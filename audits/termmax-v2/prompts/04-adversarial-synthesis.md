You are performing a final independent, authorized, read-only adversarial review
of TermMax V2 at commit e314f3f849577dfecd4614f148c4df81fdf8c72d.

Build a compact architecture and trust-boundary map, then search for multi-step
and cross-contract failures missed by single-contract review: maturity races,
rounding accumulation, donation/front-running, callbacks during partial state,
debt transfer/delegation plus liquidation, queue reordering, stale accounting,
adapter composition, oracle conversion, fee extraction, and factory/proxy
initialization.

The only relevant Immunefi smart-contract outcomes are theft, permanent or
temporary freezing, insolvency, and theft/freezing of unclaimed yield. Exclude
privileged-only, centralization, best-practice, test/config-only, unavailable
oracle data, and speculative issues without a reachable end effect.

Act as a skeptical verifier. For every candidate identify exact locations, the
shortest unprivileged transaction sequence, required capital/timing, root cause,
violated invariant, measurable end effect, severity hypothesis, disconfirming
checks, and minimal deterministic local PoC. Rank candidates by evidence, not
imagination. Do not modify files and do not call an item Confirmed without an
executed PoC. If the correct result is no credible candidate, state that.
