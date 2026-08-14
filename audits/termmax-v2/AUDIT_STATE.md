# TermMax V2 audit state

- Status: review complete; no reward-eligible finding confirmed
- Source commit: `e314f3f849577dfecd4614f148c4df81fdf8c72d`
- Source branch at verification: `origin/main`
- Source tree at verification: clean
- Scope checked: `2026-08-14`
- Review boundary: local source, local tests, and local forks only

## Evidence policy

1. Scanner output begins as an unverified signal.
2. Manual review must establish attacker control, reachability, and the violated
   invariant.
3. A local PoC must demonstrate the complete listed Immunefi impact.
4. Prior audits, known issues, duplicates, and intended behavior must be checked.
5. Only then may an item move to `FINDINGS.md` as Confirmed.

## Current phases

| Phase | State | Evidence |
|---|---|---|
| Scope refresh | Complete | `SCOPE.md` |
| Commit pin and repository check | Complete | `runs/current/metadata.md` after runner execution |
| Baseline build/test | Complete | `RUN_SUMMARY.md`, `runs/current/status.tsv`, `runs/current/test-shards/` |
| Static analysis | Complete | `STATIC_TRIAGE.md`, `runs/current/slither*` |
| Independent Codex review passes | Complete | `CODEX_TRIAGE.md`, `runs/current/codex/` |
| Candidate reproduction | Complete | `CANDIDATES.md`, `poc/RouterSameTokenBalanceSweep.t.sol` |
| Known-issue/audit comparison | Complete | `CANDIDATES.md`; exact public duplicate PR linked there |

The only hypothesis that crossed the complete technical impact gate is
`DUP-001`. It is not submission-ready because an earlier public upstream pull
request documents the same root cause, drain path, and remediation. All other
leads failed reachability, independence, or listed-impact requirements.
