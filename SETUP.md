# Solidity audit environment setup

## Recommended online option: GitHub Codespaces

This repository includes `.devcontainer/devcontainer.json`. After publishing it
to a **private GitHub repository**, choose **Code > Codespaces > Create codespace**.
The container automatically installs Foundry, Slither, and Codex.

When setup finishes, verify it with:

```bash
bash scripts/check-environment.sh
```

For Codex in a Codespace, run the remote-safe authentication command:

```bash
codex login --device-auth
```

Open the URL and enter the one-time code shown in the Codespace terminal, then sign
in with the ChatGPT account that owns your subscription. Do not use the default
browser callback here: it points at the Codespace's `localhost`, not your computer.
This setup does not use an OpenAI API key and does not require separate API billing.

The initial `.gitignore` deliberately excludes `audit/FINDINGS.md` and Solidity
PoCs under `test/security/`. Remove those exclusions only when you intentionally
want to store them in the private repository and the bounty rules permit it.

The Windows/WSL instructions below remain available as an offline alternative.

The machine already has VS Code, Git, and the Codex desktop app. WSL and Foundry
were not installed when this setup was generated.

## 1. Enable WSL2 and install Ubuntu

Open **PowerShell as Administrator**, change to this directory, and run:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\01-enable-wsl.ps1
```

Restart Windows if requested. Open **Ubuntu** from the Start menu once and create
your Linux username and password. No characters appear while entering the Linux
password; that is normal.

## 2. Install the Linux audit tools

In Ubuntu, run:

```bash
cp /mnt/c/Users/prati/OneDrive/Documents/ChatGPT/Contract-debug/02-setup-audit.sh /tmp/
chmod +x /tmp/02-setup-audit.sh
/tmp/02-setup-audit.sh
```

This installs Foundry and Slither and creates `~/code/audits`. It does not install
wallet keys or connect to a chain.

## 3. Open the Linux workspace in VS Code

Install Microsoft's **WSL** extension in VS Code, then run in Ubuntu:

```bash
cd ~/code/audits
code .
```

The lower-left corner of VS Code should say `WSL: Ubuntu`.

## 4. Add a target only when its official scope is known

```bash
cd ~/code/audits
git clone <official-repository-url> target
cd target
git switch -c audit/local
mkdir -p audit test/security
touch audit/SCOPE.md audit/ARCHITECTURE.md audit/INVARIANTS.md audit/FINDINGS.md
```

Record the exact in-scope commit and bounty rules in `audit/SCOPE.md` before any
scan. First reproduce the repository's clean baseline using its own README and
test commands. Install or run Codex Security only after confirming it is available
to the verified account/workspace; identity verification alone is not something a
local script can inspect or transfer.
