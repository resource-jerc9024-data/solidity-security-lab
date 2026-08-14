# Gearbox V3.1 known-issue database

No vulnerability entries have been imported from TermMax or any other protocol.
This database is initialized but not yet populated or triaged.

## Mandatory sources

| Source | Status | Notes |
|---|---|---|
| https://github.com/Gearbox-protocol/core-v2/issues | Pending review | Explicitly named by the Immunefi program. |
| https://github.com/Gearbox-protocol/core-v3/issues | Pending review | Explicitly named by the Immunefi program. |
| https://github.com/Gearbox-protocol/security/tree/main/audits | Pending review | Map reports to affected versions and current code. |
| https://github.com/Gearbox-protocol/security/tree/main/disclosures | Pending review | Treat matching root causes as known even if fixed elsewhere. |
| In-scope repository issues and pull requests | Pending review | Search all six repositories. |
| In-scope repository commit history | Pending review | Search fixes and security-relevant behavior changes. |

## Entry schema

Each entry must record an ID, source link, affected repository/version, root cause,
impact, fix or mitigation, current-code match status, and candidate IDs it excludes.
A textual similarity is insufficient: duplicate disposition requires matching the
same root cause and materially equivalent attack behavior.

