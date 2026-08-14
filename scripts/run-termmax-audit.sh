#!/usr/bin/env bash
set -uo pipefail

PINNED_COMMIT="e314f3f849577dfecd4614f148c4df81fdf8c72d"
SOURCE_REPO="${TERMMAX_SOURCE_REPO:-/workspaces/audits/termmax-contract-v2}"
REVIEW_ROOT="${TERMMAX_REVIEW_ROOT:-/workspaces/audits/termmax-contract-v2-review}"
LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$LAB_ROOT/audits/termmax-v2/runs/current"
STATUS_FILE="$RUN_DIR/status.tsv"

export PATH="/home/vscode/.foundry/bin:/usr/local/py-utils/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

mkdir -p "$RUN_DIR"
: >"$STATUS_FILE"
printf 'step\texit_code\tstarted_utc\tfinished_utc\n' >>"$STATUS_FILE"

fail() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 1
}

[[ -d "$SOURCE_REPO/.git" ]] || fail "source repository not found: $SOURCE_REPO"
[[ "$(git -C "$SOURCE_REPO" rev-parse HEAD)" == "$PINNED_COMMIT" ]] || fail "source checkout is not at pinned commit"
git -C "$SOURCE_REPO" diff --quiet || fail "source checkout has tracked changes"

if [[ -e "$REVIEW_ROOT/.git" ]]; then
  [[ "$(git -C "$REVIEW_ROOT" rev-parse HEAD)" == "$PINNED_COMMIT" ]] || fail "existing review worktree is at a different commit"
elif [[ -e "$REVIEW_ROOT" ]]; then
  fail "review path exists but is not a Git worktree: $REVIEW_ROOT"
else
  git -C "$SOURCE_REPO" worktree add --detach "$REVIEW_ROOT" "$PINNED_COMMIT" || fail "could not create review worktree"
fi

if [[ ! -e "$REVIEW_ROOT/dependencies" ]]; then
  [[ -d "$SOURCE_REPO/dependencies" ]] || fail "Soldeer dependencies are missing from source checkout"
  ln -s "$SOURCE_REPO/dependencies" "$REVIEW_ROOT/dependencies" || fail "could not link dependencies"
fi

CASE_FILE="$REVIEW_ROOT/test/v2/integration/ForkXauePriceFeedAdapter.t.sol"
if grep -Fq 'TermMaxPricefeedFactoryV2.sol' "$CASE_FILE"; then
  sed -i 's/TermMaxPricefeedFactoryV2.sol/TermMaxPriceFeedFactoryV2.sol/g' "$CASE_FILE"
fi

git -C "$REVIEW_ROOT" diff -- "$CASE_FILE" >"$RUN_DIR/harness-case-fix.patch"

{
  printf '# TermMax V2 run metadata\n\n'
  printf -- '- Started UTC: `%s`\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf -- '- Source repository: `%s`\n' "$SOURCE_REPO"
  printf -- '- Review worktree: `%s`\n' "$REVIEW_ROOT"
  printf -- '- Commit: `%s`\n' "$(git -C "$REVIEW_ROOT" rev-parse HEAD)"
  printf -- '- Forge: `%s`\n' "$(forge --version | head -1)"
  printf -- '- Slither: `%s`\n' "$(slither --version 2>&1 | head -1)"
  printf -- '- Contract Solidity files: `%s`\n' "$(find "$REVIEW_ROOT/contracts/v2" -type f -name '*.sol' | wc -l)"
  printf -- '- Contract Solidity lines: `%s`\n' "$(find "$REVIEW_ROOT/contracts/v2" -type f -name '*.sol' -print0 | xargs -0 cat | wc -l)"
  printf -- '- Harness-only patch SHA-256: `%s`\n' "$(sha256sum "$RUN_DIR/harness-case-fix.patch" | cut -d' ' -f1)"
  printf '\nThe harness patch corrects one filename case mismatch in a fork test import.\n'
  printf 'It does not modify production contract code and is not a bounty finding.\n'
} >"$RUN_DIR/metadata.md"

run_step() {
  local name="$1"
  local duration="$2"
  shift 2
  local started finished code
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Running %s...\n' "$name"
  set +e
  timeout --signal=TERM "$duration" "$@" >"$RUN_DIR/$name.log" 2>&1
  code=$?
  set -e
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\n' "$name" "$code" "$started" "$finished" >>"$STATUS_FILE"
  printf '%s finished with exit code %s\n' "$name" "$code"
}

cd "$REVIEW_ROOT" || fail "could not enter review worktree"

run_step contract-build 45m forge build --skip test script
run_step unit-tests 60m forge test --skip Fork --no-match-path 'test/v2/invariant/*.t.sol' --isolate -vv
run_step invariant-tests 60m env FOUNDRY_FUZZ_RUNS=512 FOUNDRY_INVARIANT_RUNS=128 FOUNDRY_INVARIANT_DEPTH=64 forge test --match-path 'test/v2/invariant/*.t.sol' --isolate -vv
run_step slither-detectors 45m slither . --foundry-ignore-compile --exclude-dependencies --filter-paths '(^|/)(test|script|dependencies)/' --json "$RUN_DIR/slither.json"
run_step slither-structure 30m slither . --foundry-ignore-compile --exclude-dependencies --filter-paths '(^|/)(test|script|dependencies)/' --print human-summary,contract-summary,entry-points,vars-and-auth

printf 'Audit runner complete. Review %s\n' "$STATUS_FILE"
