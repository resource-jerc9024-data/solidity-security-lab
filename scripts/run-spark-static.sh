#!/usr/bin/env bash
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${SPARK_SOURCE_ROOT:-$LAB_ROOT/audits/spark/source}"
RUN_DIR="${SPARK_RUN_DIR:-$LAB_ROOT/audits/spark/runs/current}/static"
MANIFEST="$SOURCE_ROOT/MANIFEST.tsv"
STATUS_FILE="$RUN_DIR/status.tsv"

export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command -v slither >/dev/null 2>&1 || fail 'slither is required'
[[ -f "$MANIFEST" ]] || fail 'run scripts/bootstrap-spark.sh first'
mkdir -p "$RUN_DIR"
printf 'repository\tstep\texit_code\tstarted_utc\tfinished_utc\n' >"$STATUS_FILE"

run_step() {
  local repo="$1" step="$2" duration="$3"
  shift 3
  local started finished code
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  set +e
  timeout --signal=TERM "$duration" "$@" >"$RUN_DIR/$repo-$step.log" 2>&1
  code=$?
  set -e
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\t%s\n' "$repo" "$step" "$code" "$started" "$finished" >>"$STATUS_FILE"
}

while IFS=$'\t' read -r repo remote pin captured; do
  [[ "$repo" == 'repository' ]] && continue
  root="$SOURCE_ROOT/$repo"
  [[ -d "$root/.git" ]] || fail "missing source checkout: $repo"
  [[ "$(git -C "$root" rev-parse HEAD)" == "$pin" ]] || fail "$repo is not at its captured pin"
  if [[ ! -f "$root/foundry.toml" ]]; then
    printf '%s\tnot-foundry\tSKIPPED\t%s\t%s\n' "$repo" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$STATUS_FILE"
    continue
  fi
  build_info="$root/out/spark-slither-build-info"
  run_step "$repo" forge-build-info 45m forge build --root "$root" --build-info --build-info-path "$build_info" -j 1
  run_step "$repo" slither-detectors 45m slither "$root" --foundry-ignore-compile --foundry-build-info-directory "$build_info" --exclude-dependencies --filter-paths '(^|/)(test|tests|script|scripts|lib)/' --json "$RUN_DIR/$repo-slither.json"
  run_step "$repo" slither-structure 20m slither "$root" --foundry-ignore-compile --foundry-build-info-directory "$build_info" --exclude-dependencies --filter-paths '(^|/)(test|tests|script|scripts|lib)/' --print human-summary,contract-summary,entry-points,vars-and-auth
done <"$MANIFEST"

printf 'Static pass complete. Classify output manually in audits/spark/STATIC_TRIAGE.md.\n'
