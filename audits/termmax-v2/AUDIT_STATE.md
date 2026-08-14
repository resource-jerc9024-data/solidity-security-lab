# TermMax V2 audit state

- Status: in progress
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
| Baseline build/test | Pending | `runs/current/status.tsv` |
| Static analysis | Pending | `runs/current/slither*` |
| Independent Codex review passes | Pending | `runs/current/codex/` |
| Candidate reproduction | Pending | `CANDIDATES.md` |
| Known-issue/audit comparison | Pending | `CANDIDATES.md` |

No bounty report is ready for submission while any required evidence gate is
pending.
