# Gearbox V3.1 review runbook

## Reuse decision

Reuse the evidence mechanics: isolated clean checkouts, exact commit metadata,
timestamped step/status tables, per-tool logs, independent Codex lanes, manual
triage, severity gates, and deterministic local PoCs.

Do not reuse TermMax source paths, compiler settings, dependency handling, harness
patches, test sharding rules, prompts, threat assumptions, candidate text, or PoCs.
Per-repository commands must come from each pinned Gearbox repository's own build
configuration and baseline documentation.

## Ordered gates

1. Clone all six official repositories and record clean `main`/`master` commits.
2. Inventory toolchains, dependencies, remappings, submodules, and baseline commands.
3. Build and test each repository unchanged; classify baseline exceptions.
4. Map cross-repository interfaces and deployed-version relevance.
5. Validate and expand `THREAT_MODEL.md` and `INVARIANTS.md` from exact source.
6. Populate `KNOWN_ISSUES.md` before promoting any hypothesis.
7. Create Gearbox-specific static-analysis configuration and Codex prompts by lane.
8. Manually trace all signals; create local PoCs only for reachable impact paths.
9. Confirm only candidates that pass the complete evidence and duplicate gates.

Generated evidence belongs under `audits/gearbox/runs/current/`, with one directory
per repository and separate `codex/` and `poc/` logs. Large generated logs should
be reviewed before deciding whether they belong in version control.

