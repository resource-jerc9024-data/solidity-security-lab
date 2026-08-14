## Executive conclusion

One credible permissionless governance-integrity issue exists in `CrossChainMultisig`: while a satellite chain is in recovery mode, any account can consume a valid signed governance batch, skip all of its non-self calls, and still advance the chain’s batch hash. The omitted calls cannot subsequently be replayed through the normal hash chain.

I rate this **Medium** because it permits temporary governance censorship and permanent omission of an already authorized batch, but does not let the attacker invent calls, forge signatures, or directly seize funds. It may be an intentional recovery-mode semantic, but if so it should be documented as “discard external actions,” not merely “execute only self-calls.”

I found no credible unprivileged route to:

- register unaudited bytecode;
- forge author or auditor attestations;
- front-run another deployer’s CREATE2 address;
- control another curator’s market through permissionless configurator creation;
- bypass a market governor or its timelock;
- grant ACL roles;
- install arbitrary price feeds in another curator’s market;
- exploit unrestricted factory hook entrypoints to execute returned calls;
- take over an InstanceManager governance transition.

Several surfaces allow a curator to configure their own market dangerously. Those are intended curator powers—not permission escalation—and are not reported as vulnerabilities.

---

## Finding G-01: Permissionless execution can irreversibly discard signed calls during recovery

**Severity:** Medium  
**Class:** Governance integrity / permissionless denial of governance action  
**Attacker privilege:** None  
**Affected component:** `permissionless/contracts/global/CrossChainMultisig.sol`

### Exact locations

- `executeBatch`: permissionless execution on every non-mainnet chain.
- `_verifyBatch`: validates the batch against the current `lastBatchHash`.
- `_executeBatch`:
  - skips every non-self call while `isRecoveryModeEnabled`;
  - nevertheless appends `batchHash` to `_executedBatchHashes`.
- `enableRecoveryMode`: establishes recovery mode without invalidating or segregating ordinary signed batches.
- `lastBatchHash`: makes the consumed batch the required parent for every future batch.

The decisive logic is:

```solidity
if (isRecoveryModeEnabled && calls[i].target != address(this)) continue;
...
_executedBatchHashes.push(batchHash);
```

### Attacker control

The attacker controls only:

- when to submit a previously threshold-signed `SignedBatch`;
- which eligible signed child of the current batch hash to execute first.

The attacker does **not** control:

- batch contents;
- signatures;
- the recovery-mode authorization;
- signer membership or threshold;
- the target calls themselves.

### Prerequisites

All of the following must hold:

1. Execution occurs outside Ethereum mainnet.
2. Recovery mode is enabled on that chain.
3. A valid threshold-signed ordinary batch exists.
4. Its `prevHash` equals the satellite chain’s current `lastBatchHash`.
5. The batch contains at least one call whose target is not the multisig itself.
6. That call has `chainId == 0` or matches the affected chain for it to have otherwise executed locally.

No compromised signer or privileged key is required after these conditions exist.

### Transaction sequence

Let the satellite multisig’s current last batch be `H`.

1. Approved signers sign a recovery message with:
   - `chainId = affectedChain`;
   - `startingBatchHash = H`.
2. Anyone calls `enableRecoveryMode(message)`.
3. A threshold-signed ordinary batch `B` exists with:
   - `B.prevHash = H`;
   - one or more external calls intended for the affected chain.
4. Before recovery mode is disabled, the attacker calls:

```solidity
multisig.executeBatch(B);
```

5. `_verifyBatch` accepts `B` because its parent is `H`.
6. `_executeBatch` skips every external call because recovery mode is active.
7. `_executeBatch` still pushes `hash(B)` to `_executedBatchHashes`.
8. `lastBatchHash()` is now `hash(B)`.
9. Re-executing `B` fails because `B.prevHash == H`, not `hash(B)`.

Governance must create and sign a new descendant batch to reproduce the omitted actions.

### Violated invariant

A threshold-authorized batch accepted into the canonical batch chain should not be marked executed unless its calls intended for the local chain were executed, or the batch explicitly authorized their cancellation.

Recovery mode legitimately suppresses external execution, but the permissionless caller can also permanently consume the suppressed actions. “Skipped because recovery is currently active” becomes indistinguishable from “successfully executed.”

### Impact

An arbitrary account can:

