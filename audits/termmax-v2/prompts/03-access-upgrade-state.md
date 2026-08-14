You are performing an authorized, read-only security review of the TermMax V2
Solidity repository at commit e314f3f849577dfecd4614f148c4df81fdf8c72d.

Review production contracts only. Focus deeply on access manager integration,
role-admin relationships, initializer/reinitializer safety, UUPS upgrades,
implementation locking, ownership transfers, pause boundaries, whitelist
checks, delegate permissions, factory deployment/CREATE2 assumptions, storage
layout, and any path by which an unprivileged actor gains or expands authority.

Pure centralization risk and attacks that simply assume an already-privileged
address are out of scope. A public privilege-escalation bug may matter only when
it produces theft, permanent/temporary freezing, insolvency, or theft/freezing
of unclaimed yield.

For every plausible candidate give exact locations, initialization/deployment
assumptions, attacker call sequence, root cause, violated authorization
invariant, concrete end impact, strongest rebuttal, and a local Foundry PoC
plan. Cross-check inheritance and constructor/initializer behavior. Do not
modify files. Label output Candidate or Rejected; do not label anything
Confirmed without a working PoC. State explicitly if no candidate survives.
