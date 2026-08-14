# Gearbox V3.1 threat model

This is a fresh Gearbox model. It must be refined against the pinned source trees;
it contains no TermMax assumptions.

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

