# DevMachineSetup.ps1
# Script to set up a new Windows development machine

$ErrorActionPreference = 'Stop'

function Write-Status {
    param([string]$Message, [string]$Level = "INFO")
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
}

function Install-WinGetIfNeeded {
    if (Get-Command winget -ErrorAction SilentlyContinue) { return }
    
    Write-Status "Installing WinGet..." "INFO"
    $releases = Invoke-RestMethod "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    $downloadUrl = $releases.assets | Where-Object { $_.browser_download_url -like "*msixbundle" } | Select-Object -ExpandProperty browser_download_url -First 1
    
    if (-not $downloadUrl) {
        throw "Failed to get the latest WinGet release."
    }

    $installerPath = Join-Path $env:TEMP "WinGetInstaller.msixbundle"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath
    Add-AppxPackage -Path $installerPath
    Remove-Item -Path $installerPath -Force
    Write-Status "WinGet installed successfully." "INFO"
}

function Install-Packages {
    param([array]$Packages)
    $result = @{Installed = 0; AlreadyInstalled = 0; Errors = 0 }
    $totalPackages = $Packages.Count

    for ($i = 0; $i -lt $totalPackages; $i++) {
        $package = $Packages[$i]
        $packageId = $package -is [string] ? $package : $package.id
        $override = $package -is [string] ? $null : $package.override

        $percentComplete = ($i / $totalPackages) * 100
        Write-Progress -Activity "Installing Packages" -Status "Processing $packageId" -PercentComplete $percentComplete

        $wingetArgs = @(
            "install"
            "--id", $packageId
            "--exact"
            "--no-upgrade"
            "--accept-source-agreements"
            "--accept-package-agreements"
        )
        if ($override) { $wingetArgs += "--override", $override }

        try {
            $output = & winget $wingetArgs 2>&1
            $outputString = $output | Out-String

            if ($outputString -match "Successfully installed") {
                $result.Installed++
                Write-Status "Successfully installed $packageId" "INFO"
            } 
            elseif ($outputString -match "Installation cancelled") {
                $result.AlreadyInstalled++
                Write-Status "Package $packageId is already installed" "INFO"
            }
            elseif ($outputString -match "no package found matching") {
                $result.Errors++
                Write-Status "Package $packageId not found" "ERROR"
            }
            else {
                $result.Errors++
                Write-Status "Unexpected output for $packageId. See below for details." "WARN"
                Write-Status $outputString "DEBUG"
            }
        }
        catch {
            $result.Errors++
            Write-Status "Error processing $packageId`: $_" "ERROR"
        }
    }
    Write-Progress -Activity "Installing Packages" -Completed
    return $result
}

function Remove-UnnecessaryApps {
    param([array]$AppList)
    $uninstalledApps = @()

    foreach ($app in $AppList) {
        Get-AppxPackage -AllUsers $app -ErrorAction SilentlyContinue | ForEach-Object {
            try {
                Remove-AppxPackage -Package $_ -AllUsers
                $uninstalledApps += $_.Name
                Write-Status "Uninstalled app: $($_.Name)" "INFO"
            }
            catch {
                Write-Status "Error uninstalling $($_.Name): $_" "ERROR"
            }
        }
    }
    return $uninstalledApps
}

try {
    # Check for admin privileges
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Status "Restarting script with admin privileges..." "INFO"
        Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }

    Install-WinGetIfNeeded

    $packagesToInstall = @(
        "7zip.7zip"
        "Docker.DockerDesktop"
        "Git.Git"
        "REALiX.HWiNFO"
        "Mozilla.Firefox"
        "AntibodySoftware.WizTree"
        "AgileBits.1Password"
        "GitHub.cli"
        "Google.Chrome"
        "Starship.Starship"
        "CodeSector.TeraCopy"
        "Valve.Steam"
        "Microsoft.PowerToys"
        "AutoHotkey.AutoHotkey"
        "BurntSushi.ripgrep.MSVC"
        "TIDALMusicAS.TIDAL"
        "ajeetdsouza.zoxide"
        "junegunn.fzf"
        @{
            id       = "Microsoft.VisualStudio.2022.BuildTools"
            override = "--add Microsoft.VisualStudio.Workload.NativeDesktop --includeRecommended --passive"
        }
    )

    $packageResult = Install-Packages -Packages $packagesToInstall

    $appsToRemove = @(
        "*3DPrint*"
        "microsoft.windowscommunicationsapps"
        "Microsoft.MixedReality.Portal"
        "Microsoft.Office.OneNote"
        "2414FC7A.Viber"
        "4DF9E0F8.Netflix"
        "7EE7776C.LinkedInforWindows"
        "89006A2E.AutodeskSketchBook"
        "9E2F88E3.Twitter"
        "CAF9E577.Plex"
        "Facebook.Facebook"
        "GAMELOFTSA.Asphalt8Airborne"
        "DolbyLaboratories.DolbyAccess"
    )

    $uninstalledApps = Remove-UnnecessaryApps -AppList $appsToRemove

    # Install WSL
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
        Write-Status "Installing WSL..." "INFO"
        wsl --install -d Ubuntu-24.04
        $wslInstalled = $true
    }
    else {
        $wslInstalled = $false
        Write-Status "WSL is already installed" "INFO"
    }

    # Enable long paths
    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            -Name "LongPathsEnabled" -Value 1 -Type DWord -Force
        $longPathsEnabled = $true
        Write-Status "Long paths enabled successfully" "INFO"
    }
    catch {
        $longPathsEnabled = $false
        Write-Status "Error enabling long paths: $_" "ERROR"
    }

    # Final summary
    Write-Status "`nScript execution completed." "INFO"
    Write-Status "Summary:" "INFO"
    Write-Status "- Packages: $($packageResult.Installed) newly installed, $($packageResult.AlreadyInstalled) already installed, $($packageResult.Errors) errors" "INFO"
    Write-Status "- Uninstalled apps: $(if ($uninstalledApps.Count -gt 0) { $uninstalledApps -join ', ' } else { 'None' })" "INFO"
    Write-Status "- WSL: $(if ($wslInstalled) { 'Installation initiated' } else { 'Already installed' })" "INFO"
    Write-Status "- Long paths: $(if ($longPathsEnabled) { 'Enabled' } else { 'Failed to enable' })" "INFO"
}
catch {
    Write-Status "An error occurred during script execution: $_" "ERROR"
}