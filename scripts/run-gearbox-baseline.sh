#!/usr/bin/env bash
set -uo pipefail

LAB_ROOT="${GEARBOX_LAB_ROOT:-/workspaces/gearbox-audit}"
SOURCE_ROOT="${GEARBOX_SOURCE_ROOT:-$LAB_ROOT/source}"
RUN_DIR="${GEARBOX_RUN_DIR:-$LAB_ROOT/audits/gearbox/runs/current}"
STATUS_FILE="$RUN_DIR/status.tsv"

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
mkdir -p "$RUN_DIR"
: >"$STATUS_FILE"
printf 'repository\tstep\texit_code\tstarted_utc\tfinished_utc\n' >>"$STATUS_FILE"

for i in "${!repos[@]}"; do
  repo="${repos[$i]}"
  pin="${pins[$i]}"
  repo_root="$SOURCE_ROOT/$repo"
  [[ -d "$repo_root/.git" ]] || fail "repository is missing: $repo_root"
  [[ "$(git -C "$repo_root" rev-parse HEAD)" == "$pin" ]] || fail "$repo is not at its pinned commit"
  [[ -z "$(git -C "$repo_root" status --porcelain)" ]] || fail "$repo has local changes"
done

{
  printf '# Gearbox V3.1 baseline metadata\n\n'
  printf -- '- Started UTC: `%s`\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf -- '- Forge: `%s`\n' "$(forge --version | head -1)"
  printf -- '- Solidity configuration: repository-native Foundry profiles (currently `0.8.23`, Shanghai)\n'
  printf '\n| Repository | Commit | Production Solidity files | Test files |\n'
  printf '|---|---|---:|---:|\n'
  for i in "${!repos[@]}"; do
    repo="${repos[$i]}"
    repo_root="$SOURCE_ROOT/$repo"
    contract_count="$(find "$repo_root/contracts" -type f -name '*.sol' ! -path '*/test/*' | wc -l)"
    test_count="$(find "$repo_root" -path "$repo_root/lib" -prune -o -type f -name '*.t.sol' -print | wc -l)"
    printf '| `%s` | `%s` | %s | %s |\n' "$repo" "${pins[$i]}" "$contract_count" "$test_count"
  done
} >"$RUN_DIR/baseline-metadata.md"

run_step() {
  local repo="$1"
  local step="$2"
  local duration="$3"
  shift 3
  local started finished code
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Running %s %s\n' "$repo" "$step"
  set +e
  timeout --signal=TERM "$duration" "$@" >"$RUN_DIR/$repo-$step.log" 2>&1
  code=$?
  set -e
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$repo" "$step" "$code" "$started" "$finished" >>"$STATUS_FILE"
  printf '%s %s finished with exit code %s\n' "$repo" "$step" "$code"
}

for repo in "${repos[@]}"; do
  repo_root="$SOURCE_ROOT/$repo"
  mkdir -p "$RUN_DIR/$repo/test-shards"
  case "$repo" in
    oracles-v3)
      run_step "$repo" dependencies 15m \
        yarn --cwd "$repo_root" install --frozen-lockfile --ignore-scripts
      ;;
    periphery-v3)
      run_step "$repo" dependencies 15m \
        pnpm --dir "$repo_root" install --frozen-lockfile --ignore-scripts
      ;;
  esac
  run_step "$repo" production-build 45m \
    forge build --root "$repo_root" --skip test script -j 1
  run_step "$repo" test-shards 240m \
    bash "$LAB_ROOT/scripts/run-gearbox-test-shards.sh" \
      "$repo_root" "$RUN_DIR/$repo/test-shards"
done

printf 'Gearbox baseline complete. Review %s\n' "$STATUS_FILE"
