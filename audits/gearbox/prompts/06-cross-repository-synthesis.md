# Gearbox V3.1 adversarial cross-repository synthesis

Perform a fresh synthesis over the supplied pinned Gearbox source. Never carry over
a TermMax or other-protocol vulnerability claim without proving the complete behavior
in these files.

Look specifically for mismatched assumptions between permissionless, core, oracles,
integrations, bots, and periphery: interfaces, versions, units, token masks, calldata,
roles, deployment verification, health checks, callbacks, liquidation, and migration.
Chain individually safe operations into permissionless sequences that yield theft,
freezing, insolvency, governance loss, MEV, griefing, gas theft, or inability to
operate from missing token funds.

Prioritize at most five concrete hypotheses. Each must include exact locations,
root cause, attacker control, transaction sequence, violated invariant, full end
effect, likely severity, PoC steps, and the strongest rejection condition. Do not
inflate speculative observations. If no PoC-ready path exists, state that clearly.
