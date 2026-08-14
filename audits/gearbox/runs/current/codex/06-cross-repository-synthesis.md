## Result

I found no PoC-ready permissionless exploit in the supplied bundle. The strongest cross-repository candidates either require a privileged actor, deliberately malicious audited bytecode, or behavior from omitted contracts that cannot be proven here.

The following are the only concrete hypotheses worth retaining. None currently qualifies as a confirmed vulnerability.

### 1. Factory hooks could seize configurator-held tokens, but only after privileged factory admission

Locations:

- `MarketConfigurator._executeHook(address, Call[])`
- `MarketConfigurator._validateCallTarget`
- `MarketConfigurator.createMarket`
- `PoolFactory.deployPool`
- `BytecodeRepository.allowSystemContract`
- `InstanceManager.deploySystemContract`

Root cause candidate: factory hooks may call the `MarketConfigurator` itself without target authorization:

```solidity
if (target != address(this) && _authorizedFactories[target] != factory) revert;
```

A hook can therefore invoke any externally callable function on the configurator. During `createMarket`, the configurator temporarily holds and approves underlying tokens needed for dead shares.

Attacker control: a malicious factory controls its returned `Call[]`, but getting that factory into the address provider requires governance to allow and deploy audited system bytecode.

Potential sequence:

1. Governance admits a malicious or compromised factory version.
2. Admin calls `createMarket`.
3. The configurator approves the pool factory for unlimited underlying.
4. A factory installation or market hook returns a call targeting the configurator.
5. The call reaches an externally callable configurator function.

Violated invariant candidate: hooks should configure only explicitly authorized suite contracts, not use the configurator as a generic callback target.

End effect: depending on another callable entry point or token callback not present here, this could escalate factory authority or consume configurator-held deployment funds.

Severity: unproven; potentially high under malicious-factory assumptions, but those assumptions already imply governance/auditor compromise.

PoC steps: implement a factory returning `Call(address(marketConfigurator), maliciousCalldata)` and enumerate selectors that can execute successfully while `msg.sender == address(this)`.

Strongest rejection condition: no self-callable configurator function shown here transfers assets or grants arbitrary authority. `authorizeFactory` and `unauthorizeFactory` are intentionally self-callable, but their arguments originate from already-admitted factories. Without malicious governance-approved factory code, there is no permissionless entry.

---

### 2. Public bytecode ownership and deployment verification authenticate metadata, not benign behavior

Locations:

- `BytecodeRepository.allowPublicContract`
- `BytecodeRepository.deploy`
- `BytecodeRepository.isDeployedFromRepository`
- `MarketConfigurator.addPeripheryContract`
- `MarketConfigurator._getDomain`

Root cause candidate: repository provenance proves only that a bytecode hash was allowed and that the deployed contract reports the expected `contractType` and `version`. Registration as periphery subsequently checks repository provenance and derives the domain from the contract’s live `contractType()` response.

Attacker control: an author can upload public-domain bytecode and deploy it permissionlessly, but it must have a valid signature from an approved auditor and the domain must first be made public by governance. Adding it to a market’s periphery list remains admin-only.

Potential sequence:

1. Attacker authors code whose reported type/version are valid but whose runtime behavior is hostile.
2. An approved auditor signs it.
3. `allowPublicContract` claims the public contract type for that author.
4. Attacker deploys it from the repository.
5. A curator registers it as periphery.
6. Other omitted consumers treat periphery registration as stronger behavioral trust than provenance.

Violated invariant candidate: “repository-deployed and registered” may be interpreted elsewhere as “safe for user approvals or callbacks.”

End effect: malicious callbacks, token approvals, or user-facing phishing are conceivable if omitted consumers grant authority solely from periphery registration.

Severity: unproven; potentially high only if another consumer grants material authority.

PoC steps: deploy audited test bytecode whose `contractType()` identifies an expected public domain and whose operational method transfers approved funds; then identify a supplied caller that invokes it without further validation.

Strongest rejection condition: no supplied contract grants a registered periphery contract custody, callback rights, or automatic approvals. Registration is also admin-controlled and audited bytecode is required. The complete exploit therefore cannot be established from these files.

---

### 3. Partial-liquidation bot and facade use different phantom-token discovery gas limits

Locations:

