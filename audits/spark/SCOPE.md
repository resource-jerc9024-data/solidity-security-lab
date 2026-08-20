# Spark scope snapshot

Snapshot date: **2026-08-15**. Re-verify immediately before a report or a new scan.

## Program terms that govern this workspace

- Maximum smart-contract reward: $5,000,000; critical minimum: $50,000; High: $10,000–$100,000.
- Proof of concept is required.
- The report must affect a deployed smart contract, not merely a GitHub branch.
- Spark uses Primacy of Impact, but testnet and mock files are excluded.
- Only local forks may be used for chain testing. Do not test deployed mainnet or public-testnet contracts directly.
- The scope page currently lists 359 assets; source capture alone does not prove deployment or scope eligibility.

Official references:

- https://immunefi.com/bug-bounty/sparklend/information/
- https://immunefi.com/bug-bounty/sparklend/scope/
- https://immunefi.com/bug-bounty/sparklend/resources/
- https://devs.spark.fi/security/security-and-audits

## Official code repositories

| Local name | Repository | Initial review role |
|---|---|---|
| sparklend | https://github.com/sparkdotfi/sparklend.git | Lending configuration and Spark adaptations |
| aave-v3-core | https://github.com/sparkdotfi/aave-v3-core.git | Inherited lending core; inspect Spark deltas and deployed configuration |
| aave-v3-periphery | https://github.com/sparkdotfi/aave-v3-periphery.git | Periphery and integration boundaries |
| spark-app | https://github.com/sparkdotfi/spark-app.git | App scope; defer until contract pass is complete |
| spark-alm-controller | https://github.com/sparkdotfi/spark-alm-controller.git | First-pass priority |
| spark-gov-relay | https://github.com/sparkdotfi/spark-gov-relay.git | First-pass priority |
| spark-rewards | https://github.com/sparkdotfi/spark-rewards.git | First-pass priority |
| spark-vaults-v2 | https://github.com/sparkdotfi/spark-vaults-v2.git | First-pass priority |

`scripts/bootstrap-spark.sh` captures the exact default-branch commits in `audits/spark/source/MANIFEST.tsv`. Do not replace those pins mid-review. A later refresh is a separate scan and must create a new run directory.
