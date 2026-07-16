# Install or upgrade Cortana

These instructions are for any coding agent that can access the web and run Windows PowerShell. Follow them on Windows.

1. Open <https://github.com/gim-home/vswork-dist> in the user's default browser.
2. Ask the user to sign in with their corporate GitHub account and wait until they confirm the repository is accessible. This must happen before GitHub CLI authorization so it does not select a personal GitHub account.
3. Run the following command in Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex
```

4. Allow the installer to open browser-based GitHub CLI authorization when required. The authorized account must have access to `gim-home/vswork-dist`.
5. When the installer finishes, verify the installed extension and report its version:

```powershell
code --list-extensions --show-versions | Select-String '^microsoft-cortana\.cortana-work-assistant@'
```

The installer installs Cortana when missing, upgrades an older version, skips the current version, and does not downgrade a newer local build. If a command fails, report the exact failure and the action required from the user.
