#!/usr/bin/env bash
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${SPARK_SOURCE_ROOT:-$LAB_ROOT/audits/spark/source}"
RUN_DIR="${SPARK_RUN_DIR:-$LAB_ROOT/audits/spark/runs/current}/baseline"
MANIFEST="$SOURCE_ROOT/MANIFEST.tsv"
STATUS_FILE="$RUN_DIR/status.tsv"

export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || fail 'run scripts/bootstrap-spark.sh first'
mkdir -p "$RUN_DIR"
cp "$MANIFEST" "$RUN_DIR/source-manifest.tsv"
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
  printf '%s %s: exit %s\n' "$repo" "$step" "$code"
}

while IFS=$'\t' read -r repo remote pin captured; do
  [[ "$repo" == 'repository' ]] && continue
  root="$SOURCE_ROOT/$repo"
  [[ -d "$root/.git" ]] || fail "missing source checkout: $repo"
  [[ "$(git -C "$root" rev-parse HEAD)" == "$pin" ]] || fail "$repo is not at its captured pin"
  [[ -z "$(git -C "$root" status --porcelain)" ]] || fail "$repo has tracked modifications"
  run_step "$repo" revision 1m git -C "$root" status --short --branch
  if [[ -f "$root/foundry.toml" ]]; then
    command -v forge >/dev/null 2>&1 || fail 'forge is required for a Foundry repository'
    run_step "$repo" forge-build 45m forge build --root "$root" -j 1
    run_step "$repo" forge-test 180m forge test --root "$root" -j 1
  elif [[ -f "$root/pnpm-lock.yaml" ]]; then
    command -v pnpm >/dev/null 2>&1 || fail "pnpm is required for $repo"
    run_step "$repo" dependencies 30m pnpm --dir "$root" install --frozen-lockfile --ignore-scripts
    run_step "$repo" package-scripts 5m pnpm --dir "$root" run
  elif [[ -f "$root/yarn.lock" ]]; then
    command -v yarn >/dev/null 2>&1 || fail "yarn is required for $repo"
    run_step "$repo" dependencies 30m yarn --cwd "$root" install --frozen-lockfile --ignore-scripts
    run_step "$repo" package-scripts 5m yarn --cwd "$root" run
  elif [[ -f "$root/package-lock.json" ]]; then
    command -v npm >/dev/null 2>&1 || fail "npm is required for $repo"
    run_step "$repo" dependencies 30m npm --prefix "$root" ci --ignore-scripts
    run_step "$repo" package-scripts 5m npm --prefix "$root" run
  else
    printf '%s\ttoolchain-discovery\tSKIPPED\t%s\t%s\n' "$repo" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$STATUS_FILE"
  fi
done <"$MANIFEST"

printf 'Baseline complete. Inspect %s before deciding any toolchain-specific test command.\n' "$STATUS_FILE"
