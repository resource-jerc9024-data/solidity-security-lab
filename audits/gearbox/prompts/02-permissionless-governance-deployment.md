# Gearbox V3.1 independent review: permissionless deployment and governance

Review only the supplied pinned Gearbox source. Start fresh and do not import claims
from TermMax or any other project.

Focus on bytecode registration and auditor attestations, CREATE2 deployments,
factories, instance/market configuration, nested price-feed configuration, ACL and
governor boundaries, timelocks, cross-chain multisig behavior, role transitions,
emergency actions, version compatibility, and malicious permissionless curators.
Separate the intended authority of a curator/governor from any unprivileged path that
expands that authority or harms users despite protocol guardrails.

For every concrete hypothesis, give exact locations, attacker control, prerequisites,
transaction sequence, violated invariant, full impact, severity mapping, and local
PoC design. Reject claims that merely assume a privileged key or bad configuration.
If no credible path exists, say so.