- `PartialLiquidationBotV3._initVars`: `gasAllowance: 10_000`
- `CreditFacadeV3._tryWithdrawPhantomToken`: `gasAllowance: 30_000`
- `AccountMigratorBot._getPhantomTokenInfo`: `gasAllowance: 30_000`
- `PartialLiquidationBotV3._validateLiquidation`
- `PartialLiquidationBotV3._executeLiquidation`

Root cause candidate: the bot may classify a token as ordinary because `getPhantomTokenInfo()` cannot complete within 10,000 gas, while the facade recognizes the same token as phantom with 30,000 gas.

Attacker control: a liquidator chooses `token`, repayment amount, and recipient. Token implementation and adapter availability are generally governance-controlled.

Potential sequence:

1. Choose a registered phantom token whose discovery call requires between 10,000 and 30,000 gas.
2. The bot sets `receivedToken = token`.
3. It computes `seizedAmount` using the phantom-token oracle price.
4. `botMulticall` asks the facade to withdraw that token.
5. The facade recognizes it as phantom and actually withdraws `depositedToken`.
6. The bot measures the recipient’s balance change in the phantom token, not the deposited token.

Violated invariant: the bot and facade must agree on which asset is delivered and therefore on which balance proves seizure.

End effect: the transaction normally reverts or reports zero received amount; this can make bot-based partial liquidation unavailable for affected phantom tokens. Because all operations are atomic, it does not establish theft.

Likely severity: low availability issue, if such a registered token exists.

PoC steps:

1. Implement a phantom token whose getter succeeds with 30,000 gas but fails with 10,000.
2. Register the token, target, and adapter as collateral.
3. Give the bot the required permissions.
4. Call `partiallyLiquidate`.
5. Show bot discovery returning “ordinary,” facade discovery returning “phantom,” and final accounting using different tokens.

Strongest rejection condition: every supported phantom token’s getter completes within 10,000 gas, or the optional-call helper reserves materially different effective gas than its argument suggests. No concrete supported token is supplied, so the hypothesis is not currently PoC-ready.

---

### 4. Market creation depends on raw token funds held by the configurator

Locations:

- `MarketConfigurator.createMarket`
- `MarketConfigurator._deployPool`
- `PoolFactory.deployPool`

Root cause: dead shares are always funded with exactly `1e5` raw underlying units:

```solidity
if (IERC20(underlying).balanceOf(msg.sender) < 1e5) revert;
IERC20(underlying).safeTransferFrom(msg.sender, address(this), 1e5);
IPoolV3(pool).deposit(1e5, address(0xdead));
```

Here `msg.sender` is the market configurator. The admin cannot provide those tokens as part of `createMarket`; the configurator must already hold them.

Attacker control: none directly. Anyone may transfer tokens out only if the token itself has hostile behavior or an admitted factory abuses its temporary allowance.

Sequence causing failure:

1. Admin attempts to create a market.
2. The configurator has less than `1e5` raw units.
3. `PoolFactory.deployPool` reverts.
4. Market creation remains impossible until the configurator is funded.

Violated invariant candidate: an authorized market creation should not silently depend on an out-of-band prefunding step.

End effect: deployment failure or funds stranded as dead shares. For zero-decimal or unusually valuable assets, the fixed raw amount may also be economically excessive.

Likely severity: informational operational risk, not a permissionless vulnerability.

PoC steps: call `createMarket` with the configurator’s underlying balance below `1e5`, observe `InsufficientFundsForDeploymentException`, fund it with exactly `1e5`, and retry.

Strongest rejection condition: deployment tooling always prefunds the configurator and supported underlying-token policy excludes assets for which `1e5` raw units is unreasonable.

## Rejected observations

- `BytecodeRepository.submitAuditReport` prevents duplicate signatures rather than duplicate auditors. One auditor can submit multiple reports by changing `reportUrl`, but the attacker must be an approved auditor and pays for every storage addition. Deployment only requires a boolean “at least one approved auditor,” so duplicates confer no additional privilege.
- `LiquidityMigrator` has no slippage bound on destination shares, but execution is restricted to its owner and only affects users who approved that exact migrator.
- `AccountMigratorBot` accepts arbitrary target-account opening calls, but the caller must own the source account, the target account is opened for that same owner, and the target facade performs its normal collateral check.
- `PoolV3.lendCreditAccount` lacks an explicit registration modifier, but an unconfigured caller has a zero debt limit and therefore cannot borrow a nonzero amount.

Bottom line: this bundle supports one plausible phantom-token availability mismatch and several governance/operational trust boundaries, but no complete permissionless theft, insolvency, governance-loss, or freezing PoC.