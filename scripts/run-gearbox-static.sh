#!/usr/bin/env bash
set -uo pipefail

LAB_ROOT="${GEARBOX_LAB_ROOT:-/workspaces/gearbox-audit}"
SOURCE_ROOT="${GEARBOX_SOURCE_ROOT:-$LAB_ROOT/source}"
RUN_DIR="${GEARBOX_RUN_DIR:-$LAB_ROOT/audits/gearbox/runs/current}"
OUTPUT_DIR="$RUN_DIR/static-production"
STATUS_FILE="$OUTPUT_DIR/status.tsv"
SCOPE_FILE="$OUTPUT_DIR/scope-files.tsv"

export PATH="/home/vscode/.foundry/bin:/usr/local/py-utils/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

repos=(permissionless core-v3 oracles-v3 integrations-v3 bots-v3 periphery-v3)
pins=(
  b1b5e5bac7d2183a1f10c4bcc3d4bbf88c8b7769
  510fc6541c3767ce825929b4c311826fe81d6fa5
  287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d
  39e70f05e09ef4224febb3a8c9890afe48adbec9
  ebec19d2396a1abcf69e6496a193abb7a9f5c027
  2a63cf27b458c9c3b7824086da32f9dd6ee73613
)

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

command -v forge >/dev/null 2>&1 || fail 'forge is missing'
command -v slither >/dev/null 2>&1 || fail 'slither is missing'
mkdir -p "$OUTPUT_DIR"
: >"$STATUS_FILE"
: >"$SCOPE_FILE"
printf 'repository\tshard\tstep\texit_code\tstarted_utc\tfinished_utc\n' >>"$STATUS_FILE"
printf 'repository\tshard\tsource_file\n' >>"$SCOPE_FILE"

LAST_EXIT=0
run_step() {
  local repo="$1"
  local shard="$2"
  local step="$3"
  local duration="$4"
  shift 4
  local started finished code
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Running %s/%s %s\n' "$repo" "$shard" "$step"
  set +e
  timeout --signal=TERM "$duration" "$@" >"$OUTPUT_DIR/$repo-$shard-$step.log" 2>&1
  code=$?
  set -e
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$shard" "$step" "$code" "$started" "$finished" >>"$STATUS_FILE"
  printf '%s/%s %s finished with exit code %s\n' "$repo" "$shard" "$step" "$code"
  LAST_EXIT="$code"
}

verify_repo() {
  local repo="$1"
  local pin="$2"
  local repo_root="$SOURCE_ROOT/$repo"
  [[ -d "$repo_root/.git" ]] || fail "repository is missing: $repo_root"
  [[ "$(git -C "$repo_root" rev-parse HEAD)" == "$pin" ]] || fail "$repo is not at its pinned commit"
  [[ -z "$(git -C "$repo_root" status --porcelain)" ]] || fail "$repo has local changes"
}

scan_shard() {
  local repo="$1"
  local shard="$2"
  shift 2
  local repo_root="$SOURCE_ROOT/$repo"
  local build_info="$repo_root/out/slither-production-$shard"
  local json="$OUTPUT_DIR/$repo-$shard-slither.json"
  local targets=("$@")

  ((${#targets[@]} > 0)) || fail "$repo/$shard has no source files"
  for target in "${targets[@]}"; do
    [[ -f "$repo_root/$target" ]] || fail "$repo/$shard target is missing: $target"
    printf '%s\t%s\t%s\n' "$repo" "$shard" "$target" >>"$SCOPE_FILE"
  done

  rm -rf "$build_info"
  rm -f "$json"

  pushd "$repo_root" >/dev/null || fail "cannot enter $repo_root"
  run_step "$repo" "$shard" build-info 45m \
    forge build "${targets[@]}" --build-info --build-info-path "$build_info" -j 1
  popd >/dev/null || fail "cannot leave $repo_root"

  if ((LAST_EXIT != 0)); then
    return
  fi

  run_step "$repo" "$shard" detectors 45m \
    slither "$repo_root" --foundry-ignore-compile \
      --foundry-build-info-directory "$build_info" \
      --exclude-dependencies --filter-paths '(^|/)(test|tests|script|scripts|lib)/' \
      --json "$json"

  run_step "$repo" "$shard" structure 20m \
    slither "$repo_root" --foundry-ignore-compile \
      --foundry-build-info-directory "$build_info" \
      --exclude-dependencies --filter-paths '(^|/)(test|tests|script|scripts|lib)/' \
      --print human-summary,contract-summary,entry-points,vars-and-auth
}

for i in "${!repos[@]}"; do
  verify_repo "${repos[$i]}" "${pins[$i]}"
done

mapfile -t permissionless_files < <(
  cd "$SOURCE_ROOT/permissionless" &&
    find contracts -type f -name '*.sol' ! -path '*/test/*' ! -path '*/tests/*' | sort
)
scan_shard permissionless production "${permissionless_files[@]}"

mapfile -t core_files < <(
  cd "$SOURCE_ROOT/core-v3" &&
    find contracts -type f -name '*.sol' ! -path '*/test/*' ! -path '*/tests/*' | sort
)
scan_shard core-v3 production "${core_files[@]}"

mapfile -t oracle_files < <(
  cd "$SOURCE_ROOT/oracles-v3" &&
    find contracts -type f -name '*.sol' ! -path '*/test/*' ! -path '*/tests/*' | sort
)
scan_shard oracles-v3 production "${oracle_files[@]}"

for shard in adapters helpers integrations interfaces zappers; do
  mapfile -t integration_files < <(
    cd "$SOURCE_ROOT/integrations-v3" &&
      find "contracts/$shard" -type f -name '*.sol' ! -path '*/test/*' ! -path '*/tests/*' | sort
  )
  scan_shard integrations-v3 "$shard" "${integration_files[@]}"
done

mapfile -t bot_files < <(
  cd "$SOURCE_ROOT/bots-v3" && find contracts/bots -type f -name '*.sol' | sort
)
scan_shard bots-v3 production "${bot_files[@]}"

# The canonical periphery scope literally names emergency, kyc and migration paths,
# excluding Previewer contracts. The pinned tree has no contracts/kyc directory;
# contracts/rwa is not silently substituted for that missing path.
mapfile -t periphery_files < <(
  cd "$SOURCE_ROOT/periphery-v3" &&
    find contracts/emergency contracts/migration -type f -name '*.sol' ! -name '*Previewer*' | sort
)
scan_shard periphery-v3 production "${periphery_files[@]}"

printf 'Gearbox production-only static analysis complete. Review %s\n' "$STATUS_FILE"
