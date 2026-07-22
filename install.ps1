# Cortana Work Assistant bootstrap installer for Windows.
#
# Purpose:
#   Installs or upgrades the Cortana Visual Studio Code extension (.vsix) from an
#   internal GitHub release. It does not modify system settings, install services,
#   touch the registry, or access user data beyond GitHub authentication.
#
# Security scope:
#   Reads   - GitHub release metadata and the release .vsix asset.
#   Writes  - the VS Code extensions directory only.
#   Network - github.com only (WinGet installs VS Code / GitHub CLI only if missing).
#   Verify  - the .vsix is checked against the SHA-256 digest in the GitHub release.
#   Privs   - no elevation required.
#
# Usage:
#   irm https://raw.githubusercontent.com/daizw/cortana-install/main/install.ps1 | iex

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$distributionRepository = 'gim-home/vswork-dist'
$extensionId = 'microsoft-cortana.cortana-work-assistant'
$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) (
    'cortana-install-' + [Guid]::NewGuid().ToString('N')
)

function Write-Step {
    param([string]$Message)
    Write-Host "`n==> $Message" -ForegroundColor Cyan
}

function Refresh-ProcessPath {
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = @($machinePath, $userPath) -join ';'
}

function Find-Executable {
    param(
        [string]$CommandName,
        [string[]]$CandidatePaths
    )

    $command = Get-Command $CommandName -ErrorAction SilentlyContinue
    if ($command) {
        return $command.Source
    }

    foreach ($candidate in $CandidatePaths) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) {
            return $candidate
        }
    }

    return $null
}

function Invoke-Native {
    param(
        [string]$Executable,
        [string[]]$Arguments,
        [string]$FailureMessage
    )

    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$FailureMessage (exit code $LASTEXITCODE)."
    }
}

function Install-WinGetPackage {
    param(
        [string]$PackageId,
        [string]$DisplayName
    )

    $winget = Find-Executable 'winget.exe' @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe')
    )
    if (-not $winget) {
        throw "$DisplayName is required, and Windows Package Manager (winget) is unavailable. Install $DisplayName manually, then run this installer again."
    }

    Write-Step "Installing $DisplayName"
    Invoke-Native $winget @(
        'install', '--id', $PackageId, '--exact',
        '--accept-source-agreements', '--accept-package-agreements',
        '--disable-interactivity'
    ) "Failed to install $DisplayName"
    Refresh-ProcessPath
}

function ConvertTo-ComparableVersion {
    param(
        [string]$Value,
        [string]$Description
    )

    $normalized = $Value.Trim() -replace '^[vV]', ''
    $normalized = ($normalized -split '[-+]')[0]
    try {
        return [Version]$normalized
    }
    catch {
        throw "Cannot compare the $Description version '$Value'."
    }
}

if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    throw 'This installer currently supports Windows only.'
}

