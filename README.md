# Cortana installer

Install or upgrade Cortana Work Assistant on Windows from PowerShell:

```powershell
irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex
```

The bootstrap installer:

- installs Visual Studio Code and GitHub CLI with WinGet when missing;
- opens GitHub browser sign-in when authentication is required;
- downloads the latest Cortana VSIX from `gim-home/vswork-dist`;
- verifies the VSIX against the SHA-256 digest in the GitHub release;
- installs or upgrades the Cortana VS Code extension.

The signed-in GitHub account must have access to `gim-home/vswork-dist`. No credentials or tokens are stored in this repository.
