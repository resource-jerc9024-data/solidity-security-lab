## Result

No credible, unprivileged Candidate survives the supplied production-source review.

I found several suspicious accounting and lifecycle patterns, but each lacks either attacker-controlled reachability or an in-scope Immunefi impact. Because shell and Foundry execution were prohibited, none has a working PoC; therefore nothing is labeled Confirmed.

## Rejected signals

### Rejected — Full repayment leaves a zero-debt GT alive

- Location: `contracts/v2/tokens/AbstractGearingTokenV2.sol`
  - `repayAndRemoveCollateral`
  - `_repay`
- Root cause: Unlike `repay` and `_flashRepay`, `repayAndRemoveCollateral` does not call `_burnInternal(id)` when `repayAll == true`. It writes a zero-debt loan back into `loanMapping`.
- Prerequisites: Attacker must own the GT or be delegated by its owner and must repay its entire debt.
- Sequence:
  1. Call `repayAndRemoveCollateral(id, fullDebt, ..., partialCollateral)`.
  2. Debt becomes zero.
  3. Selected collateral is returned.
  4. The NFT and remaining collateral record continue to exist.
  5. Before maturity, the owner can call `removeCollateral` for the remainder.
- Invariant discrepancy: “A fully repaid loan is burned” is violated as a lifecycle invariant.
- End impact: No theft or freeze was established. The remaining collateral stays withdrawable by the same owner/delegate before maturity. If the user voluntarily leaves it until maturity, ordinary collateral-removal methods become unavailable, but this is not an attacker-induced loss.
- Strongest disconfirming evidence: `removeCollateral` explicitly permits withdrawal with no health check when `loan.debtAmt == 0`.
- Minimal Foundry plan:
  1. Mint an ERC20-backed GT.
  2. Fully repay while removing only half the collateral.
  3. Assert `ownerOf(id)` still succeeds and debt is zero.
  4. Remove the remaining collateral.
  5. Assert the owner recovers all collateral and no third party profits.

### Rejected — Stable ERC4626 wrappers conceal pool losses behind a fixed 1:1 rate

- Locations:
  - `StableERC4626For4626.totalAssets`, `_convertToShares`, `_convertToAssets`
  - `StableERC4626ForAave.totalAssets`, `_convertToShares`, `_convertToAssets`
  - `StableERC4626ForCustomize.totalAssets`, `_convertToShares`, `_convertToAssets`
  - `StableERC4626ForVenus.totalAssets`, `_convertToShares`, `_convertToAssets`
- Root cause: These wrappers report `totalAssets() == totalSupply()` and always convert assets and shares 1:1, even if actual backing falls below supply.
- Plausible sequence:
  1. Third-party pool suffers a loss.
  2. Wrapper still quotes one asset per share.
  3. A new user deposits.
  4. An earlier shareholder withdraws newly supplied liquid assets.
- Violated invariant: Actual backing may satisfy  
  `underlying balance + pool assets < stable-share supply`,  
  while the reported exchange rate remains 1.
- Potential impact: Redistributive insolvency and eventual withdrawal reverts.
- Why rejected: The supplied code provides no unprivileged way to create the backing deficit. It requires failure, loss, or misconduct in an externally selected pool. The review rules exclude impacts requiring live-chain behavior, and pool selection is privileged and whitelist-controlled.
- Strongest disconfirming evidence: Under normal integrations, yield increases backing; deposits mint exactly the assets supplied, and withdrawals burn the same number of shares.
- Minimal Foundry plan:
  1. Use a mock pool capable of losing assets.
  2. Deposit for Alice, force a backing loss, then deposit for Bob.
  3. Have Alice withdraw Bob’s newly added liquidity.
  4. Demonstrate Bob’s withdrawal failure.
  5. This would establish the accounting consequence, but not an in-scope attacker path against approved production pools.

### Rejected — Customize wrapper counts the entire third-pool balance

- Location: `contracts/v2/tokens/StableERC4626ForCustomize.sol`
  - `_assetInPool`
  - `_depositToPool`
  - `_withdrawFromPool`
- Root cause: `_assetInPool` treats the entire underlying balance of `thirdPool` as wrapper backing, rather than tracking an isolated entitlement.
- Plausible sequence:
  1. Unrelated assets are held at `thirdPool`.
  2. They are counted as wrapper income.
  3. The owner withdraws supposed income, or users rely on overstated liquidity.
