# Gearbox V3.1 independent review: credit, pool, and liquidation

Review only the supplied pinned Gearbox source. Start the security analysis fresh.
Do not transfer or analogize any vulnerability claim from TermMax or another protocol.

Focus on credit-account debt and collateral accounting, health checks, liquidation,
bad debt, interest accrual, quotas, pool shares, withdrawals, token masks, rounding,
multicall state transitions, and reentrancy. Trace complete permissionless transaction
sequences and cross-function state changes.

Report only concrete hypotheses. For each, provide exact file/function locations,
attacker-controlled inputs, preconditions, transaction sequence, violated invariant,
complete end effect, likely Gearbox/Immunefi impact, and a minimal local PoC plan.
Explicitly reject privileged-only, test-only, intended, or incomplete-impact ideas.
Tool output is not proof. If no credible path exists, say so.
