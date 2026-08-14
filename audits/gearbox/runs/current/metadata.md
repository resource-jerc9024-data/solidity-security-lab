# Gearbox V3.1 source metadata

- Captured UTC date: `2026-08-14`
- Codespace checkout root: `/workspaces/gearbox-audit/source/`
- Checkout mode: isolated official repository clones at exact commits
- Source state: clean; recursive dependency submodules initialized at the exact
  commits recorded by each superproject
- Shared Solidity configuration observed: Solidity `0.8.23`, Shanghai EVM

| Repository | Branch | Commit | Solidity files under `contracts/` | Foundry test files observed |
|---|---|---|---:|---:|
| `permissionless` | `master` | `b1b5e5bac7d2183a1f10c4bcc3d4bbf88c8b7769` | 102 | 21 |
| `core-v3` | `main` | `510fc6541c3767ce825929b4c311826fe81d6fa5` | 162 | 32 |
| `oracles-v3` | `main` | `287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d` | 48 | 14 |
| `integrations-v3` | `main` | `39e70f05e09ef4224febb3a8c9890afe48adbec9` | 271 | 38 |
| `bots-v3` | `main` | `ebec19d2396a1abcf69e6496a193abb7a9f5c027` | 3 | 1 |
| `periphery-v3` | `main` | `2a63cf27b458c9c3b7824086da32f9dd6ee73613` | 103 | 9 |

Counts are discovery metrics, not final scope counts. In particular, periphery and
bots have narrower production paths, while tests and mocks are excluded from bounty
impact even when retained for local harness use.

Submodule graphs differ by repository and include Gearbox repositories on recorded
submodule commits or special branches. The baseline and scan runners retained those
exact superproject-recorded commits; they did not replace them with the six top-level
scope pins merely because repository names overlap.
