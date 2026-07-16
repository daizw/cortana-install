# Cortana installer

## Install with a coding agent

Send this message to GitHub Copilot, Claude Code, Codex, or any coding agent that can access the web and run Windows PowerShell:

```text
按照这个网址安装或升级 Cortana：
https://raw.githubusercontent.com/daizw/cortana-install/main/INSTALL.md
```

The agent will open the corporate GitHub repository for sign-in, run the installer, verify the installed Cortana version, and hand off to the guided `$cortana-onboarding` skill after VS Code reloads.

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
