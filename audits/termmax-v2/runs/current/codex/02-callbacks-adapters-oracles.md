I found no item that can be labeled Confirmed. The supplied bundle lacks the market/gearing-token implementations needed to demonstrate an end-to-end insolvency or liquidation exploit, and I could not execute Foundry under the stated restrictions.

Two router issues survive as plausible Candidates. The oracle leads are Rejected for the requested impact model or because their end effect cannot be established from this bundle.

## Candidate — Permissionless extraction of every token balance stranded in the router

Locations:

- `TermMaxRouterV2._executeSwapPaths`:
  `useBalanceOnchain` sets the input to `IERC20(...).balanceOf(address(this))`.
- `TermMaxRouterV2._executeSwapUnits`:
  an adapter address of zero transfers `inputAmt` directly to the caller-selected `recipient`.
- Related whole-balance accounting:
  - `_flashRepayFromCollateral`
  - `_rollover`
  - `_rolloverToAave`
  - `_rolloverToMorpho`
  - `TerminalVaultAdapter._swap`

Attacker-controlled input:

- `SwapPath.useBalanceOnchain`
- `SwapPath.recipient`
- `units[0].tokenIn`
- A zero adapter, or an adapter whose refund address is attacker-controlled

Call sequence:

1. Tokens remain in the router after an earlier operation. Possible sources include:

   - unexpected ERC20 transfer behavior;
   - an adapter refund sent to `address(this)`;
   - output exceeding an amount subsequently forwarded;
   - direct token transfers;
   - accounting based on the router’s total balance rather than a per-operation delta.

2. The attacker calls `swapTokens` with:

   - `useBalanceOnchain = true`;
   - `units[0].tokenIn = strandedToken`;
   - `units[0].adapter = address(0)`;
   - `units[0].tokenOut != tokenIn`;
   - `recipient = attacker`.

3. `_executeSwapPaths` reads the router’s entire balance.
4. `_executeSwapUnits` transfers that entire balance to the attacker.

Root cause:

The router treats its global token balance as caller-owned input. It maintains no depositor attribution, operation-local starting balance, or authorization proving that the caller supplied the balance.

Violated invariant:

A user must not be able to consume token balances contributed by another user or left by an earlier operation.

Complete end effect:

Theft of any token balance stranded in the router. This includes potentially unclaimed refunds or collateral/debt-token residue. The issue does not require a malicious adapter.

Contrary evidence:

- Normal successful paths generally attempt to forward their complete result.
- `nonReentrant` prevents stealing an in-flight balance by reentering `swapTokens`.
- Therefore exploitation requires a balance to survive after the preceding transaction.
- The bundle does not establish a normal production path that necessarily leaves a material balance, so the theft precondition remains unproven.
- Tokens deliberately transferred directly to the router may reasonably be considered unrecoverable dust, although the function permits taking arbitrary-sized balances, not merely dust.

Minimal local Foundry PoC:

```solidity
function test_anyoneCanTakeRouterBalance() public {
    MockERC20 token = new MockERC20("Token", "TOK", 18);

    // Deploy and initialize the router with a whitelist manager that permits
    // the test configuration.
    TermMaxRouterV2 router = deployRouter();

    // Models residue belonging to a prior user/operation.
    token.mint(address(router), 100 ether);

    SwapUnit[] memory units = new SwapUnit[](1);
    units[0] = SwapUnit({
        adapter: address(0),
        tokenIn: address(token),
        tokenOut: address(1), // Must differ so the unit is not skipped.
        swapData: ""
    });

    SwapPath[] memory paths = new SwapPath[](1);
    paths[0] = SwapPath({
        inputAmount: 0,
        recipient: attacker,
        useBalanceOnchain: true,
        units: units
    });

    vm.prank(attacker);
    router.swapTokens(paths);

    assertEq(token.balanceOf(attacker), 100 ether);
    assertEq(token.balanceOf(address(router)), 0);
}
```

This PoC proves the extraction primitive, but not that a production transaction necessarily creates a material stranded balance. The item therefore remains Candidate.

## Candidate — Several whitelisted adapters allow attacker-selected spenders or call targets

Locations:

- `KodiakSwapAdapter._swap`:
  decodes an attacker-selected `IKodiakRouter router`, approves it, then calls it.
- `OkxSwapAdapter._swap`:
  decodes attacker-selected `router` and `okxApproveAddress`, approves the latter, then calls the former.
- `UniswapV3AdapterV2._swap`:
  decodes an attacker-selected `ISwapRouter router` and approves it.
- `TerminalVaultAdapter._swap`:
  decodes an attacker-selected `ITerminalVault vault` and approves it for deposits.
- `KyberswapV2AdapterV2._swap`, `LifiSwapAdapter._swap`, and
  `PancakeSmartAdapter._swap`:
  send largely arbitrary calldata to fixed external routers.
- `LifiSwapAdapter._swap` and `PancakeSmartAdapter._swap`:
  comments assert that encoded recipients are the adapter/router, but the contracts do not decode and validate those recipients.

