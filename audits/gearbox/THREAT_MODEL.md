# Gearbox V3.1 threat model

This is a fresh Gearbox model derived from the pinned source trees. It contains no
TermMax assumptions or transferred vulnerability claims.

## Actors and trust boundaries to validate

- Unprivileged credit-account users and liquidators.
- Liquidity providers and pool share holders.
- Bots, quota keepers, gauges, and permissionless deployment callers.
- Credit managers, facades, configurators, adapters, and external protocol calls.
- Price feeds, oracle composition, and price-update/fallback paths.
- Governance, ACL, timelocks, emergency controls, migrations, and KYC components.
- Repository boundaries where core, integrations, oracles, bots, permissionless,
  and periphery contracts rely on shared interfaces or version assumptions.

## Priority failure classes

| Lane | Questions to prove from Gearbox source |
|---|---|
| Credit accounting | Can debt, interest, collateral value, quotas, or enabled-token state diverge from real assets? |
| Liquidation and health | Can an attacker avoid liquidation, seize excess value, create bad debt, or make accounts unliquidatable? |
| Pool solvency | Can deposits, withdrawals, interest accrual, quota revenue, or loss accounting inflate claims or strand funds? |
| Adapter execution | Can target calls, calldata rewriting, approvals, token masks, or multicalls escape the intended credit-account boundary? |
| Oracle safety | Are assets, decimals, bounds, freshness, fallbacks, and composite prices enforced before health decisions? |
| Permissionless deployment | Can bytecode registration, factory deployment, configuration, or version checks admit malicious system components? |
| Bots and periphery | Can delegated bot permissions, emergency actions, KYC, or migrations exceed explicit user/system authority? |
| Governance and upgrades | Can roles, timelocks, version compatibility, serialization, or upgrade transitions be bypassed by an unprivileged caller? |

Privileged compromise alone is out of scope. Each candidate must identify the
unprivileged transition that expands authority or produces a listed impact.

## Source-validated control map

| Boundary | Gearbox control traced in the pinned source | Residual review focus |
|---|---|---|
| User to credit account | `CreditFacadeV3` binds account operations to owners or exact bot permissions, holds the reentrancy guard across multicalls, and finishes state-changing user flows with collateral checks. | Account substitution, incomplete permission masks, sequencing before the final check. |
| Facade/adapters to credit manager | `CreditManagerV3` restricts facade transitions and registered-adapter execution; adapter calls operate on the manager's active credit account. | Active-account lifetime, callback paths, target/calldata rewriting, and token-mask synchronization. |
| Credit manager to pool | `PoolV3` accounts borrowing by the calling credit manager, with configured debt limits and repayment/loss accounting. | Share rounding, interest/quota revenue, bad debt, loss socialization, and donation behavior. |
| Solvency to prices | `PriceOracleV3` and configured feeds provide the asset/price conversions used by collateral and liquidation logic; update/fallback behavior crosses into `oracles-v3` and the price-feed store. | Asset identity, decimals, staleness, reserve/main selection, composites, and update ordering. |
| Core to integrations | Registered adapters and collateral configuration define which external protocol and token behaviors may enter a credit-account multicall. | Recipient/approval escape, phantom-token agreement, return-value handling, and unsupported-token assumptions. |
| User to bot | `BotListV3` keys delegated permissions by bot, credit manager, and credit account; the partial-liquidation bot additionally constrains permission bits and ending health. | Revocation, closed-account cleanup, cross-manager reuse, and caller-controlled recipient/token fields. |
| Migration/periphery | The migrator checks source ownership, registration/version, active source account, and a temporarily unlocked migration adapter; privileged pause/treasury paths have explicit roles. | Atomic unlock/lock, arbitrary opening calls, legacy-version transitions, and residual allowances. |
| Permissionless market creation | Bytecode registration binds source, type/version, author signatures, approved auditor attestations, and repository deployment; market configurators and factory hooks retain curator/governance trust. | Domain/type collisions, hook target authority, revocation, salts, cross-curator isolation, and curator trust disclosure. |
| Cross-chain governance | `CrossChainMultisig` requires threshold-signed hash-chained batches; recovery semantics intentionally execute only self-calls while consuming an authorized batch. | Signature/domain binding, replay/fork handling, recovery-mode expectations, and chain-specific execution. |

External tokens, protocols, feeds, curators, governance, emergency operators, and
approved code/auditors remain explicit trust assumptions. A result depending only
on those actors behaving maliciously is not promoted without a separate Gearbox
authorization bypass or in-scope end effect.