- permanently omit local execution of already signed governance actions;
- force cross-chain state divergence;
- delay emergency remediation, system upgrades, address changes, or role transitions;
- require the signer group to construct and sign a replacement descendant batch;
- exploit timing around recovery mode without controlling any signer.

The attacker cannot directly choose malicious replacement actions. Consequently, this is a governance availability/integrity failure rather than arbitrary execution.

### Severity mapping

- **High:** Not justified from the supplied source because the attacker cannot create or modify signed calls and governance can issue a remediation batch.
- **Medium:** Appropriate where skipped operations may be time-sensitive or security-critical and signer coordination is nontrivial.
- **Low:** Could be appropriate if recovery mode is explicitly intended to irrevocably discard all ordinary external calls executed during recovery and operational procedures guarantee no such batches are exposed.

### Local PoC design

Deploy `CrossChainMultisig` on a test chain whose chain ID is not 1:

1. Use three local signer keys with threshold two.
2. Deploy a `Counter` contract with `increment()`.
3. Create and sign a recovery message whose `startingBatchHash` is zero.
4. Call `enableRecoveryMode`.
5. Build a signed batch with:
   - `prevHash = 0`;
   - a call to `Counter.increment()`;
   - the local chain ID.
6. Call `executeBatch` from an unrelated account.
7. Assert:
   - `Counter.value() == 0`;
   - `lastBatchHash() == computeBatchHash(...)`.
8. Call `executeBatch` again with the same signed batch.
9. Assert it reverts with `InvalidPrevHashException`.
10. Demonstrate that only a newly signed child batch can perform the omitted increment.

### Recommended remediation

Do not consume ordinary external calls during recovery. Possible designs:

- Revert if a recovery-mode batch contains any non-self call applicable to the current chain.
- Allow skipping calls for other chains, but require every locally applicable call to target `address(this)`.
- Maintain a separate recovery hash chain so recovery actions do not consume normal governance batches.
- Require an explicit signed “discard batch” self-action before advancing past suppressed calls.

The smallest change is to reject locally applicable non-self calls while recovery mode is active.

---

## Other reviewed hypotheses

### Bytecode attestations and public-domain registration

**No credible unprivileged bypass found.**

`uploadBytecode` binds contract type, version, init code hash, author, and source to an EIP-712 author signature. `submitAuditReport` binds the bytecode hash, auditor, and report URL to an approved auditor signature. Allowance then requires a currently approved auditor.

`allowPublicContract` is permissionless, but only after:

- governance has designated the domain public;
- the bytecode was signed by its author;
- an approved auditor attested it;
- the contract-type owner is either unset or matches the author.

A malicious public-domain author therefore cannot substitute code under an existing type owned by another author.

The duplicate-report check compares signatures rather than auditor addresses. An auditor may potentially supply different valid encodings of the same signature, depending on the linked ECDSA implementation. This does not increase authority because `isBytecodeAudited` is boolean and only requires one currently approved auditor.

### Auditor removal and stale reports

**No bypass found.**

`isBytecodeAudited` checks `isAuditor(report.auditor)` at evaluation time. Removing an auditor invalidates that auditor’s historical reports for future allowance decisions.

Already allowed bytecode is not automatically forbidden when its auditor is removed. That is an explicit governance/revocation-policy question, not an unprivileged escalation demonstrated by this bundle.

### CREATE2 deployment and front-running

**No credible collision or front-running path found.**

Both `deploy` and `computeAddress` derive:

```solidity
uniqueSalt = keccak256(abi.encode(salt, deployer))
```

Factories also bind salts to the relevant market configurator where needed. A third party cannot occupy another deployer’s computed repository address by submitting the same public salt.

`computeAddress` does not reject a nonexistent allowed-bytecode entry and can return a meaningless counterfactual address based on empty init code. Actual deployment rejects the entry through `BytecodeIsNotAllowedException`, so this is at most an integration footgun.

### Permissionless market configurators and malicious curators

**No cross-curator authority expansion found.**

Anyone can create a registered `MarketConfigurator`, but factories use `msg.sender` as the configurator identity and derive ACL, treasury, salts, and authorization calls from that configurator. Registration does not grant one configurator authority over another configurator’s ACL or contracts.

A malicious curator can deliberately create a dangerous market, choose aggressive parameters, and—where they are admin—later reconfigure it. Those are the advertised powers of the market admin. Users must treat a permissionless curator as a trusted risk manager for that curator’s own market.

