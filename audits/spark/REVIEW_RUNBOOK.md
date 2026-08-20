# Spark local review runbook

Run commands from the Linux/WSL clone of this workspace. The scripts use current stable tooling already installed in that environment, but preserve each repository's lockfiles and compiler configuration. They do not force a global Solidity version.

```bash
bash scripts/check-environment.sh
bash scripts/bootstrap-spark.sh
bash scripts/run-spark-baseline.sh
bash scripts/run-spark-static.sh
```

Optional local fork variables belong in an untracked `.env` file or shell session. Never paste credentials into Markdown, logs, Git, or Codex prompts.

```bash
export ETH_RPC_URL='https://your-read-only-rpc-endpoint'
export SPARK_FORK_BLOCK='<documented block number>'
```

The bootstrap script records immutable source pins. The baseline script uses repository-native build and test commands where discoverable. It will not run deployment scripts, broadcast transactions, or modify source checkouts. The static runner only analyzes repositories that expose a Foundry configuration; it records skipped repositories for manual setup rather than guessing a toolchain.

After the baseline, document exact deployment addresses and a fork block in `SCOPE.md`, then add focused local tests in the appropriate isolated review worktree. Do not characterize a scanner result as a vulnerability until it passes every gate in `AUDIT_STATE.md`.
