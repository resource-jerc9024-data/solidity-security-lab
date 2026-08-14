#!/usr/bin/env bash
set -euo pipefail

failed=0
for command_name in git node python3 forge cast anvil slither codex; do
  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%-10s OK\n' "$command_name"
  else
    printf '%-10s MISSING\n' "$command_name"
    failed=1
  fi
done

echo 'Codex authentication: run codex and choose Sign in with ChatGPT'

exit "$failed"
