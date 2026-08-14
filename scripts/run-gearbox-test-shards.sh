#!/usr/bin/env bash
set -uo pipefail

REPO_ROOT="${1:?repository root is required}"
OUTPUT_DIR="${2:?output directory is required}"
STATUS_FILE="$OUTPUT_DIR/status.tsv"

export PATH="/home/vscode/.foundry/bin:/usr/local/py-utils/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

[[ -d "$REPO_ROOT/.git" ]] || {
  printf 'Repository is missing: %s\n' "$REPO_ROOT" >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR/logs"
: >"$STATUS_FILE"
printf 'test_file\texit_code\tstarted_utc\tfinished_utc\n' >>"$STATUS_FILE"

mapfile -d '' test_files < <(
  find "$REPO_ROOT" \
    \( -path "$REPO_ROOT/lib" -o -path "$REPO_ROOT/node_modules" \
       -o -path "$REPO_ROOT/out" -o -path "$REPO_ROOT/cache" \) -prune -o \
    -type f -name '*.t.sol' -print0 | sort -z
)

failures=0
for absolute_test_file in "${test_files[@]}"; do
  test_file="${absolute_test_file#"$REPO_ROOT/"}"
  log_name="${test_file//\//__}"
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Running shard %s\n' "$test_file"

  set +e
  if [[ "$test_file" == *invariant* || "$test_file" == *invaritant* ]]; then
    timeout --signal=TERM 30m env \
      FOUNDRY_FUZZ_RUNS=512 \
      FOUNDRY_INVARIANT_RUNS=128 \
      FOUNDRY_INVARIANT_DEPTH=64 \
      forge test --root "$REPO_ROOT" --match-path "$test_file" -j 1 -vv \
      >"$OUTPUT_DIR/logs/$log_name.log" 2>&1
  else
    timeout --signal=TERM 20m forge test --root "$REPO_ROOT" \
      --match-path "$test_file" -j 1 -vv \
      >"$OUTPUT_DIR/logs/$log_name.log" 2>&1
  fi
  code=$?
  set -e

  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\n' "$test_file" "$code" "$started" "$finished" >>"$STATUS_FILE"
  if [[ "$code" -ne 0 ]]; then
    failures=$((failures + 1))
  fi
  printf '%s finished with exit code %s\n' "$test_file" "$code"
done

printf 'Sharded tests complete: %s files, %s non-zero exits.\n' "${#test_files[@]}" "$failures"
exit "$failures"
