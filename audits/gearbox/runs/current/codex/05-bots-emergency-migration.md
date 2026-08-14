# Independent review result

I found no credible unprivileged vulnerability in the supplied pinned source.

The reviewed paths either preserve caller/account binding and collateral checks, or require an explicitly privileged role, account ownership, or prior user delegation. No deterministic local exploit PoC can therefore be specified without assuming authority that falls outside an unprivileged threat model.

## Findings

No reportable High, Medium, or Low severity issue was identified.

Informational robustness and operational observations below do not yield an unprivileged loss, unauthorized state change, or persistent protocol denial of service.

## Key security conclusions

### Delegated partial-liquidation bot

Locations:

- `bots-v3/contracts/bots/PartialLiquidationBotV3.sol::_initVars`
- `::_validateLiquidation`
- `::_executeLiquidation`
- `::_checkHealthFactor`
- `core-v3/contracts/credit/CreditFacadeV3.sol::botMulticall`
- `core-v3/contracts/core/BotListV3.sol::getBotStatus`
- `::setBotPermissions`

The caller controls:

- `creditAccount`
- collateral `token`
- `repaidAmount`
- `minSeizedAmount`
- recipient `to`
- price-update payloads

This does not let the caller select another account’s authority context:

1. The bot derives the credit manager from `creditAccount`.
2. It derives that manager’s current facade.
3. The facade queries bot permissions for the same `creditAccount`.
4. `BotListV3` keys permissions by bot, derived credit manager, and credit account.
5. The bot must have exactly `DECREASE_DEBT_PERMISSION | WITHDRAW_COLLATERAL_PERMISSION`.
6. The bot’s multicall cannot add external calls, increase debt, change quotas, or delegate further bots.
7. The transaction reverts unless the account starts inside the configured liquidation range, survives the facade’s full collateral check, and ends inside the bot’s configured health-factor range.

The public ability to choose `to` is intentional: the caller supplies underlying and receives discounted collateral. Atomic reversion protects the account if the minimum received amount or final health factor is not satisfied.

No caller/account substitution, permission replay, or cross-manager permission reuse was found.

### Price-update handoff

Locations:

- `PartialLiquidationBotV3.partiallyLiquidate`
- `AccountMigratorBot._applyPriceUpdates`
- `CreditFacadeV3._onDemandPriceUpdates`
- `CreditFacadeV3._updatePrices`

Each execution resolves the price-feed store from the facade associated with the relevant manager. Updates occur before the corresponding solvency or liquidation calculation.

The supplied code does not authenticate update contents itself, but authentication and freshness are necessarily properties of `IPriceFeedStore.updatePrices`, whose implementation was not supplied. Nothing here bypasses that store by directly writing oracle state.

A replay claim would require showing that the price-feed store accepts stale or replayed updates. That cannot be established from this bundle.

### Core partial liquidation

Locations:

- `CreditFacadeV3.partiallyLiquidateCreditAccount`
- `::_revertIfNotLiquidatable`
- `::_calcPartialLiquidationPayments`
- `::_tryWithdrawPhantomToken`
- `CreditManagerV3.manageDebt`
- `CreditManagerV3.fullCollateralCheck`

The core path:

1. Applies prices.
2. verifies current liquidatability or expiration;
3. transfers repayment funds from the caller;
4. computes fees and seizure using the manager’s configured parameters;
5. resolves phantom-token withdrawal when applicable;
6. prevents seizure of underlying;
7. decreases debt;
8. pays the configured treasury;
9. transfers collateral;
10. performs a full collateral check.

All effects revert atomically on a failed minimum-output or collateral check. No unprivileged route was found to seize collateral without furnishing the underlying repayment.

### Account migration binding

Locations:

- `AccountMigratorBot.migrateCreditAccount`
- `::_validateParameters`
- `::_checkAccountOwner`
- `::_unlockAdapter`
- `::migrate`
- `::_lockAdapter`
- `AccountMigratorAdapter.onlyMigratorBot`
- `AccountMigratorAdapterV30.migrate`
- `AccountMigratorAdapterV31.migrate`

Binding is maintained across the bot, adapter, source account, and target facade:

