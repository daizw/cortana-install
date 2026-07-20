# Install or upgrade Cortana

These instructions are for any coding agent that can access the web and run Windows PowerShell. Follow them on Windows.

1. Open <https://github.com/gim-home/vswork-dist> in the user's default browser.
2. Ask the user to sign in with their corporate GitHub account and wait until they confirm the repository is accessible. This must happen before GitHub CLI authorization so it does not select a personal GitHub account.
3. Run the following command in Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex
```

   If you are an agent invoking this from a non-PowerShell shell (for example a Bash tool) and the command fails with `Permission denied` or exit code 126, your sandbox is blocking the bare `powershell` launcher — not the installer. Call PowerShell by full path instead. Prefer PowerShell 7 if present:

```bash
"/c/Program Files/PowerShell/7/pwsh.exe" -Command "irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex"
```

   Fall back to Windows PowerShell by full path if `pwsh.exe` is unavailable:

```bash
"/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe" -Command "irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex"
```

4. Allow the installer to open browser-based GitHub CLI authorization when required. The authorized account must have access to `gim-home/vswork-dist`.

   A successful run ends with these two lines:

```text
Cortana installed successfully.
Open or reload Visual Studio Code, then select Cortana from the Activity Bar.
```

   Treat that as success. A `DeprecationWarning: url.parse()` (DEP0169) line printed by VS Code during install is harmless and does not indicate failure. Only report failure if the installer prints `Cortana installation failed:` or a non-zero exit code with no success line.
5. When the installer finishes, verify the installed extension and report its version:

```powershell
code --list-extensions --show-versions | Select-String '^microsoft-cortana\.cortana-work-assistant@'
```

6. Tell the user to reload Visual Studio Code, open Cortana chat, and send:

```text
Use $cortana-onboarding to finish setting up Cortana on this machine.
```

The onboarding skill completes model, identity, communication-style, guardrail, service, memory, PWA, and optional integration setup while preserving existing configuration. If `$cortana-onboarding` is unavailable after reload, the installed Cortana release does not contain the skill yet; report that the user must install a release that includes it.

The installer installs Cortana when missing, upgrades an older version (existing configuration is preserved), skips the current version, and does not downgrade a newer local build. If a command fails, report the exact failure and the action required from the user.
