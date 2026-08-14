You are performing an authorized, read-only security review of the TermMax V2
Solidity repository at commit e314f3f849577dfecd4614f148c4df81fdf8c72d.

Review production contracts only. Focus deeply on Market, Order, Vault,
ERC4626 wrappers, GearingToken, debt, collateral, liquidation, mint/burn/redeem,
maturity, fee, share-price, rounding, queue, bad-debt, and interest accounting.

Immunefi contract impacts in scope are direct theft of user funds, permanent
freezing, protocol insolvency, theft/permanent freezing of unclaimed yield, and
temporary freezing. Privileged-only behavior, centralization risk, best
practice, test/config-only defects, and impact requiring live-chain testing are
not findings.

Trace concrete attacker-controlled call sequences and conservation equations.
For every plausible candidate report exact file/function locations, root cause,
attacker prerequisites, transaction sequence, violated invariant, end impact,
strongest disconfirming evidence, and a minimal local Foundry PoC plan. Reject
signals that lack reachability or a listed end impact. Do not modify files. Do
not call anything confirmed without a working PoC; label output Candidate or
Rejected. If no credible candidate survives, say so explicitly.
