# TermMax V2 candidate ledger

Candidates are private working hypotheses. They are not bounty findings.

| ID | State | Component | Hypothesis | Attacker/reachability | Candidate impact | Disposition |
|---|---|---|---|---|---|---|
| DUP-001 | Rejected: exact public duplicate | `TermMaxRouterV2` | A final same-token unit strands a caller's input; another caller can consume the router's global on-chain balance and transfer it out through the zero-adapter branch. | Permissionless `swapTokens`; no role, oracle, live chain, or victim signature beyond the victim's own route. | Direct theft of the stranded ERC-20 balance; hypothetically Critical under the published impact table. | Local PoC passed, but public PR [term-structure/termmax-contract-v2#32](https://github.com/term-structure/termmax-contract-v2/pull/32) already describes and tests both the stranded same-token amount and prefunded-router drain. Do not submit. |
| REJ-001 | Rejected: no independent cross-user impact | Router adapters | Some whitelisted adapters accept a spender or ultimate target through caller-controlled calldata. | A caller can expose its own input. Spending third-party value requires a pre-existing global router balance. | Potential arbitrary token transfer. | Any cross-user loss collapses into `DUP-001`; no separate asynchronous or victim-funded path was established. |
| REJ-002 | Rejected: authenticated | `OrderManagerV2.afterSwap` | The public callback might be invoked by an arbitrary caller after delegatecall. | Any address can call the Vault fallback, but the original caller is preserved as `msg.sender`. | Hypothetical accounting corruption. | `_orderMaturityMapping[msg.sender]` must be nonzero; unrelated callers revert `UnauthorizedOrder`. |
| REJ-003 | Rejected: deployment evidence contradicts | UUPS proxies | An attacker could initialize an uninitialized proxy. | Would require a deployed proxy with no atomic initialization data. | Hypothetical owner takeover and theft. | Deployment scripts create Router, Viewer, and AccessManager proxies with initializer calldata in the constructor; Router upgrade initialization is also atomic. |
| REJ-004 | Rejected: unreachable | `UniversalFactory` | CREATE2 squatting could capture a preauthorized or prefunded address. | Requires an actual deployment flow that relies on a predictable address before initialization. | Hypothetical authority or asset capture. | Current scripts import but do not use the helper for these deployments; `PreTMX` uses its constructor and Viewer uses an atomically initialized proxy. |
| REJ-005 | Rejected: no added authority | Gearing-token delegation | A delegate could merge a victim GT into an attacker-selected token ID. | Victim must intentionally grant the protocol's broad delegate authority. | Hypothetical collateral theft. | The same delegation already permits value-moving repay/remove-collateral flows with arbitrary recipients; merge does not create an independent escalation. |
| REJ-006 | Rejected: missing source-only trigger | Oracle aggregation | A zero oracle answer is accepted despite the positive-price comment. | Requires bad third-party data, privileged configuration, or a separate oracle manipulation path. | Hypothetical insolvency or liquidation error. | No unprivileged source-only sequence produced a listed end impact; bad external data is outside this code-only proof. |
| REJ-007 | Rejected: no listed impact | Zero-debt NFT handling | A zero-debt token can survive a repayment/removal path. | Permissionless only within the caller's authorized token flow. | Code-quality/state-cleanup concern. | No theft, freeze, insolvency, or unclaimed-yield loss was demonstrated. |
| TEST-001 | Rejected: stale baseline tests | `VaultV2*.t.sol` | Twelve tests revert when deposit and withdraw actions are performed sequentially. | Both operations occur inside one Foundry test transaction. | None demonstrated. | `TransactionReentrancyGuard` intentionally rejects different protected actions in one transaction; transient storage clears between real transactions. |
| TEST-002 | Rejected: harness impersonation | `StableERC4626For4626Invariant.t.sol` | All 11 invariant checks report a handler balance assertion failure. | Foundry chooses the vault proxy as fuzz sender and `vm.startPrank` impersonates it. | None demonstrated. | Trace shows `transferFrom(vault, vault, amount)`; an external attacker cannot originate a transaction as the vault. Exclude protocol addresses from the handler's actor set. |

## DUP-001 - same-token router balance can be swept

- Exact source: `contracts/v2/router/TermMaxRouterV2.sol`,
  `_executeSwapPaths` lines 116-129 and `_executeSwapUnits` lines 132-164 at
  commit `e314f3f849577dfecd4614f148c4df81fdf8c72d`.
- Root cause: input is pulled before swap execution; a same-token unit is skipped
  without paying the final recipient; `useBalanceOnchain` then exposes the
  router's full global token balance to any later caller; an address-zero
  adapter transfers that input balance directly to the chosen recipient.
- Minimal transaction sequence:
  1. Victim calls `swapTokens` with `useBalanceOnchain = false` and a final unit
     whose `tokenIn == tokenOut`; the full input remains in the router.
  2. Attacker calls `swapTokens` with `useBalanceOnchain = true`, the stranded
     token as `tokenIn`, a different `tokenOut`, address-zero adapter, and the
     attacker as recipient.
  3. The router transfers the victim's full stranded balance to the attacker.
- Violated invariant: assets supplied by one swap caller must not become a
  permissionless credit for a different caller.
- Reproduction: `poc/RouterSameTokenBalanceSweep.t.sol` passed at the pinned
  commit. The complete trace is in
  `runs/current/poc-router-same-token.log` (`1 passed; 0 failed`).
- Hypothetical program mapping: direct theft of user funds, Critical; published
  formula 10% of directly affected funds, bounded by `$10,000-$50,000`.
- Eligibility conclusion: rejected as already public/known. PR #32, opened
  2026-05-25 and closed unmerged on 2026-05-27, proposes the exact balance
  tracking and final same-token payout fix and includes matching regression
  tests. Expected bounty eligibility is therefore none, regardless of the
  technical impact on the still-vulnerable pinned commit.

## Rejected-lead evidence notes

- `OrderManagerV2.afterSwap` reads the mapping with the preserved external
  caller and rejects an unmapped address before state changes.
- The deployment check covered `DeployBaseV2.s.sol`, Router upgrade calldata,
  Viewer deployment, AccessManager deployment, and `PreTMX` construction.
- The stable-wrapper rerun trace is retained at
  `runs/current/test-shards/stable4626-rerun-trace.log`.
- Scanner and independent-review suggestions were accepted into this ledger
  only after manual source tracing; none was promoted on tool output alone.

## Required candidate record

Each new candidate must contain exact source locations, root cause, attacker
preconditions, a transaction sequence, violated invariant, complete end effect,
severity mapping, reward basis, PoC status, known-issue status, and rejection
conditions.
