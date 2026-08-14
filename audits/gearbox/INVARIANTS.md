# Gearbox V3.1 invariant register

These invariants were created for Gearbox and mapped to the pinned production
source and baseline tests. "Reviewed" means the relevant transition and guard were
traced; it does not claim formal verification.

| ID | Gearbox invariant | Primary source anchors | Validation state |
|---|---|---|---|
| GBX-INV-001 | Pool assets, debt, interest, quota revenue, and share claims conserve value within documented rounding bounds. | `PoolV3`, `CreditLogic`, `PoolQuotaKeeperV3` | Reviewed in baseline tests and Codex lane 01; no violating path retained. |
| GBX-INV-002 | A credit account cannot complete a user-controlled operation below the required health/collateral threshold. | `CreditFacadeV3`, `CreditManagerV3`, `CollateralLogic` | Reviewed across multicall, debt, withdrawal, close, and final-collateral-check paths. |
| GBX-INV-003 | Liquidation transfers no more value than authorized by debt, discounts, fees, and remaining collateral, and accounts all bad debt. | `CreditFacadeV3`, `CreditManagerV3`, `AliasedLossPolicyV3` | Full and partial liquidation traced; public liquidation issues indexed before triage. |
| GBX-INV-004 | Adapter and multicall execution can affect only the active credit account and explicitly authorized assets/targets. | `CreditManagerV3`, `CreditFacadeV3`, integration adapters | Reviewed in Codex lane 04 and supported-adapter comparison; no escape retained. |
| GBX-INV-005 | Token masks, balances, enabled collateral, quotas, and oracle-valued collateral cannot disagree in a way that increases borrow capacity. | `CollateralLogic`, `CreditFacadeV3`, `PoolQuotaKeeperV3` | Mask/quota transitions and atomic rollback traced; no violating path retained. |
| GBX-INV-006 | Every price used for solvency has the correct asset identity, units, bounds, freshness, and fallback semantics. | `PriceOracleV3`, `oracles-v3` feeds and traits | Reviewed in Codex lane 03; public Redstone-decimal and reserve-feed roots indexed. |
| GBX-INV-007 | Bot permissions are scoped, revocable, and incapable of escalating beyond the owner-granted action set. | `BotListV3`, `PartialLiquidationBotV3`, `CreditFacadeV3.botMulticall` | Exact bot/manager/account binding and permission mask traced; no reuse path retained. |
| GBX-INV-008 | Factories and permissionless deployment paths cannot register or wire incompatible or attacker-controlled components as trusted Gearbox code. | `BytecodeRepository`, `InstanceManager`, `MarketConfigurator`, factories | Signatures, attestations, domains, salts, hook authorization, and curator boundary reviewed. |
| GBX-INV-009 | Emergency, migration, KYC, governance, ACL, and version transitions preserve funds and cannot be invoked or bypassed without documented authority. | periphery emergency/migration paths, `AccountMigratorBot`, ACL, `CrossChainMultisig` | Roles, owner binding, atomic adapter unlock, legacy registration, and recovery semantics traced. |
| GBX-INV-010 | Cross-repository interfaces and version checks agree on selectors, serialization, units, and security assumptions. | core interfaces, integrations, bots, permissionless and periphery consumers | Cross-repository Codex lane completed; phantom-token gas mismatch rejected for lack of a supported trigger. |
