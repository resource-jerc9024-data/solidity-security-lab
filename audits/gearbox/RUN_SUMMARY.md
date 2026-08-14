# Gearbox V3.1 scan summary

- Date: `2026-08-14`
- Execution environment: isolated `/workspaces/gearbox-audit` workspace in the
  authenticated GitHub Codespace
- Sources: six official repositories at the exact commits in `SCOPE.md`, with
  recursive submodules at their superproject-recorded commits
- TermMax vulnerability claims or PoCs reused: **none**

## Baseline

All six production builds pass.

| Repository | Passed | Failed | Skipped | Disposition |
|---|---:|---:|---:|---|
| `permissionless` | 201 | 0 | 1 | Clean |
| `core-v3` | 337 | 0 | 0 | Clean |
| `oracles-v3` | 46 | 0 | 0 | Clean after exact declared JS dependencies were installed with lifecycle scripts disabled |
| `integrations-v3` | 261 | 1 | 0 | Only `Upshift.attach.t.sol`; `setUp` reports `Instance is not deployed` |
| `bots-v3` | 7 | 0 | 0 | Clean |
| `periphery-v3` | 22 | 0 | 4 | Clean after exact declared JS dependencies were installed with lifecycle scripts disabled |
| **Total** | **874** | **1** | **5** | **114 of 115 test files pass** |

The single integrations exception is an attachment-environment fixture failure,
not a failed production assertion. It is recorded as `TEST-001` and was not treated
as security evidence. The first periphery shard run also discovered one dependency
test under `node_modules`; it passed and is excluded from the 115 source-test-file
count. The committed shard runner now prunes `node_modules`, `lib`, `out`, and
`cache` explicitly.

## Analysis passes

| Lane | Result |
|---|---|
| Production-only Slither | 338 literal in-scope files; 1,035 deduplicated signals; 21 High and 208 Medium manually triaged |
| Gearbox-specific Codex | Six of six independent lanes completed; two suggestions rejected after source/test/supported-integration checks |
| Known issues | All six issue trackers initially reviewed; confirmed candidate compared to Pyth-specific PRs, file history, disclosures, and the public Oracle audit scope |
| PoC | `PythPriceFeedFeeAmplificationPoC`: 2 passed, 0 failed |

## Outcome

One fresh Gearbox finding is confirmed:

- `GBX-M-01` — a permissionless caller can amplify Pyth update fees paid from a
  feed's prepaid ETH using redundant valid update data, exhaust the reserve, and
  make later price updates fail until the feed is funded again.

No TermMax behavior was used to infer this result. The finding originated from the
pinned Gearbox Pyth implementation, was checked against Pyth's production fee
semantics, and has a Gearbox-specific deterministic PoC.

The public duplicate check found no match. Several issue links from the prior
private Spearbit review are inaccessible, so their unknown contents are explicitly
recorded as a submission-eligibility risk.
