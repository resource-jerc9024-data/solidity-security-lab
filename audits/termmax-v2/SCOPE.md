# TermMax V2 - local audit scope

- Program: https://immunefi.com/bug-bounty/termstructurelabs/information/
- Scope: https://immunefi.com/bug-bounty/termstructurelabs/scope/
- Official repository: https://github.com/term-structure/termmax-contract-v2
- Pinned review commit: `e314f3f849577dfecd4614f148c4df81fdf8c72d`
- Local checkout: `/workspaces/audits/termmax-contract-v2`
- Scope snapshot verified: `2026-08-14`
- Program last updated by Immunefi: `2026-08-03`

## In scope

Prioritize the TermMax V2 smart contract, the program's stated primary target.
The program lists 3 total assets, but this review is contract-only. The website
and application assets are not part of this run.

In-scope smart-contract impacts at the snapshot date:

- Critical: direct theft of user funds other than unclaimed yield.
- Critical: permanent freezing of funds.
- Critical: protocol insolvency.
- High: theft or permanent freezing of unclaimed yield.
- High: temporary freezing of funds.

Primacy of Rules applies. A technically real issue is not a valid bounty report
unless both the affected asset and the demonstrated impact are in scope.

## Authorized testing boundary

- Local source, unit tests, fuzz tests, and local forks only.
- No mainnet or public-testnet transactions.
- No automated traffic against services, no denial-of-service testing, no third-
  party oracle or contract testing.
- Do not submit a report without a reproducible local PoC and a known-issue/
  audit check.
- Do not classify test/configuration defects as bounty findings unless they lead
  to an independently proven in-scope production-contract impact.
