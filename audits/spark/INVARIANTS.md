# Spark test invariants

Add one local test per invariant once the relevant deployed implementation and fork block are pinned.

| ID | Area | Invariant | Required proof |
|---|---|---|---|
| SPK-INV-001 | vaults | Total redeemable assets cannot exceed controlled assets after arbitrary deposit/redeem/intent sequences | Stateful fuzz or invariant test |
| SPK-INV-002 | intents | A fulfilled or cancelled request cannot redeem again | Stateful fuzz test with reordered calls |
| SPK-INV-003 | ALM | Sum of assets moved through all routes never exceeds the active rate limit | Multi-route fuzz test |
| SPK-INV-004 | relays | A payload is accepted once, only from its configured source and sender | Replay/domain-separation test |
| SPK-INV-005 | rewards | Cumulative claims for an account and epoch do not exceed its allocation | Merkle/epoch fuzz test |
| SPK-INV-006 | lending | Spark configuration changes preserve collateral, debt and liquidation safety constraints | Fork-based configuration transition test |
