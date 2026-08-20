# Spark threat model

This is a review checklist, not a claim that a weakness exists.

## Assets and boundaries

| Boundary | Attacker-controlled input | Property to prove |
|---|---|---|
| Savings vaults / ERC-4626 | deposit, mint, withdraw, redeem, recipient, share allowance | assets and shares remain conserved; no user can redeem another user's shares |
| Withdrawal intents | request creation, cancellation, recipient, deadlines, fulfillment timing | a request is unique, cannot be replayed/replaced unexpectedly, and can only consume the intended shares |
| ALM controller | public entry points, tokens, amounts, routes, rate-limit windows | limits and accounting cannot be bypassed or desynchronized |
| Cross-chain SSR / governance relays | message payloads, ordering, delivery/retry behavior | source domain and sender are authenticated; messages execute once with intact parameters |
| Lending deployments | collateral, borrow, liquidation, reserve configuration | Spark-specific configuration cannot create bad debt, unauthorized borrowing, or unsafe parameter transitions |
| Rewards | proof, amount, recipient, epoch/root changes | claims are bounded, non-replayable, and paid to the intended recipient |

## Priority invariants

1. Every asset-outflow path requires authority attributable to the owner, an authorized role, or a validated cross-chain message.
2. Assets, shares, debt, and cross-chain representations remain conserved across each completed state transition.
3. A message, fulfillment, claim, or signature cannot be replayed across calls, epochs, chains, or contracts.
4. Rate limits account for every equivalent route and cannot be bypassed with rounding, aliases, batching, or reentrancy.
5. Upgrade and role changes cannot leave a privileged external call path with broader authority than intended.

Populate this file with concrete contracts, deployment addresses, commit pins, and call graphs after baseline discovery.
