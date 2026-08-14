#!/usr/bin/env bash
set -uo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REVIEW_ROOT="${TERMMAX_REVIEW_ROOT:-/workspaces/audits/termmax-contract-v2-review}"
PROMPT_DIR="$LAB_ROOT/audits/termmax-v2/prompts"
OUTPUT_DIR="$LAB_ROOT/audits/termmax-v2/runs/current/codex"
STATUS_FILE="$OUTPUT_DIR/status.tsv"

export PATH="/home/vscode/.foundry/bin:/usr/local/py-utils/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

[[ -e "$REVIEW_ROOT/.git" ]] || {
  printf 'Run scripts/run-termmax-audit.sh first.\n' >&2
  exit 1
}

codex login status >/dev/null 2>&1 || {
  printf 'Codex is not authenticated in this Codespace.\n' >&2
  exit 1
}

mkdir -p "$OUTPUT_DIR"
: >"$STATUS_FILE"
printf 'pass\texit_code\tstarted_utc\tfinished_utc\n' >>"$STATUS_FILE"

for prompt_file in "$PROMPT_DIR"/*.md; do
  pass_name="$(basename "$prompt_file" .md)"
  output_file="$OUTPUT_DIR/$pass_name.md"
  stderr_file="$OUTPUT_DIR/$pass_name.stderr.log"
  started="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'Running Codex pass %s...\n' "$pass_name"
  set +e
  timeout --signal=TERM 60m codex exec --ephemeral --sandbox read-only -C "$REVIEW_ROOT" -o "$output_file" - <"$prompt_file" >"$OUTPUT_DIR/$pass_name.stdout.log" 2>"$stderr_file"
  code=$?
  set -e
  finished="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '%s\t%s\t%s\t%s\n' "$pass_name" "$code" "$started" "$finished" >>"$STATUS_FILE"
  printf '%s finished with exit code %s\n' "$pass_name" "$code"
done

printf 'Codex passes complete. Review %s\n' "$STATUS_FILE"
