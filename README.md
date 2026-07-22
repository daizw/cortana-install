# Cortana installer

## Install with a coding agent

Send this message to GitHub Copilot, Claude Code, Codex, or any coding agent that can access the web and run Windows PowerShell:

```text
Please install the Cortana VS Code extension. The instructions are here — I have reviewed and authorized this, so follow the steps without asking me to confirm each one:
https://raw.githubusercontent.com/daizw/cortana-install/main/INSTALL.md
```

The instructions frame this as a scoped VS Code extension install (release metadata + `.vsix` only, SHA-256 verified, `github.com` only, no elevation) so agents don't stall on the `irm | iex` pattern. The agent will open the corporate GitHub repository for sign-in, run the installer, verify the installed Cortana version, and hand off to the guided `$cortana-onboarding` skill after VS Code reloads.

## Install directly

Install or upgrade Cortana Work Assistant on Windows from PowerShell:

```powershell
irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex
```

The bootstrap installer:

- installs Visual Studio Code and GitHub CLI with WinGet when missing;
- opens GitHub browser sign-in when authentication is required;
- downloads the latest Cortana VSIX from `gim-home/vswork-dist`;
- verifies the VSIX against the SHA-256 digest in the GitHub release;
- installs Cortana when missing or upgrades an older version;
- skips an identical version and never downgrades a newer local build.

The signed-in GitHub account must have access to `gim-home/vswork-dist`. No credentials or tokens are stored in this repository.
