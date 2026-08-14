# Gearbox V3.1 independent review: adapters and external calls

Review only the supplied pinned Gearbox source. Start fresh; similarity to another
protocol is not evidence.

Focus on adapter calldata rewriting, selector restrictions, target validation,
approval lifecycle, token-mask changes, balance accounting, phantom tokens, gateways,
zappers, callbacks, multicalls, external-protocol return values, and interactions
between adapters and CreditFacade/CreditManager/CreditAccount. Look for ways one user
can affect another account, escape the active credit-account boundary, create false
collateral, retain approval, or bypass post-call health checks.

For every concrete hypothesis, give exact source locations, attacker control,
preconditions, full call sequence, violated Gearbox invariant, complete impact,
severity mapping, and a minimal local PoC. Reject third-party bugs, privileged setup,
and claims without an in-scope end effect. If none exist, say so.
