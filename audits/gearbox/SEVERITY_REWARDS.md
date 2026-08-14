# Gearbox V3.1 severity and reward worksheet

Use only after a deterministic local code PoC demonstrates a complete in-scope
impact. Gearbox and Immunefi determine final eligibility, severity, and payment.

| Severity | Published reward range | Rule |
|---|---:|---|
| Critical | `$6,000-$150,000` | Generally 10% of directly affected funds, capped at $150,000; Primacy of Impact. |
| High | `$3,000-$6,000` | Impact/funds-at-risk or temporary-freeze duration; Primacy of Impact. |
| Medium | `$1,000-$3,000` | Primacy of Rules. |
| Low | `$1,000` | Primacy of Rules. |

## Confirmation gate

1. The behavior exists in a clean, pinned, in-scope Gearbox source tree.
2. An unprivileged attacker can reach it under program rules.
3. A local code PoC demonstrates the complete listed impact.
4. The claim survives Gearbox issues, audits, disclosures, PRs, and history checks.
5. The PoC does not test mainnet, public testnets, third-party contracts, or oracles.

