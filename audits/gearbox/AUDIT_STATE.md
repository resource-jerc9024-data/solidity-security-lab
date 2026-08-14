# Gearbox V3.1 audit state

- Status: initial full-scope scan complete; one Medium finding confirmed
- Source commits: pinned in `SCOPE.md`
- Source trees: clean isolated checkouts; exact recursive submodules initialized
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
| Per-repository build/test discovery | Complete | `RUN_SUMMARY.md` and baseline logs |
| Architecture and trust-boundary map | Complete for initial scan | `THREAT_MODEL.md` |
| Gearbox invariants | Source-reviewed | `INVARIANTS.md` |
| Known-issue database | Initial review complete; private-review limitation recorded | `KNOWN_ISSUES.md` |
| Static and semantic passes | Complete | `STATIC_TRIAGE.md`, `CODEX_TRIAGE.md`, and run logs |
| Candidate reproduction | Complete for `CAND-001` | `CANDIDATES.md`, `FINDINGS.md`, and Gearbox-only PoC |

## Current result

- Confirmed: `GBX-M-01` (Medium), permissionless amplification of Pyth update
  fees paid from the feed's prepaid ETH reserve.
- Rejected semantic candidates: recovery-mode batch consumption (`REJ-001`) and
  phantom-token gas-probe disagreement (`REJ-002`).
- Baseline-only exception: missing external Upshift attachment instance (`TEST-001`).
- Remaining eligibility caveat: PR `oracles-v3#45` references private Spearbit
  issues whose contents are inaccessible, so an undisclosed duplicate cannot be
  ruled out from public evidence.