- The external caller must equal both the source manager’s recorded borrower and `params.accountOwner`.
- `activeCreditAccount` is set to the selected source account immediately before the source multicall.
- The adapter can be unlocked or locked only by its configured migrator bot.
- Adapter `migrate` can only be dispatched by its credit facade.
- The nested bot `migrate` call only accepts the currently active source credit account as `msg.sender`.
- Reentrancy into `migrateCreditAccount` is blocked.
- A revert at any point also rolls back the temporary unlocked and active-account state.

The migration can leave the source account open with zero debt and any collateral the owner deliberately omitted. That is not an unauthorized loss: the same owner retains the source account, and repayment/opening is atomic.

### Arbitrary migration calls

Locations:

- `AccountMigratorBot._getOpeningMultiCalls`
- `::_validateParameters`

The owner can provide `underlyingSwapCalls` and `extraOpeningCalls`. These execute against the newly opened account owned by that same caller and remain subject to:

- the target facade’s adapter allowlist;
- the opening permission mask;
- the final collateral check.

Direct calls to the target migration adapter are expressly rejected. Consequently, these fields do not create an unprivileged route into another user’s account or the temporarily unlocked source adapter.

Malformed call-count fields can make array construction or execution revert, but only the submitting owner’s migration is affected.

### Allowances and residual balances

Locations:

- `AccountMigratorAdapter._migrate`
- `AccountMigratorAdapter._approveTokens`
- `AccountMigratorBot._transferCollaterals`
- `TreasuryLiquidator.partiallyLiquidateFromTreasury`

The source adapter grants maximum allowances only around `_execute(msg.data)` and resets them to zero before returning. A failed execution reverts the approval as well.

The migrator bot approves the target manager for the exact transferred balance. Normal `addCollateral` consumes that amount. There is no unprivileged callable sweep or transfer function through which another user could claim any accidental bot dust.

`TreasuryLiquidator` similarly approves the validated credit manager for the requested repayment. The supplied manager pulls that amount during the same transaction. A meaningful residual-allowance exploit would require replacing a registered facade or manager with malicious code, which is not an unprivileged path under this bundle.

### Legacy compatibility and serialization

Locations:

- `AccountMigratorAdapterV30`
- `AccountMigratorAdapterV31`
- `AccountMigratorBot._validateCreditManager`
- `AccountMigratorBot.serialize`
- `AccountMigratorAdapter.serialize`

The V3.0 adapter deliberately exposes legacy adapter identifiers and reverts for the V3.1 `contractType` and `version` interface. Its migration return shape also matches the legacy facade expectation.

Legacy managers must be present in `contractsRegisterOld`. V3.1 managers must belong to a recognized market configurator and its contracts register. No caller-controlled version value alone is sufficient to bypass registration.

`AccountMigratorBot.serialize` omits `contractsRegisterOld` and owner, while the adapter serialization omits its transient `locked` state. This may matter to off-chain deployment comparison tooling, but no on-chain authorization or migration decision consumes these serializations in the supplied source. It is therefore not a demonstrated security issue.

## Rejected privileged-only ideas

The following do not qualify as unprivileged vulnerabilities:

- `MultiPause.pauseContracts`, `pauseMarket`, `pauseCreditSuite`, and `pauseAllContracts` require `PAUSABLE_ADMIN`.
- Paused-facade liquidation requires `EMERGENCY_LIQUIDATOR`.
- `TreasuryLiquidator.setLiquidatorStatus` and `setMinExchangeRate` require the treasury.
- Calling `partiallyLiquidateFromTreasury` requires prior treasury approval as a liquidator.
- Changing phantom-token overrides requires the migrator bot owner.
- `LiquidityMigrator.migrate` requires the instance owner; the user must also have approved pool shares.
- Replacing facades, adapters, price oracles, fees, collateral definitions, or contract allowances requires configurator authority.
- Forbidding bots requires the `BotListV3` owner.

Abuse under any of these roles is a governance, emergency-operator, treasury, or explicitly delegated-operator trust assumption—not a credible unprivileged attack path.

## Final assessment

Severity mapping: **None / no reportable issue**.

Within the supplied executable source, I found no deterministic transaction sequence by which an unprivileged caller can steal user or treasury assets, reuse bot authority across accounts, bypass liquidation eligibility, retain exploitable migration authority, replay a migration against another owner, or cross the active-account boundary.