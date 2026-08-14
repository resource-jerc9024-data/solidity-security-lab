#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="${GEARBOX_LAB_ROOT:-/workspaces/gearbox-audit}"
REPO_ROOT="$LAB_ROOT/source/oracles-v3"
POC_SOURCE="$LAB_ROOT/audits/gearbox/poc/PythPriceFeedFeeAmplification.t.sol"
POC_DIR="$REPO_ROOT/contracts/test/poc"
POC_TARGET="$POC_DIR/PythPriceFeedFeeAmplification.t.sol"
LOG_DIR="$LAB_ROOT/audits/gearbox/runs/current/poc"
PIN="287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d"

export PATH="/home/vscode/.foundry/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

[[ -f "$POC_SOURCE" ]] || { printf 'Missing PoC: %s\n' "$POC_SOURCE" >&2; exit 1; }
[[ "$(git -C "$REPO_ROOT" rev-parse HEAD)" == "$PIN" ]] || {
  printf 'oracles-v3 is not at the pinned commit\n' >&2
  exit 1
}
[[ -z "$(git -C "$REPO_ROOT" status --porcelain)" ]] || {
  printf 'oracles-v3 has local changes\n' >&2
  exit 1
}

cleanup() {
  rm -f "$POC_TARGET"
  rmdir "$POC_DIR" 2>/dev/null || true
}
trap cleanup EXIT

mkdir -p "$POC_DIR" "$LOG_DIR"
cp "$POC_SOURCE" "$POC_TARGET"

set +e
forge test --root "$REPO_ROOT" \
  --match-contract PythPriceFeedFeeAmplificationPoC -vv \
  2>&1 | tee "$LOG_DIR/pyth-fee-amplification.log"
code=${PIPESTATUS[0]}
set -e

exit "$code"
