#!/usr/bin/env bash
set -euo pipefail

sudo apt-get update
sudo apt-get install -y build-essential curl git jq python3 python3-pip pipx unzip

mkdir -p "$HOME/code/audits"

if ! command -v forge >/dev/null 2>&1; then
  curl -L https://foundry.paradigm.xyz | bash
  export PATH="$HOME/.foundry/bin:$PATH"
  foundryup
fi

if ! command -v slither >/dev/null 2>&1; then
  pipx install slither-analyzer
fi

grep -Fqx 'export PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || \
  printf '\nexport PATH="$HOME/.foundry/bin:$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"

echo
echo 'Audit environment ready.'
echo "Workspace: $HOME/code/audits"
echo "Foundry: $("$HOME/.foundry/bin/forge" --version | head -n 1)"
echo 'Close and reopen Ubuntu before using slither if it is not immediately found.'
