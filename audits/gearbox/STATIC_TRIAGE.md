# Gearbox V3.1 static-analysis triage

Slither 0.11.6 was run from Forge build-info produced only from exact production
source manifests. Integrations were split into bounded component shards to avoid
memory loss, and detector output was deduplicated by repository, detector, and
description before triage.

## Coverage

| Repository | Literal in-scope production files | Scan layout |
|---|---:|---|
| `permissionless` | 61 | One production-only shard |
| `core-v3` | 69 | One production-only shard |
| `oracles-v3` | 26 | One production-only shard; avoids the test deployer that crashes Slither |
| `integrations-v3` | 174 | `adapters`, `helpers`, `integrations`, `interfaces`, and `zappers` shards |
| `bots-v3` | 1 | `contracts/bots/` only |
| `periphery-v3` | 7 | `emergency` and non-`Previewer` `migration`; canonical `contracts/kyc/` is absent at the pin |
| **Total** | **338** | All build-info, detector, and structure steps completed |

The first corrective run also analyzed six `contracts/rwa/` files as contextual
coverage. The canonical scope literally names `contracts/kyc/`; RWA results were
excluded from in-scope counts and promotion. The committed runner now avoids this
semantic substitution.

## Deduplicated in-scope output

| Slither impact | Unique signals |
|---|---:|
| High | 21 |
| Medium | 208 |
| Low | 412 |
| Informational | 385 |
| Optimization | 9 |
| **Total** | **1,035** |

Slither uses exit code `255` when it emits detector results. All production-only
JSON results reported `success: true`; `255` is not recorded as a build or parser
failure.

## High-signal disposition

| Class | Manual result |
|---|---|
| Pyth fee payment | Retained and proved as `CAND-001`, then promoted to `GBX-M-01`. The useful root cause is attacker amplification of reserve-funded fees, not Slither's generic “arbitrary ETH send” wording. |
| `CreditManagerV3.addCollateral` arbitrary payer | Rejected: `creditFacadeOnly` and `nonReentrant`; the facade supplies its transaction caller as payer. |
| Governor ETH calls and batch reentrancy | Rejected: authenticated timelock/governance execution; no unprivileged target or value authority. |
| Bytecode `abi.encodePacked` | Rejected: intentional concatenation of init code and opaque constructor bytes; the value is deployed/hashed, not ambiguously decoded. |
| BytecodeRepository uninitialized mapping | False positive: Solidity mappings are valid from zero state and are populated through `submitAuditReport`. |
| Integration gateway ETH calls | Rejected: fixed WETH/external protocol targets, caller-funded assets, and atomic return-to-caller behavior. |
| Mellow/Infinifi balance reentrancy | Rejected: configured fixed protocol/token targets; callbacks cannot assume the original user's `msg.sender`, and adapter execution remains inside the facade/manager guard. |
| Lido/Infinifi unchecked token returns | Rejected for supported fixed token implementations; no attacker-selected token or false-return trigger without privileged configuration. |
| Treasury liquidator arbitrary payer | Rejected: only a treasury-approved liquidator can enter, the registered credit suite is checked, and the treasury explicitly supplies balance/allowance. |
| Contextual RWA arbitrary payer | Outside the literal periphery scope and independently gated to the registered wrapped token; shares remain held for the fixed depositor. |

Twenty High signals were rejected or excluded; one was converted into the confirmed
Medium finding after source tracing and a deterministic PoC.

## Medium-signal disposition

All 208 Medium signals were grouped and traced. They comprise intentional fixed-
point ordering, equality guards, zero-initialized locals, ignored tuple/set/return
values, and reentrancy heuristics across registered components. The accounting and
liquidation cases were also covered by Codex lane 01; adapter and gateway callbacks
by lane 04; governance/factory calls by lane 02; bots/migration by lane 05.

No second Medium signal established an attacker-controlled target or token, escaped
the active credit-account boundary, survived atomic reversion/final collateral
checks, or reached a listed Gearbox impact.

Compact detector logs, the exact source manifest, timestamps, and status table are
retained under `runs/current/static-production/`. Full JSON and structure output
remain in the isolated Codespace at
`/workspaces/gearbox-audit/audits/gearbox/runs/current/static-production/` to avoid
adding roughly 35 MB of redundant generated data to the branch.
