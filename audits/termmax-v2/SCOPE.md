# TermMax V2 — local audit scope

- Program: https://immunefi.com/bug-bounty/termstructurelabs/information/
- Scope: https://immunefi.com/bug-bounty/termstructurelabs/scope/
- Official repository: https://github.com/term-structure/termmax-contract-v2
- Pinned review commit: `e314f3f849577dfecd4614f148c4df81fdf8c72d`
- Local checkout: `/workspaces/audits/termmax-contract-v2`

## In scope

Prioritize the TermMax V2 smart contract, the program's stated primary target.
The program lists 3 total assets. Review the current Immunefi scope before
reporting because scope can change after this snapshot.

## Authorized testing boundary

- Local source, unit tests, fuzz tests, and local forks only.
- No mainnet or public-testnet transactions.
- No automated traffic against services, no denial-of-service testing, no third-
  party oracle or contract testing.
- Do not submit a report without a reproducible local PoC and a known-issue/
  audit check.
