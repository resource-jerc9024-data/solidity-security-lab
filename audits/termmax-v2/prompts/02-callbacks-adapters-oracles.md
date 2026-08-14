You are performing an authorized, read-only security review of the TermMax V2
Solidity repository at commit e314f3f849577dfecd4614f148c4df81fdf8c72d.

Review production contracts only. Focus deeply on router callbacks, flash repay,
swap adapters, arbitrary calldata boundaries, token approvals, fee-on-transfer
and unusual ERC20 behavior, reentrancy/cross-function reentrancy, callback
authentication, oracle asset identity, decimals, inversion, sign, staleness,
sequencer handling, and price manipulation assumptions.

Only the following contract end impacts matter: theft, permanent/temporary
freezing, insolvency, or theft/freezing of unclaimed yield. Incorrect data merely
supplied by a third-party oracle is out of scope, while a defect in TermMax's own
validation or conversion logic may be relevant. Use local reasoning only; do not
contact any chain, oracle, application, or service.

For each plausible candidate provide exact locations, attacker-controlled input,
call sequence, root cause, violated invariant, complete end effect, contrary
evidence, and a minimal local Foundry PoC. Treat automated patterns as leads,
not proof. Do not modify files. Label each item Candidate or Rejected, never
Confirmed without a working PoC. State explicitly if none survives.
