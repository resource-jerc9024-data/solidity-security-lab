# Gearbox V3.1 audit state

- Status: source/toolchain discovery; security analysis not started
- Source commits: pinned in `SCOPE.md`
- Source trees: clean shallow checkouts; dependency submodules not initialized
- Scope checked: `2026-08-14`
- Prior TermMax conclusions imported: none

## Evidence policy

1. Capture every in-scope repository at a clean, exact commit before scanning.
2. Establish Gearbox-specific trust boundaries and invariants from source and docs.
3. Treat scanner and Codex output only as hypotheses.
4. Prove attacker control, reachability, invariant violation, and complete listed impact.
5. Require a deterministic local code PoC for every severity.
6. Check Gearbox issues, audits, disclosures, and code history before confirmation.
7. Never infer Gearbox exposure from a TermMax behavior or finding.

## Phase gates

| Phase | State | Required evidence |
|---|---|---|
| Current scope capture | Complete | `SCOPE.md` |
| Repository checkout and commit pins | Complete | `SCOPE.md`, `runs/current/metadata.md` |
| Per-repository build/test discovery | In progress | `REVIEW_RUNBOOK.md` and baseline logs |
| Architecture and trust-boundary map | Pending | `THREAT_MODEL.md` |
| Gearbox invariants | Pending source validation | `INVARIANTS.md` |
| Known-issue database | Initialized | `KNOWN_ISSUES.md` |
| Static and semantic passes | Pending | run logs and triage records |
| Candidate reproduction | Pending | `CANDIDATES.md` and Gearbox-only PoCs |