Attacker-controlled input:

- External call target or approval spender in the adapters listed above
- Arbitrary encoded calldata
- Refund address and encoded swap recipient
- In conjunction with the first Candidate, a router-resident token balance

Call sequence:

1. A target token balance exists in `TermMaxRouterV2`.
2. The attacker selects a whitelisted adapter such as `OkxSwapAdapter`.
3. The attacker supplies `useBalanceOnchain = true`.
4. Adapter calldata identifies an attacker-controlled spender and call target.
5. Because adapters execute using `delegatecall`, the approval is issued by `TermMaxRouterV2`.
6. The malicious spender consumes the approved router tokens and sends value to the attacker.
7. It returns data formatted as the adapter expects so execution completes.

Root cause:

The router whitelist authenticates adapter implementation code, but some adapters delegate the sensitive trust decision back to user calldata. Consequently, whitelisting the adapter does not constrain the ultimate spender or external call target.

Violated invariant:

A whitelisted adapter must limit token approvals and arbitrary calls to the protocol integration for which it was reviewed.

Complete end effect:

Theft of the selected router-held token balance. Persistent nonzero allowances may also expose later deposits to the attacker-controlled spender, depending on `TransferUtilsV2.safeApprove` behavior and whether the malicious target consumes the allowance immediately.

Contrary evidence:

- Without `useBalanceOnchain`, the normal input was just transferred from the same caller, so a malicious target primarily steals the attacker’s own tokens.
- `nonReentrant` prevents using this primitive against balances held only during another user’s active router call.
- The supplied `TransferUtilsV2` implementation is absent, so residual-allowance behavior cannot be established.
- The simpler zero-adapter path already extracts any preexisting balance; thus the arbitrary-target defect does not independently prove a broader production loss.
- Fixed routers may internally validate their calldata, but that does not mitigate adapters where the router itself is user-selected.

Minimal local Foundry PoC:

```solidity
contract MaliciousSpender {
    function steal(IERC20 token, address router, address receiver, uint256 amount)
        external
        returns (uint256)
    {
        token.transferFrom(router, receiver, amount);
        return amount;
    }
}

function test_whitelistedOkxAdapterCanApproveArbitrarySpender() public {
    MockERC20 token = new MockERC20("Token", "TOK", 18);
    TermMaxRouterV2 router = deployRouter();
    OkxSwapAdapter adapter = new OkxSwapAdapter();
    MaliciousSpender malicious = new MaliciousSpender();

    whitelistAdapter(address(adapter));
    token.mint(address(router), 100 ether);

    bytes memory maliciousCall = abi.encodeCall(
        malicious.steal,
        (IERC20(address(token)), address(router), attacker, 100 ether)
    );

    bytes memory adapterData =
        abi.encode(address(malicious), address(malicious), maliciousCall);

    SwapUnit[] memory units = new SwapUnit[](1);
    units[0] = SwapUnit({
        adapter: address(adapter),
        tokenIn: address(token),
        tokenOut: address(otherToken),
        swapData: adapterData
    });

    SwapPath[] memory paths = new SwapPath[](1);
    paths[0] = SwapPath({
        inputAmount: 0,
        recipient: attacker,
        useBalanceOnchain: true,
        units: units
    });

    vm.prank(attacker);
    router.swapTokens(paths);

    assertEq(token.balanceOf(attacker), 100 ether);
}
```

The real `OKXScaleHelper` may require calldata matching a supported OKX selector. A production-compatible PoC would encode one of those accepted forms with attacker-controlled target fields. Without executing against the dependency, this remains Candidate.

## Rejected — Callback authentication bypass

Locations:

- `onlyCallbackAddress`
- both `executeOperation` overloads
- `leverage`
- `_flashRepayFromCollateral`
- `_rolloverGt`

Lead:

The callbacks are externally callable and execute swaps, approvals, rollover logic, and arbitrary callback data.

Reason for rejection:

The expected callback is stored in transient storage immediately before the synchronous external call. `onlyCallbackAddress` clears it before checking `msg.sender`, preventing callback reuse. A failed authentication reverts the clearing as part of the transaction, but there is no outer operation the attacker can resume from. The top-level value-moving functions are also `nonReentrant`.

No path was found for an unrelated contract to become the stored callback address during another user’s operation.

## Rejected — Cross-function reentrancy through adapters or unusual ERC20 hooks

Lead:

Adapters execute through `delegatecall`, and transfers, approvals, vault deposits, swaps, and token balance queries can invoke hostile contracts.

Reason for rejection:

All public router entry points that move value use `nonReentrant`. The callback functions intentionally remain callable during the guarded operation, but they require the transiently authenticated market or gearing token. A malicious token or adapter cannot call those callbacks with the authenticated sender identity unless that exact whitelisted market or gearing token is itself malicious.

Whitelist compromise or a malicious whitelisted market is outside a permissionless attack model.

## Rejected — Fee-on-transfer tokens break router accounting

Locations:

