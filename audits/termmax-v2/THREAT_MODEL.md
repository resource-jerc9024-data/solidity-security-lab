# TermMax V2 threat model

## Protected assets and invariants

- User collateral, FT/XT balances, vault assets, and unclaimed yield cannot be
  stolen, permanently frozen, or made insolvent by an unprivileged actor.
- Market mint/burn/redeem flows conserve value across decimal conversions,
  fees, maturity transitions, and rounding.
- Vault shares represent the correct proportional claim through deposits,
  withdrawals, queues, bad-debt handling, and interest accrual.
- Gearing-token debt and collateral updates preserve solvency before and after
  liquidation, flash repayment, delegation, and delivery.
- Router callbacks and swap adapters cannot spend assets outside the initiating
  user's authorized flow or retain dangerous approvals.
- Oracle values use correct assets, decimals, freshness, bounds, and sequencer
  state before affecting solvency or liquidation.
- Initializers, upgrades, owners, guardians, curators, allocators, and whitelists
  enforce their documented authority without a public escalation path.

## Priority review lanes

| Lane | Main components | Failure modes |
|---|---|---|
| Accounting | Market, Order, Vault, ERC4626 wrappers | inflation, donation, rounding, stale interest, queue mismatch |
| Debt/liquidation | GearingToken, Market, Router | bad debt, under-collateralized extraction, partial-repay errors |
| External calls | Router, callbacks, swap adapters | reentrancy, callback spoofing, arbitrary spend, residual approval |
| Price safety | aggregators and adapters | decimals, stale/negative price, inversion, sequencer bypass |
| Authorization | access manager, roles, UUPS, pause | initializer takeover, role bypass, unsafe upgrade, storage drift |
| Maturity | FT/XT issue/redeem and order expiry | pre/post-maturity mismatch, stuck funds, double claim |

The threat model prioritizes unprivileged and permissionless attacker paths.
Centralization risks or attacks that merely assume a privileged role are outside
the program unless a separate code defect expands those privileges.
