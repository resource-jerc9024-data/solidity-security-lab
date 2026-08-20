#!/usr/bin/env bash
set -euo pipefail

LAB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="${SPARK_SOURCE_ROOT:-$LAB_ROOT/audits/spark/source}"
MANIFEST="$SOURCE_ROOT/MANIFEST.tsv"
REFRESH="${SPARK_REFRESH:-0}"

repos=(
  "sparklend|https://github.com/sparkdotfi/sparklend.git"
  "aave-v3-core|https://github.com/sparkdotfi/aave-v3-core.git"
  "aave-v3-periphery|https://github.com/sparkdotfi/aave-v3-periphery.git"
  "spark-app|https://github.com/sparkdotfi/spark-app.git"
  "spark-alm-controller|https://github.com/sparkdotfi/spark-alm-controller.git"
  "spark-gov-relay|https://github.com/sparkdotfi/spark-gov-relay.git"
  "spark-rewards|https://github.com/sparkdotfi/spark-rewards.git"
  "spark-vaults-v2|https://github.com/sparkdotfi/spark-vaults-v2.git"
)

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
command -v git >/dev/null 2>&1 || fail 'git is required'

mkdir -p "$SOURCE_ROOT"
if [[ -f "$MANIFEST" && "$REFRESH" != "1" ]]; then
  fail "source manifest already exists; preserve the existing pins or set SPARK_REFRESH=1 for a separately documented refresh"
fi

tmp_manifest="$MANIFEST.tmp"
printf 'repository\tremote\tcommit\tcaptured_utc\n' >"$tmp_manifest"

for item in "${repos[@]}"; do
  name="${item%%|*}"
  remote="${item#*|}"
  destination="$SOURCE_ROOT/$name"
  if [[ -e "$destination/.git" ]]; then
    [[ "$REFRESH" == "1" ]] || fail "$destination already exists but is not represented by a reusable manifest"
    git -C "$destination" fetch --tags --prune origin
    default_ref="$(git -C "$destination" symbolic-ref --quiet --short refs/remotes/origin/HEAD || true)"
    [[ -n "$default_ref" ]] || fail "cannot resolve default branch for $name"
    git -C "$destination" checkout --detach "$default_ref"
  elif [[ -e "$destination" ]]; then
    fail "$destination exists and is not a Git checkout"
  else
    git clone --recurse-submodules "$remote" "$destination"
  fi
  git -C "$destination" submodule update --init --recursive
  git -C "$destination" diff --quiet || fail "$name has tracked changes after capture"
  printf '%s\t%s\t%s\t%s\n' "$name" "$remote" \
    "$(git -C "$destination" rev-parse HEAD)" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$tmp_manifest"
done

mv "$tmp_manifest" "$MANIFEST"
printf 'Spark source capture complete: %s\n' "$MANIFEST"