- `_executeSwapPaths` passes `path.inputAmount` after `safeTransferFrom`, without measuring the received delta.
- `borrowTokenFromCollateral` passes nominal `collInAmt`.
- Several adapters approve and attempt to spend nominal amounts.
- `TermMaxSwapAdapter` requires exact balance deltas.

Reason for rejection:

Fee-on-transfer inputs can make operations revert, and in some integrations might make downstream calls receive less than expected. However, atomic reversion prevents loss in the straightforward cases. The bundle does not demonstrate a successful transaction that creates theft, insolvency, or permanent freezing rather than incompatibility or user-selected slippage.

The possible creation of stranded balances is already covered by the first Candidate.

## Rejected — OracleAggregatorV2 accepts a zero price

Location:

- `OracleAggregatorV2._checkAnswer`: rejects `answer < 0`, not `answer <= 0`.

Lead:

A live primary or backup feed returning zero is treated as valid and returned by `getPrice`.

Reason for rejection:

This is a real validation weakness: the comments say the price must be positive, while the implementation accepts zero. But incorrect data supplied by a third-party oracle is expressly out of scope. More importantly, the supplied bundle omits the collateral valuation and liquidation arithmetic needed to prove whether zero causes safe reversion, liquidation, freezing, or insolvency.

A defensible correction would reject `answer <= 0`, but no qualifying contract-end impact can be established here.

## Rejected — Missing Chainlink round-integrity validation

Locations:

- `OracleAggregatorV2.getPrice`
- `TermMaxPriceFeedConverter.latestRoundData`
- `TermMaxERC4626PriceFeed.latestRoundData`
- `TermMaxPTPriceFeed.latestRoundData`

Lead:

These contracts generally do not validate:

- `updatedAt != 0`;
- `answeredInRound >= roundId`;
- round IDs consistently across composed feeds.

Reason for rejection:

`OracleAggregatorV2` does enforce configured heartbeat freshness, except where governance explicitly sets heartbeat to zero. Modern feeds may not require the legacy `answeredInRound` check. A malicious or incorrect third-party feed response is out of scope, and no TermMax conversion defect yielding a qualifying end effect was demonstrated.

## Rejected — Sequencer feed arithmetic and configuration edge cases

Locations:

- `OracleAggregatorWithSequencerV2._isSequencerUp`
- `setSequencerUptimeFeedAndGracePeriod`

Leads:

- `block.timestamp - startedAt` reverts if `startedAt` is in the future.
- A zero or incompatible sequencer feed address freezes `getPrice`.
- There is no validation that `answer` is only zero or one.

Reason for rejection:

Future timestamps or malformed answers originate from the third-party feed. Setting an invalid feed is an owner-controlled configuration error. These can freeze oracle access but do not provide a permissionless attacker-controlled sequence in the supplied contracts.

## Rejected — Manipulable Uniswap/Pancake TWAP

Locations:

- `TermMaxUniswapTWAPPriceFeed._consult`
- `TermMaxUniswapTWAPPriceFeed.latestRoundData`
- `TermMaxPancakeTWAPPriceFeed._ensureSufficientObservations`

Lead:

The constructor checks token identity and observation history but imposes no minimum liquidity, manipulation-cost, or trusted-factory constraint. A sufficiently low-liquidity configured pool can have its TWAP manipulated.

Reason for rejection:

The pool and TWAP duration are immutable deployment choices, and deploying an adapter does not itself make TermMax consume it. Exploitability depends on the configured pool liquidity, TWAP duration, economic manipulation cost, and omitted lending parameters. No complete insolvency or theft sequence can be established locally from this bundle.

## Rejected — `SimpleAggregator` negative-answer conversion

Location:

- `SimpleAggregator.getPrice`: `price = uint256(answer)`.

Lead:

A negative signed answer converts to an enormous unsigned price.

Reason for rejection:

The contract is documented for constant feeds and deployment/configuration determines the feed. A negative result would be erroneous third-party data or privileged misconfiguration. The bundle contains no permissionless way to replace its immutable feed mapping or prove a qualifying downstream loss.

## Rejected — Adapter asset-identity mismatches

Examples:

- `OneInchSwapAdapter` does not verify `desc.srcToken` or `desc.dstToken`.
- `KodiakSwapAdapter` does not verify `input.token` or `output.token`.
- `OdosV2AdapterV2` does not verify `tokenInfo.inputToken` or `outputToken`.
- `UniswapV3AdapterV2` does not decode and validate path endpoints.
- `PendleSwapV3AdapterV2` does not require `tokenIn` to match the selected market’s supported asset.

Reason for rejection:

These are meaningful integration-boundary defects, but a caller normally controls and funds their own swap. Against third-party value, they reduce to consuming a preexisting router balance, already captured by the first two Candidates. No separate end effect was proven.

Final result: two Candidates survive, both centered on theft of balances already resident in the router. Nothing reaches Confirmed status, and no independent oracle, callback-authentication, flash-repay, reentrancy, or fee-on-transfer finding with the required end impact survives the supplied evidence.