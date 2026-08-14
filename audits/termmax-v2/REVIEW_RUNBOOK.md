# TermMax V2 - local review runbook

1. Capture the pinned commit and run the repository baseline.
2. Map state-changing external functions, trust boundaries, roles, pause/upgrade
   controls, accounting, and token flows.
3. Run Slither as triage, then inspect every candidate manually.
4. Use unit, fuzz, and invariant tests to prove an in-scope end effect.
5. Classify the proven impact with `SEVERITY_REWARDS.md`.
6. Keep findings private until the project approves publication.

## Reproducible Codespace commands

From `/workspaces/solidity-security-lab`:

```bash
bash scripts/run-termmax-audit.sh
bash scripts/run-termmax-codex-passes.sh
```

The first command creates an isolated review worktree at the exact pinned
commit, applies only the documented Linux test-import case correction, then
runs contract compilation, non-fork unit tests, invariants, Slither detectors,
and Slither structure printers. The second command runs independent read-only
Codex review passes and records only their final candidate reports.

Generated evidence is written to `audits/termmax-v2/runs/current/`. Exit codes
are recorded in `status.tsv`; a non-zero analyzer exit is evidence to triage,
not proof of a vulnerability.