- Violated invariant: Reported backing should include only assets economically owned by this wrapper.
- End impact considered: Insolvency or freezing if the balance is not exclusively attributable to the wrapper.
- Why rejected: The contract explicitly requires an isolated, trusted pool with allowance back to the wrapper. Choosing or operating a non-isolated pool is privileged/configuration behavior, not an unprivileged exploit.
- Strongest disconfirming evidence: No public function lets an attacker redirect withdrawals or obtain the pool’s allowance.
- Minimal Foundry plan:
  1. Deploy a deliberately shared mock pool.
  2. Place unrelated underlying in it.
  3. Show `currentIncomeAssets` counts those tokens.
  4. Show withdrawal behavior depends on the mock pool granting allowance.
  5. Confirm that exploitability depends entirely on misconfiguration/control of the pool.

### Rejected — Venus income withdrawal rounds pool shares down

- Location: `contracts/v2/tokens/StableERC4626ForVenus.sol`
  - `withdrawIncomeAssets`
  - `_convertUnderlyingToShare`
- Root cause: When withdrawing income as vTokens, shares are calculated using floor division:
  `shares = floor(amount × 1e18 / exchangeRate)`,
  while `withdrawnIncomeAssets` increases by the full `amount`.
- Violated invariant: Historical withdrawn income can exceed the underlying value of shares actually transferred by less than one vToken share’s value.
- End impact: Dust remains in the wrapper; the recipient receives no more than requested.
- Why rejected: The rounding direction favors remaining holders. The function is also `onlyOwner`, so no attacker-controlled extraction exists.
- Minimal Foundry plan:
  1. Set a non-divisible exchange rate.
  2. Accrue income and withdraw it as vTokens.
  3. Compare the transferred vToken value with `amount`.
  4. Assert transferred value is at most `amount`, leaving only dust.

### Rejected — Redemption denominator changes after burning repaid FT

- Location: `contracts/v2/TermMaxMarketV2.sol`
  - `previewRedeem`
  - `_redeem`
- Signal: `_redeem` first burns all FT held by the market, then calculates the redeemer’s proportion using the reduced total supply.
- Conservation analysis:
  - FT repaid to the market represents already-satisfied debt.
  - Burning market-held FT cancels that claim.
  - Remaining debt tokens and collateral should be divided only among circulating FT.
  - Sequential redemptions use:
    `p = userFT / circulatingFT`,
    followed by proportional reduction of both circulating FT and remaining assets.
- Why rejected: `previewRedeem` already uses the equivalent denominator  
  `ft.totalSupply() - ft.balanceOf(market)`.  
  The state-changing path reaches the same denominator by burning the reserve first.
- End impact: No unfair dilution or extraction was identified beyond ordinary floor-rounding dust.
- Minimal Foundry plan:
  1. Create equal FT claims.
  2. Repay one loan using FT and another using debt tokens.
  3. Redeem remaining FT holders in both orders.
  4. Assert aggregate distributions equal available debt tokens and collateral, subject only to bounded rounding dust.

### Rejected — Flash leverage transfers debt tokens before collateral and XT settlement

- Location: `contracts/v2/TermMaxMarketV2.sol`
  - `_leverageByXt`
- Signal: The receiver gets `xtAmt` debt tokens before its callback, GT mint, and XT burn.
- Conservation equation:
  - Market debt-token reserve decreases by `x`.
  - XT supply decreases by `x`.
  - New GT debt is `d = xB/(B-fee)`.
  - New treasury FT is `d-x`.
  - The added terminal assets are GT repayment `d`.
  - The added terminal FT liability is `d-x`, while extinguishing XT corresponds to releasing `x`.
- Why rejected: Any failure to provide collateral, authorize XT burning, or satisfy GT health checks reverts the entire transaction, including the initial transfer. `nonReentrant` blocks recursive market entry.
- Minimal Foundry plan:
  1. Use a malicious callback receiver that attempts to retain the transfer.
  2. Omit collateral or XT approval.
  3. Assert the transaction reverts and all balances remain unchanged.
  4. On success, assert the liability/asset conservation equation above.

## Conclusion

The strongest code-quality issue is the unburned zero-debt NFT in `repayAndRemoveCollateral`, but the supplied code does not turn it into attacker-driven theft or freezing. The stable ERC4626 wrappers have meaningful insolvency semantics under external-pool loss, but no source-only, unprivileged mechanism was found to induce that loss.

Accordingly: no credible Candidate and no Confirmed finding from this source bundle.