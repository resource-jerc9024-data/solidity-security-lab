# TermMax V2 independent Codex-pass triage

Four pass-specific reviews completed successfully. Their full final reports and
execution status are retained in `runs/current/codex/`. These reports are
hypothesis generators; the dispositions below come from separate manual source,
test, deployment, and known-issue checks.

| Pass | Review lane | Main output | Manual disposition |
|---|---|---|---|
| 01 | Accounting and liquidation | No credible candidate; noted zero-debt token cleanup and external-pool assumptions. | No listed impact or unprivileged trigger. |
| 02 | Callbacks, adapters, and oracles | Global router balance sweep; caller-selected adapter targets; zero-price and token-behavior cautions. | Sweep reproduced as `DUP-001`; other items have no independent cross-user path or need privileged/bad external data. |
| 03 | Access, upgrades, and state | Suggested `afterSwap`, proxy initialization, and CREATE2 deployment hypotheses. | Rejected after preserved-caller authentication and atomic deployment-script checks. |
| 04 | Adversarial synthesis | Prioritized the router sweep and found no second PoC-ready issue; noted broad delegation. | Router issue is an exact public duplicate; delegation adds no authority beyond the documented broad grant. |

## Verification highlights

- `OrderManagerV2.afterSwap` requires the preserved external caller to exist in
  `_orderMaturityMapping`; unrelated callers revert before mutation.
- Router, Viewer, and AccessManager deployment paths pass initialization data
  into `ERC1967Proxy` atomically. Router upgrade initialization is included in
  the authorized upgrade call.
- Caller-selected adapter targets can act on the initiating user's funds. A
  cross-user loss requires a pre-existing router balance and therefore reduces
  to the global-balance condition already covered by `DUP-001`.
- The zero-answer oracle condition has no demonstrated unprivileged trigger in
  the reviewed source; bad third-party data and privileged misconfiguration are
  not treated as a source-only bounty proof.

The Codespace kernel blocks Bubblewrap namespace creation. The pass runner kept
read-only sandbox mode, embedded only the relevant public Solidity source in
each prompt, and explicitly prohibited shell, filesystem, tool, and network
calls. Unsafe unrestricted Codex execution was not used.
