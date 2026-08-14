#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y --no-install-recommends build-essential curl git jq pipx unzip

if ! command -v forge >/dev/null 2>&1; then
  curl -fsSL https://foundry.paradigm.xyz | bash
  "$HOME/.foundry/bin/foundryup"
fi

if ! command -v slither >/dev/null 2>&1; then
  pipx install slither-analyzer
fi

if ! command -v codex >/dev/null 2>&1; then
  curl -fsSL https://chatgpt.com/codex/install.sh | sh
fi

mkdir -p audit test/security
touch audit/SCOPE.md audit/ARCHITECTURE.md audit/INVARIANTS.md audit/FINDINGS.md

echo
echo 'Security lab installed. Run: bash scripts/check-environment.sh'
echo 'In Codespaces, authenticate with your ChatGPT subscription using:'
echo '  codex login --device-auth'