### Factory hook entrypoints

Several hooks and configuration functions lack `onlyMarketConfigurators`, notably in the IRM, loss-policy, pool, price-oracle, and rate-keeper factories.

**No actionable unprivileged exploit was established.**

These functions return `Call[]`; they do not execute the returned calls. Actual execution occurs through `MarketConfigurator._executeHook`, which validates each target against the factory authorization map. Calling a factory directly merely gives the attacker encoded call data they could have constructed independently.

`CreditFactory.emergencyConfigure` also embeds its caller into an unauthorization call, but a direct attacker still cannot make a victim configurator execute that returned call.

### Factory-target authorization

**No bypass found.**

Only the configurator itself can call `authorizeFactory` and `unauthorizeFactory`. Factory-generated self-calls work only because they are executed by the configurator during `_executeHook`. Non-configurator callers cannot directly mutate the authorization maps.

The special allowance for hook targets equal to the configurator itself does not create an external path: the attacker still needs an admin/emergency-admin operation to cause the configurator to execute the hook.

### Nested price feeds

**No permissionless market-impact path found.**

`PriceFeedStore.addPriceFeed` is owner-only. Repository-deployed nested feeds must be owned by the store where an ownership interface is exposed. Externally deployed feeds are treated as leaves, so an external contract cannot induce recursive traversal through fake nesting accessors.

A repository-deployed cyclic feed tree could make `addPriceFeed` recurse until out of gas, but producing and installing it requires audited/allowed bytecode and an owner transaction. This is not an unprivileged exploit.

The tree traversal has no cycle detection or explicit depth bound, so defensive cycle detection would still be sensible.

### Price-feed selection

A curator can choose from globally allowed feeds, and ordinary configuration verifies token membership and nonzero answers where exposure is nonzero. Emergency main-feed replacement additionally requires the feed to have been allowed for more than one day.

`onAddToken` does not perform the same explicit nonzero-answer check as ordinary main-feed configuration, but the action is curator-admin-only and the feed must already be globally allowed for the token. Without assuming malicious curator action or a bad global feed, this does not establish an unprivileged exploit.

### ACL and emergency roles

**No escalation found.**

The ACL has an immutable owner equal to the market configurator. Only that configurator may grant or revoke roles. The market admin drives normal role changes; the emergency admin can only revoke roles through the configurator.

Emergency configuration selectors are mostly restrictive:

- debt and token limits can be reduced to zero;
- borrowing, tokens, and adapters can be forbidden;
- contracts can be paused;
- loss-policy checks/access mode can be adjusted;
- emergency price replacement is constrained by the global allowlist and one-day age.

Some emergency actions can harm availability if the emergency admin is malicious, but that assumes compromise of an explicitly privileged key.

### Governor and timelock

**No permissionless queueing, cancellation, or early execution bypass found.**

Only an owner or queue admin can queue. Execution is restricted unless permissionless execution has itself been enabled through a timelocked governor self-configuration. Permissionless execution only executes already queued transactions after the ETA; it does not grant queue authority.

Batch membership binds each transaction to a block, index, and exact transaction hash. Individual execution or cancellation of batched transactions is blocked.

### Instance governance transition

**No takeover path found.**

Only current cross-chain governance may set `pendingGovernance`, and only that exact pending address may accept. The old governance remains effective until acceptance. Instance ownership after activation and cross-chain governance are intentionally separate authority domains.

### Version compatibility

Latest-patch lookup is constrained by the requested minor version, and deployed bytecode is checked at runtime for exact `contractType` and `version`. Factory minor versions are restricted to major version 3 by `MarketConfigurator`.

The repository’s “latest patch” trust model means approving a newer patch can affect later deployments and explicit factory upgrades. That is governance-controlled version selection, not an unprivileged upgrade path.

---

## Final assessment

Apart from the recovery-mode batch-consumption issue, the supplied contracts maintain the intended boundary: permissionless actors may deploy their own curator environments and relay already-authorized operations, but they cannot expand their authority into another market or bypass bytecode, ACL, governor, or timelock authorization.

The review is necessarily limited where behavior resides in imported Gearbox core contracts or omitted deployed bytecode, particularly pool, oracle, credit-manager, adapter, loss-policy, rate-keeper, and price-feed implementations.