# TermMax V2 review summary

## Outcome

- Pinned public source: `e314f3f849577dfecd4614f148c4df81fdf8c72d`.
- Production contract build: passed with Solidity `0.8.27`.
- Non-fork V2 test shards: 36 files and 626 test cases executed; 603 passed and
  23 failed across 3 files for the two classified baseline causes below.
- Reproduction PoC: 1 passed, 0 failed.
- Slither: 940 raw signals manually grouped and triaged; no new listed impact.
- Independent Codex passes: 4 completed; suggestions were manually verified.
- Final bounty result: no reward-eligible finding. One technically Critical-
  class theft path is reproducible but is an exact public duplicate.

The run used local source and local EVM tests only. It sent no mainnet or public-
testnet transaction and generated no automated traffic against TermMax or any
third-party service.

## Classified baseline exceptions

### TEST-001: Vault tests conflict with the transaction-level guard

`VaultV2.t.sol` reports 32 passed and 6 failed; `VaultV2WithPool.t.sol` reports
14 passed and 6 failed. Each failure is
`ReentrantCallBetweenActions(ACTION_WITHDRAW, ACTION_DEPOSIT)`.

The affected tests perform deposit and withdraw/redeem activity within one
Foundry test transaction. `TransactionReentrancyGuard` intentionally records a
protected action with EIP-1153 transient storage and rejects a different action
before the transaction ends. Transient state clears between real transactions.
The repeated baseline fixtures are stale relative to that guard; they do not
demonstrate a listed production impact.

### TEST-002: Stable-wrapper invariant handler impersonates the vault

`StableERC4626For4626Invariant.t.sol` reports 1 passed and 11 failed, but every
failure originates in the handler's post-deposit balance assertion before the
named invariant is evaluated. The minimized sequence is one `deposit(0)` call,
bounded by the handler to one unit.

The full trace shows Foundry selecting the stable-vault proxy address as the
fuzz sender. The handler accepts it as an actor and calls `vm.startPrank`, which
impersonates the vault. The resulting token call is
`transferFrom(vault, vault, amount)`: a self-transfer correctly leaves the
underlying balance unchanged, contradicting the handler's assumption that it
must decrease. An external attacker cannot originate a transaction as the
vault. This is a harness actor-filter defect, not an attacker-reachable contract
failure. The trace is retained in
`runs/current/test-shards/stable4626-rerun-trace.log`.

## Evidence interpretation

Passing tests and analyzers reduce uncertainty but do not prove absence of all
vulnerabilities. A finding enters `FINDINGS.md` only when an unprivileged,
current-scope attack produces the complete listed impact locally and survives
the known-issue check. `CANDIDATES.md` preserves both the exact duplicate and
the rejected hypotheses so future passes do not repeat the same false leads.
