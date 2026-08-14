# Gearbox V3.1 independent review: bots, emergency controls, and migrations

Review only the supplied pinned Gearbox source and begin from zero prior findings.

Focus on delegated bot permissions, partial liquidation, caller/account binding,
price-update handoff, residual allowances, emergency pause/liquidation, treasury
flows, account and liquidity migration, legacy-version compatibility, replay,
serialization assumptions, and state that crosses core/periphery/bot boundaries.
Preview-only code is not in scope and should be used only as contextual evidence.

For each credible unprivileged path, provide exact locations, attacker-controlled
inputs, authority prerequisites, transaction sequence, violated invariant, full end
effect, severity mapping, and deterministic local PoC design. Clearly reject ideas
that only assume emergency/governance authority. If no credible issue exists, say so.
