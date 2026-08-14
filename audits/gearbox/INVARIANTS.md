# Gearbox V3.1 invariant register

These are starting hypotheses, not yet source-validated claims. Each must be mapped
to exact contracts, state variables, transitions, and tests after commit pinning.

| ID | Proposed invariant | Validation state |
|---|---|---|
| GBX-INV-001 | Pool assets, debt, interest, quota revenue, and share claims conserve value within documented rounding bounds. | Pending |
| GBX-INV-002 | A credit account cannot complete a user-controlled operation below the required health/collateral threshold. | Pending |
| GBX-INV-003 | Liquidation transfers no more value than authorized by debt, discounts, fees, and remaining collateral, and accounts all bad debt. | Pending |
| GBX-INV-004 | Adapter and multicall execution can affect only the active credit account and explicitly authorized assets/targets. | Pending |
| GBX-INV-005 | Token masks, balances, enabled collateral, quotas, and oracle-valued collateral cannot disagree in a way that increases borrow capacity. | Pending |
| GBX-INV-006 | Every price used for solvency has the correct asset identity, units, bounds, freshness, and fallback semantics. | Pending |
| GBX-INV-007 | Bot permissions are scoped, revocable, and incapable of escalating beyond the owner-granted action set. | Pending |
| GBX-INV-008 | Factories and permissionless deployment paths cannot register or wire incompatible or attacker-controlled components as trusted Gearbox code. | Pending |
| GBX-INV-009 | Emergency, migration, KYC, governance, ACL, and version transitions preserve funds and cannot be invoked or bypassed without documented authority. | Pending |
| GBX-INV-010 | Cross-repository interfaces and version checks agree on selectors, storage/serialization, units, and security assumptions. | Pending |