try {
    Write-Host 'Cortana Work Assistant installer' -ForegroundColor White

    $codeCandidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        (Join-Path $env:ProgramFiles 'Microsoft VS Code\bin\code.cmd'),
        $(if (${env:ProgramFiles(x86)}) {
            Join-Path ${env:ProgramFiles(x86)} 'Microsoft VS Code\bin\code.cmd'
        })
    )
    $code = Find-Executable 'code.cmd' $codeCandidates
    if (-not $code) {
        $code = Find-Executable 'code' $codeCandidates
    }
    if (-not $code) {
        Install-WinGetPackage 'Microsoft.VisualStudioCode' 'Visual Studio Code'
        $code = Find-Executable 'code.cmd' $codeCandidates
        if (-not $code) {
            $code = Find-Executable 'code' $codeCandidates
        }
    }
    if (-not $code) {
        throw 'Visual Studio Code was installed, but its command-line launcher could not be found. Restart PowerShell and run this installer again.'
    }
    Write-Host "    Visual Studio Code: $code" -ForegroundColor DarkGray

    $ghCandidates = @(
        (Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'),
        $(if (${env:ProgramFiles(x86)}) {
            Join-Path ${env:ProgramFiles(x86)} 'GitHub CLI\gh.exe'
        }),
        (Join-Path $env:LOCALAPPDATA 'Programs\GitHub CLI\gh.exe')
    )
    $gh = Find-Executable 'gh.exe' $ghCandidates
    if (-not $gh) {
        $gh = Find-Executable 'gh' $ghCandidates
    }
    if (-not $gh) {
        Install-WinGetPackage 'GitHub.cli' 'GitHub CLI'
        $gh = Find-Executable 'gh.exe' $ghCandidates
        if (-not $gh) {
            $gh = Find-Executable 'gh' $ghCandidates
        }
    }
    if (-not $gh) {
        throw 'GitHub CLI was installed, but gh.exe could not be found. Restart PowerShell and run this installer again.'
    }
    Write-Host "    GitHub CLI: $gh" -ForegroundColor DarkGray

    & $gh auth status --hostname github.com *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Step 'Sign in to GitHub to access the internal Cortana release'
        Write-Host 'A browser window will open. Use an account with access to gim-home/vswork-dist.' -ForegroundColor Yellow
        Invoke-Native $gh @(
            'auth', 'login', '--hostname', 'github.com',
            '--git-protocol', 'https', '--web'
        ) 'GitHub sign-in failed'
    }

    Invoke-Native $gh @(
        'auth', 'status', '--hostname', 'github.com'
    ) 'GitHub authentication is unavailable'

    Write-Step 'Finding the latest Cortana release'
    $releaseJson = & $gh api "repos/$distributionRepository/releases/latest"
    if ($LASTEXITCODE -ne 0) {
        $account = (& $gh api user --jq '.login' 2>$null)
        $accountHint = if ($LASTEXITCODE -eq 0 -and $account) {
            "The active GitHub account is '$account'. "
        } else {
            ''
        }
        throw (
            "Cannot access $distributionRepository. $accountHint" +
            "Use an account with repository access. If another account is already configured, run 'gh auth switch --hostname github.com'; otherwise run 'gh auth login --hostname github.com --web'."
        )
    }
    $release = $releaseJson | ConvertFrom-Json
    $vsixAssets = @(
        $release.assets | Where-Object { $_.name -like 'cortana-agent-*.vsix' }
    )
    if ($vsixAssets.Count -ne 1) {
        throw "Expected exactly one cortana-agent-*.vsix asset in release $($release.tag_name), but found $($vsixAssets.Count)."
    }
    $asset = $vsixAssets[0]
    $latestVersion = ConvertTo-ComparableVersion $release.tag_name 'latest release'
    Write-Host "    Release: $($release.tag_name)" -ForegroundColor DarkGray
    Write-Host "    Package: $($asset.name)" -ForegroundColor DarkGray

    Write-Step 'Checking the installed Cortana version'
    $installedExtensionLines = @(& $code --list-extensions --show-versions)
    if ($LASTEXITCODE -ne 0) {
        throw 'VS Code failed to list installed extensions.'
    }
    $installedLine = $installedExtensionLines | Where-Object {
        $_ -match ('^' + [Regex]::Escape($extensionId) + '@(.+)$')
    } | Select-Object -First 1

    if ($installedLine) {
        $installedVersionText = $installedLine.Substring($extensionId.Length + 1)
        $installedVersion = ConvertTo-ComparableVersion $installedVersionText 'installed Cortana'
        Write-Host "    Installed: $installedVersionText" -ForegroundColor DarkGray

        if ($installedVersion -eq $latestVersion) {
            Write-Host "`nCortana $installedVersionText is already the latest version. Nothing to do." -ForegroundColor Green
            return
        }
        if ($installedVersion -gt $latestVersion) {
            Write-Host "`nCortana $installedVersionText is newer than the latest release $($release.tag_name). It was left unchanged." -ForegroundColor Yellow
            return
        }

        Write-Host "    Action: upgrade $installedVersionText -> $($release.tag_name)" -ForegroundColor DarkGray
    } else {
        Write-Host '    Installed: not found' -ForegroundColor DarkGray
        Write-Host "    Action: install $($release.tag_name)" -ForegroundColor DarkGray
    }

    New-Item -ItemType Directory -Path $temporaryDirectory -Force | Out-Null
    $vsixPath = Join-Path $temporaryDirectory $asset.name

    Write-Step 'Downloading Cortana'
    Invoke-Native $gh @(
        'release', 'download', $release.tag_name,
        '--repo', $distributionRepository,
        '--pattern', $asset.name,
        '--dir', $temporaryDirectory,
        '--clobber'
    ) 'Failed to download Cortana'

    if (-not (Test-Path -LiteralPath $vsixPath)) {
        throw "The download completed without producing $($asset.name)."
    }

    if ($asset.digest -and $asset.digest -match '^sha256:(?<hash>[0-9a-fA-F]{64})$') {
        Write-Step 'Verifying the downloaded package'
        $expectedHash = $Matches.hash.ToLowerInvariant()
        $actualHash = (Get-FileHash -LiteralPath $vsixPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actualHash -ne $expectedHash) {
            throw 'Cortana package verification failed: the SHA-256 digest does not match the GitHub release metadata.'
        }
        Write-Host "    SHA-256 verified: $actualHash" -ForegroundColor DarkGray
    } else {
        Write-Warning 'This GitHub release does not expose a SHA-256 digest; package hash verification was skipped.'
    }

    Write-Step 'Installing the Cortana VS Code extension'
    Invoke-Native $code @(
        '--install-extension', $vsixPath, '--force'
    ) 'VS Code failed to install Cortana'

    $installedExtensions = @(& $code --list-extensions --show-versions)
    $expectedInstalledLine = "${extensionId}@$latestVersion"
    if ($LASTEXITCODE -ne 0 -or $installedExtensions -notcontains $expectedInstalledLine) {
        throw "VS Code did not report $expectedInstalledLine as installed."
    }

    Write-Host "`nCortana installed successfully." -ForegroundColor Green
    Write-Host 'Open or reload Visual Studio Code, then select Cortana from the Activity Bar.' -ForegroundColor White
}
catch {
    Write-Host "`nCortana installation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'Fix the reported issue, then run the same install command again.' -ForegroundColor Yellow
    throw
}
finally {
    if (Test-Path -LiteralPath $temporaryDirectory) {
        Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
    }
}
