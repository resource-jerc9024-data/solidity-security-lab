# TermMax V2 static-analysis triage

Slither `0.11.6` analyzed the pinned commit with Solidity `0.8.27` build-info.
The complete machine output is retained in `runs/current/slither.json` and the
human logs. Detector output is a lead inventory, not a vulnerability count.

## Raw signal inventory

| Slither impact | Signals |
|---|---:|
| High | 70 |
| Medium | 232 |
| Low | 318 |
| Informational | 293 |
| Optimization | 27 |
| **Total** | **940** |

The 70 High signals group as follows: 27 `uninitialized-state`, 14
`unchecked-transfer`, 13 `reentrancy-balance`, 9 `controlled-delegatecall`, 6
`arbitrary-send-erc20`, and 1 `encode-packed-collision`.

## High-signal disposition

| Signal group | Manual disposition |
|---|---|
| `unchecked-transfer` | Thirteen instances are in mock Venus contracts and one is in a V1 Pendle adapter. None is a production V2 unsafe transfer. |
| `uninitialized-state` | Mostly Vault storage that intentionally begins at zero and is updated through the Vault/OrderManager delegatecall design; the remainder is mock state or Pendle's intentionally empty limit-order struct. No public read-before-initialize authority or value-extraction path was found. |
| `controlled-delegatecall` | Router delegatecalls are limited by the adapter whitelist; Vault delegatecalls use the immutable `ORDER_MANAGER_SINGLETON`. User-selected ultimate targets inside some whitelisted adapter calldata were separately traced below. |
| `arbitrary-send-erc20` | V1 caller-parameter flows plus `StableERC4626ForCustomize` pulling from its privileged, documented isolated `thirdPool`. No attacker-selected victim address in a current V2 production flow was established. |
| `reentrancy-balance` | Router value-moving entries are `nonReentrant`; intentional callbacks authenticate a transient expected caller and clear it before use. Adapter balance reads enforce output/input postconditions. No callback spoof or cross-user reentrancy sequence survived manual tracing. |
| `encode-packed-collision` | `UniversalFactory.getCreationCode` intentionally concatenates creation bytecode and already-encoded constructor arguments; it is a pure helper and no ambiguous authorization decision depends on decoding the result. |

## Leads requiring explicit impact analysis

- Global router balance consumption plus the zero-adapter transfer is a real
  cross-user theft primitive when a prior route strands funds. The local PoC
  passed, but the exact issue is already public in upstream PR #32 and is
  rejected as `DUP-001` in `CANDIDATES.md`.
- `OkxSwapAdapter`, `KodiakSwapAdapter`, `UniswapV3AdapterV2`, and
  `TerminalVaultAdapter` accept a spender or external target through caller
  calldata. In a normal `swapTokens` call this exposes the caller's own input.
  Against third-party value it depends on a pre-existing router balance and
  therefore collapses into the already-known global-balance issue. Persistent
  allowances do not create an asynchronous interleaving point during an
  otherwise atomic victim route.
- Fee-on-transfer debt or collateral can make nominal accounting differ from
  received balances. Asset selection is privileged, no currently in-scope
  production asset with that behavior was established, and straightforward
  mismatches revert atomically. This is an integration/configuration caveat,
  not an unprivileged bounty finding on the available evidence.
- `OracleAggregatorV2._checkAnswer` accepts zero despite its positive-price
  comment. A zero value requires bad external-oracle data, privileged
  configuration, or separate oracle manipulation; no source-only unprivileged
  sequence produced a listed end impact. Rejecting `answer <= 0` remains a
  sensible hardening change.

## Static-analysis conclusion

No raw Slither signal independently established direct theft, permanent or
temporary freezing, protocol insolvency, or theft/freezing of unclaimed yield.
Only the reproducible, already-public router duplicate crossed the complete
impact proof gate.
