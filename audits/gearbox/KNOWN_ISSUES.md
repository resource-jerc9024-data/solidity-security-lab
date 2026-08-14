# Gearbox V3.1 known-issue database

No vulnerability entries have been imported from TermMax or any other protocol.
The entries below come from Gearbox's own public issue trackers. A matching root
cause is ineligible even when the public issue remains open or the pinned code still
contains the behavior.

## Gearbox V3 public issues

| ID | Public source | Root cause / behavior | Pinned-code comparison rule |
|---|---|---|---|
| `KI-V3-311` | [core-v3#311](https://github.com/Gearbox-protocol/core-v3/issues/311) | Full liquidation freezes collateral/debt data after on-demand price updates, while remaining-funds conversion can use live prices after adapter multicalls. The issue notes no standard adapter path that changes prices mid-multicall. | Reject any frozen-vs-live liquidation-price claim with this root cause; a distinct candidate requires a proven standard-call reachability or different accounting defect and impact. |
| `KI-V3-194` | [core-v3#194](https://github.com/Gearbox-protocol/core-v3/issues/194) | `availableToBorrow` could quote the exact U2 boundary that `calcBorrowRate` rejected due to a sign error. | Reject exact U2-boundary unintended-revert claims; verify whether a different current boundary can cause a listed impact. |
| `KI-V3-182` | [core-v3#182](https://github.com/Gearbox-protocol/core-v3/issues/182) | Flexible liquidation adapter calls can claim and withdraw a user's farming rewards that were not enabled or included in `totalValue`. | Reject liquidator withdrawal of unclaimed/disabled rewards as known. A candidate must demonstrate a distinct asset path or authority expansion. |
| `KI-V3-174` | [core-v3#174](https://github.com/Gearbox-protocol/core-v3/issues/174) | Fee-on-transfer debt repayment/liquidation accounting and collateral health accounting differed, overestimating effective health. | Reject matching fee-on-transfer health/debt mismatch claims unless a distinct current implementation and impact are proven. |
| `KI-V3-170` | [core-v3#170](https://github.com/Gearbox-protocol/core-v3/issues/170) | Incremental collateral checking stopped at one target but final `isLiquidatable`/`fullCollateralCheck` decisions used another, mishandling `minHealthFactor`. | Reject the documented early-stop/min-health-factor mismatch. |
| `KI-V3-168` | [core-v3#168](https://github.com/Gearbox-protocol/core-v3/issues/168) | A dummy withdrawal could make safe-price logic use an inflated trusted main feed after the reserve feed was activated. | Reject matching main/reserve-feed fallback bypass claims. |
| `KI-V3-130` | [core-v3#130](https://github.com/Gearbox-protocol/core-v3/issues/130) | Debt could be changed more than once in a block before the documented fix. | Reject same-block repeated-debt-change claims matching the fixed behavior; check new paths against current guards. |
| `KI-V3-129` | [core-v3#129](https://github.com/Gearbox-protocol/core-v3/issues/129) | Non-expirable to expirable CreditFacade migration was incorrect before the documented fix. | Reject the exact legacy facade-migration bug; compare any new migration claim by versions and state transition. |
| `KI-V3-122` | [core-v3#122](https://github.com/Gearbox-protocol/core-v3/issues/122) | Public invariant concern: CreditManager's active credit account could be overwritten if re-entered from CreditFacade. | Treat active-account reentrancy as publicly known unless a materially different entry point/root cause is proven. |
| `KI-V3-107` | [core-v3#107](https://github.com/Gearbox-protocol/core-v3/issues/107) | Public invariant backlog covers bot permissions after closure, quota cleanup on disconnect/zero debt, quota collateral overperformance, and quota limit totals. | Compare all bot-cleanup and quota-state hypotheses to these listed invariants before promotion. |

## Other in-scope repository issues

| ID | Public source | Root cause / behavior | Pinned-code comparison rule |
|---|---|---|---|
| `KI-ORACLE-36` | [oracles-v3#36](https://github.com/Gearbox-protocol/oracles-v3/issues/36) | `RedstonePriceFeed` assumes eight feed decimals, although Redstone has feeds with other decimal counts. | Reject hardcoded-Redstone-decimals claims matching this behavior. A distinct candidate needs a different feed/unit path and current impact. |
| `KI-PERM-17` | [permissionless#17](https://github.com/Gearbox-protocol/permissionless/issues/17) | Rate-keeper update hooks originally called `setGauge` before migrating existing tokens, causing configured markets to revert. | Reject the documented hook-order/rate-keeper-token migration failure; the issue records release `v1.4.2` as its fix. |
| `NOTE-PERM-18` | [permissionless#18](https://github.com/Gearbox-protocol/permissionless/issues/18) | Non-configurable adapters are still authorized and unauthorised during factory updates, increasing gas. | Treat as public gas optimization, not a new security impact without a separate permissionless block-stuffing or inability-to-operate proof. |
| `NOTE-PERIPH-41` | [periphery-v3#41](https://github.com/Gearbox-protocol/periphery-v3/issues/41) | Compressors return `success: false` without detailed error data. | Compressors are outside the V3.1 periphery paths in scope; retain only as public context. |

## Gearbox V2 issues retained for cross-version comparison

These are not automatically V3 duplicates. They are rejection evidence only when the
same root cause and behavior are proven to persist in the pinned V3.1 implementation.

| ID | Public source | Root cause / behavior |
|---|---|---|
| `KI-V2-68` | [core-v2#68](https://github.com/Gearbox-protocol/core-v2/issues/68) | A cumulative-loss liquidation attempted to pause an already-paused facade and reverted; the issue states V3 fixed it. |
| `KI-V2-12` | [core-v2#12](https://github.com/Gearbox-protocol/core-v2/issues/12) | Liquidation premium based on total value could be unfair for low-liquidation-threshold collateral. |
| `KI-V2-07` | [core-v2#7](https://github.com/Gearbox-protocol/core-v2/issues/7) | USDC borrower blacklisting could block transfer of remaining liquidation funds and temporarily freeze liquidation/LP funds. |
| `KI-V2-06` | [core-v2#6](https://github.com/Gearbox-protocol/core-v2/issues/6) | Adapters cached an immutable CreditFacade and failed to recognize a later facade replacement. |

## Mandatory sources

| Source | Status | Notes |
|---|---|---|
| https://github.com/Gearbox-protocol/core-v2/issues | Initial security-relevant review complete | Explicitly named by the Immunefi program; V2 entries remain cross-version evidence only. |
| https://github.com/Gearbox-protocol/core-v3/issues | Initial security-relevant review complete | Public V3 root causes are indexed above. |
| https://github.com/Gearbox-protocol/security/tree/main/audits | Candidate-specific comparison complete for `CAND-001` | The public 2024 Oracles report's explicit scope omits `PythPriceFeed`; future candidates still require their own report comparison. |
| https://github.com/Gearbox-protocol/security/tree/main/disclosures | Index captured; applicability pending | Public disclosures currently include the 2022 Uniswap V3 and forbidden-token incidents; compare if an adapter/token candidate reaches those roots. |
| In-scope repository issues | Initial review complete | All six repository issue trackers reviewed; relevant entries are indexed above. |
| In-scope repository pull requests | Complete for confirmed candidate; future candidates pending | `CAND-001` searches and Pyth PR comparisons are recorded below. |
| In-scope repository commit history | Complete for confirmed candidate; future candidates pending | `PythPriceFeed.sol` history reviewed from introduction through the pinned commit. |

## Candidate-specific comparison: `CAND-001` / `GBX-M-01`

| Source | Comparison result |
|---|---|
| `oracles-v3` issues and PR search | No public issue or PR describes attacker-amplified Pyth fees, redundant update arrays, or exhaustion of the feed's prepaid ETH. |
| [`oracles-v3#45`](https://github.com/Gearbox-protocol/oracles-v3/pull/45) | Spearbit-review follow-up added timestamp and confidence checks but retained caller-controlled `updateData` and reserve-funded `getUpdateFee`. The PR references private Spearbit issues whose contents return `404`; they could not be compared. |
| [`oracles-v3#52`](https://github.com/Gearbox-protocol/oracles-v3/pull/52) | Pyth microfixes added constructor and exponent validation only; no update-count, feed-ID, payer, or fee bound. |
| `PythPriceFeed.sol` commit history | File history from its May 2024 introduction through the pinned commit contains no public fee-amplification fix or description. |
| [2024 ChainSecurity Oracles V3 report](https://github.com/Gearbox-protocol/security/blob/main/audits/2024%20Aug%20-%20ChainSecurity_Gearbox_Oracles_V3.pdf) | Explicit contract scope lists Redstone as the updatable feed and adds Mellow in version 4; it does not list `PythPriceFeed`. Pages 5-6 were extracted and visually checked. |
| Gearbox security disclosures | No Pyth fee-reserve or redundant-update disclosure found. |
| [Pyth production source](https://github.com/pyth-network/pyth-crosschain/blob/0418a8a75ac11783bc1fd34cc980c4679e856668/target_chains/ethereum/contracts/contracts/pyth/Pyth.sol#L62-L111) | Confirms fees scale with all decoded updates and `updatePriceFeeds` succeeds after processing stale or duplicate valid updates; supports the root cause rather than duplicating it as a Gearbox issue. |

Disposition: no public duplicate was found, but inaccessible private Spearbit issue
contents create a clearly recorded eligibility risk. This limitation must be
disclosed if `GBX-M-01` is submitted.

## Entry schema

Each entry must record an ID, source link, affected repository/version, root cause,
impact, fix or mitigation, current-code match status, and candidate IDs it excludes.
A textual similarity is insufficient: duplicate disposition requires matching the
same root cause and materially equivalent attack behavior.
