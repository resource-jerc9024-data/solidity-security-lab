# TermMax V2 — local review runbook

1. Capture the pinned commit and run the repository baseline.
2. Map state-changing external functions, trust boundaries, roles, pause/upgrade
   controls, accounting, and token flows.
3. Run Slither as triage, then inspect every candidate manually.
4. Use unit, fuzz, and invariant tests to prove an in-scope end effect.
5. Classify the proven impact with `SEVERITY_REWARDS.md`.
6. Keep findings private until the project approves publication.
