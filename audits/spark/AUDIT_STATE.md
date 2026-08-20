# Spark audit state

- Status: infrastructure prepared; source capture not yet run
- Program: Immunefi Spark bug bounty
- Scope checked: 2026-08-15
- Source pins: pending `scripts/bootstrap-spark.sh`

## Non-negotiable gates

1. Work only against the live Immunefi scope and exact deployed implementations.
2. Test exclusively in local unit tests or local forks. Never transact against mainnet or a public testnet.
3. Treat static-analysis and model output as hypotheses, never as findings.
4. A candidate requires attacker control, reachability, a violated invariant, an in-scope impact, and a deterministic local PoC.
5. Compare every candidate against published audits, known issues, disclosures, and repository history before confirmation.
6. Do not commit API keys, RPC URLs containing credentials, private keys, PoCs, or unpublished findings.

## Initial focus

1. `spark-vaults-v2`: withdrawal intents, ERC-4626 accounting, authorization, and liquidity fulfillment.
2. `spark-alm-controller`: limits, conversions, access boundaries, cross-domain accounting.
3. `spark-gov-relay`: replay, ordering, source authentication, and parameter integrity.
4. `spark-rewards`: claims, epoch roots, accounting, and token transfer behavior.
5. `sparklend`, `aave-v3-core`, and `aave-v3-periphery`: Spark-specific deployments and configuration deltas only.

## Phase gates

| Phase | State | Evidence |
|---|---|---|
| Scope snapshot | Complete | `SCOPE.md` |
| Source capture and commit pins | Pending | `source/MANIFEST.tsv` |
| Build/test baseline | Pending | `runs/current/baseline/` |
| Architecture and trust map | Pending | `THREAT_MODEL.md` |
| Invariants and attack matrix | Pending | `INVARIANTS.md` |
| Static triage | Pending | `STATIC_TRIAGE.md` |
| Candidate reproduction | Pending | `CANDIDATES.md`, local untracked PoCs |
