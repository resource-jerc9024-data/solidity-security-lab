# Gearbox V3.1 audit scope

- Program: https://immunefi.com/bug-bounty/gearbox/information/
- Scope: https://immunefi.com/bug-bounty/gearbox/scope/
- Canonical repository scope: https://github.com/Gearbox-protocol/security/blob/main/bug-bounty/v3_1-scope.md
- Scope snapshot verified: `2026-08-14`
- Program last updated by Immunefi: `2026-06-29`
- Review boundary: local source, local tests, and permitted local forks only

## In-scope source

Only the `main` or `master` branch is in scope unless Gearbox specifies otherwise.
Exact commits must be captured from clean local checkouts before analysis begins.

| Repository | Included production source | Pinned commit |
|---|---|---|
| https://github.com/Gearbox-protocol/permissionless | `contracts/`, excluding `contracts/test/` | `b1b5e5bac7d2183a1f10c4bcc3d4bbf88c8b7769` (`master`) |
| https://github.com/Gearbox-protocol/core-v3 | `contracts/`, excluding `contracts/test/` | `510fc6541c3767ce825929b4c311826fe81d6fa5` (`main`) |
| https://github.com/Gearbox-protocol/oracles-v3 | `contracts/`, excluding `contracts/test/` | `287739a0d85d4c1a2ad15b8aebcc2fcb4db0af4d` (`main`) |
| https://github.com/Gearbox-protocol/integrations-v3 | `contracts/`, excluding `contracts/test/` | `39e70f05e09ef4224febb3a8c9890afe48adbec9` (`main`) |
| https://github.com/Gearbox-protocol/bots-v3 | `contracts/bots/` | `ebec19d2396a1abcf69e6496a193abb7a9f5c027` (`main`) |
| https://github.com/Gearbox-protocol/periphery-v3 | `contracts/emergency/`, `contracts/kyc/`, and `contracts/migration/`, excluding contracts whose names contain `Previewer` | `2a63cf27b458c9c3b7824086da32f9dd6ee73613` (`main`) |

Gearbox's canonical V3.1 scope says the whole listed codebase matters, including
contracts that are not deployed. Mainnet-relevant PoCs should use contract versions
strictly between `3_10` and `3_20`, unless the canonical scope specifies otherwise.

## In-scope smart-contract impacts

- Critical: permanent freezing of funds.
- Critical: protocol insolvency.
- Critical: direct theft of user funds, at rest or in motion, excluding unclaimed yield.
- Critical: governance voting manipulation resulting in loss of funds.
- Critical: miner-extractable value (MEV).
- High: theft or permanent freezing of unclaimed yield.
- High: temporary freezing of funds.
- Medium: block stuffing for profit.
- Medium: inability to operate due to lack of token funds.
- Medium: griefing with damage to users or the protocol.
- Medium: theft of gas.

Critical and High use Primacy of Impact. Medium and Low remain subject to Primacy
of Rules. A code PoC is required for every severity.

## Authorized testing boundary

- Do not test against mainnet or public testnets; use local tests or local forks.
- Do not test third-party contracts or pricing oracles directly.
- Do not perform denial-of-service or traffic-generating service tests.
- Do not treat privileged access, bad third-party oracle data, tests, mocks,
  configuration, centralization, or best-practice concerns as bounty findings
  without a separate unprivileged in-scope impact.
- Do not submit or disclose a candidate until its PoC and known-issue checks pass.
