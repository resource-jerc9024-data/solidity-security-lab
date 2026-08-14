# Gearbox V3.1 confirmed findings

## GBX-M-01: Permissionless Pyth updates can exhaust the feed's prepaid ETH on redundant data

- Severity: **Medium**
- Repository: `oracles-v3`
- Component: `contracts/oracles/updatable/PythPriceFeed.sol`
- Pinned commit: `287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d`
- Impact mapping: griefing with protocol damage and inability to operate due to
  lack of token funds; temporary disruption of price-dependent operations
- PoC: `poc/PythPriceFeedFeeAmplification.t.sol` (`2 passed, 0 failed`)

### Root cause

`PythPriceFeed.updatePrice` is permissionless and nonpayable. It decodes both the
expected timestamp and the complete `bytes[] updateData` from caller-controlled
calldata, computes `IPyth(pyth).getUpdateFee(updateData)`, and pays that amount
from ETH previously sent to the price-feed contract. The only post-update binding
is that the configured `priceFeedId` has the caller-supplied expected timestamp.

There is no bound on the number of updates, total fee, or relationship between
every paid update and the configured Gearbox feed. Pyth's production EVM code
charges for every encoded price update and intentionally succeeds when an update
is stale or redundant. Consequently, one fresh update for the configured feed can
be combined with duplicate or unrelated valid updates; the configured feed passes
the timestamp check while Gearbox pays the fee for all of them.

Relevant source:

- [Gearbox `PythPriceFeed.updatePrice`](https://github.com/Gearbox-protocol/oracles-v3/blob/287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d/contracts/oracles/updatable/PythPriceFeed.sol#L128-L150)
- [Gearbox permissionless `PriceFeedStore.updatePrices`](https://github.com/Gearbox-protocol/permissionless/blob/b1b5e5bac7d2183a1f10c4bcc3d4bbf88c8b7769/contracts/instance/PriceFeedStore.sol#L263-L271)
- [Pyth fee and update implementation](https://github.com/pyth-network/pyth-crosschain/blob/0418a8a75ac11783bc1fd34cc980c4679e856668/target_chains/ethereum/contracts/contracts/pyth/Pyth.sol#L62-L111)

### Attack sequence

1. A Gearbox Pyth feed has ETH precharged through its `receive()` function, as
   contemplated by the contract's own documentation.
2. The attacker obtains a valid current Pyth update for the configured
   `priceFeedId` and any number of other valid or duplicate updates.
3. The attacker calls `updatePrice(abi.encode(expectedTimestamp, updateData))`.
4. Gearbox pays `getUpdateFee(updateData)` from the feed's balance for every
   encoded update.
5. At least one entry advances the configured feed to `expectedTimestamp`, so
   Gearbox's only postcondition passes even though most of the fee was unnecessary.
6. Repeating this, or sizing one call to the available reserve, consumes the
   prepaid ETH. The next legitimate update reverts until the feed is funded again.

### Impact and severity

The attacker cannot withdraw the ETH and pays their own transaction gas, so direct
theft and High severity are not claimed. They can nevertheless force protocol ETH
to be paid to Pyth without a corresponding Gearbox need. Once the reserve is empty,
on-demand updates fail. After the stored Pyth price exceeds its ten-minute validity
window, credit-account checks and liquidation paths that need that feed can revert
until someone refills it. This is conservatively Medium under Gearbox's listed
griefing and lack-of-token-funds impacts.

Users can restore operation by funding the feed, including atomically through a
helper contract, so the effect is temporary rather than permanent. That recovery
does not prevent an attacker from consuming ordinary operational top-ups again.

### Deterministic PoC

The PoC deploys the pinned Gearbox `PythPriceFeed` with a fee-charging Pyth model
that mirrors the production semantics relevant to this defect: every valid update
is charged, while duplicate timestamps are accepted without replacing newer state.

With a reserve equal to 50 update fees, an unprivileged caller supplies 50 copies
of one valid target update. The target timestamp advances, the Gearbox post-check
passes, and the entire reserve is transferred as fees. A subsequent one-entry
legitimate update reverts for insufficient balance. The Codespace run recorded:

```text
[PASS] test_Control_SingleTargetUpdateConsumesOnlyOneFee()
[PASS] test_PermissionlessCallerCanConsumeEntirePrechargedBalanceWithDuplicateUpdates()
Suite result: ok. 2 passed; 0 failed; 0 skipped
```

Full output is retained in `runs/current/poc/pyth-fee-amplification.log`.

### Known-issue disposition

No matching public Gearbox issue, PR, disclosure, or public audit finding was
located. PRs `oracles-v3#45` and `#52` changed other Pyth validation behavior but
left the caller-controlled fee payment unchanged. The public ChainSecurity Oracles
V3 report's explicit scope does not include `PythPriceFeed`.

PR `#45` references several findings in a private Spearbit repository that is not
accessible through the authenticated account. Their contents could not be compared,
so they remain a submission-eligibility risk rather than evidence of a public
duplicate.

### Recommended remediation

Do not subsidize arbitrary permissionless update data from an unbounded contract
reserve. Prefer making the update path payable and requiring the caller to provide
the Pyth fee, forwarding only the exact required value and refunding any excess.
If Gearbox intentionally subsidizes updates, additionally parse and bind the paid
data to the configured `priceFeedId`, enforce a strict update-count/fee ceiling,
and restrict or rate-limit subsidized callers. Tests should cover duplicate blobs,
unrelated feed IDs, maximum-size payloads, repeated updates, and an empty reserve.
