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
commit, copies the already-installed Soldeer dependencies, applies only the
documented Linux test-import case correction, and pins Solidity `0.8.27`. It
then compiles production contracts, runs each non-fork V2 test file as a shard,
generates dedicated Slither build-info, and runs detector and structure passes.
Per-file sharding avoids a Solidity compiler termination seen with the entire
test tree in one compilation unit.

The second command runs four independent Codex review passes. Because this
Codespace kernel does not permit Bubblewrap namespaces, the runner embeds a
pass-specific read-only Solidity source bundle in each prompt and forbids tool,
shell, filesystem, and network calls. It does not use unsafe unrestricted
execution.

Generated evidence is written to `audits/termmax-v2/runs/current/`. Exit codes
are recorded in `status.tsv`; a non-zero analyzer exit is evidence to triage,
not proof of a vulnerability. See `RUN_SUMMARY.md` for the manually classified
baseline exceptions and `STATIC_TRIAGE.md` for detector dispositions.
