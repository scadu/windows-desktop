# Update-System.ps1
# Script to update various system components

$ErrorActionPreference = "Stop"
$AppsDirectory = Join-Path $HOME "Apps"
$WslDistro = "Ubuntu-24.04"

function Write-Status {
    param([string]$Message, [string]$Level = "INFO")
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
}

function Assert-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Status "Restarting script with admin privileges..." "INFO"
        Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        exit
    }
}

function Update-WslDistro {
    Write-Status "Updating $WslDistro packages" "INFO"
    try {
        $output = wsl -d $WslDistro -u root -e bash -c "apt-get update -qq && apt-get upgrade --with-new-pkgs -yq" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Status "$WslDistro upgrade failed with exit code $LASTEXITCODE" "ERROR"
        }
        else {
            Write-Status "$WslDistro upgrade completed successfully" "INFO"
        }
    }
    catch {
        Write-Status "$WslDistro upgrade failed: $_" "ERROR"
    }
}

function Update-WingetPackages {
    Write-Status "Updating winget packages" "INFO"
    try {
        $output = winget upgrade --all --accept-source-agreements --silent | Out-String
        $upgradeCount = ($output | Select-String "Successfully installed" -AllMatches).Matches.Count
        Write-Status "Winget upgraded $upgradeCount package(s)" "INFO"
    }
    catch {
        Write-Status "Error updating winget packages: $_" "ERROR"
    }
}

function Update-PatchMyPC {
    if (-not (Test-Path -Path $AppsDirectory)) {
        New-Item $AppsDirectory -ItemType Directory | Out-Null
    }

    $PatchMyPCPath = Join-Path $AppsDirectory "PatchMyPC.exe"
    $PatchMyPCBinary = "https://patchmypc.com/freeupdater/PatchMyPC.exe"

    if (-not(Test-Path $PatchMyPCPath -PathType Leaf)) {
        Write-Status "PatchMyPC not found. Downloading..." "WARN"
        try {
            Invoke-WebRequest $PatchMyPCBinary -OutFile $PatchMyPCPath
        }
        catch {
            Write-Status "Failed to download PatchMyPC: $_" "ERROR"
            return
        }
    }

    Write-Status "Updating programs with PatchMyPC" "INFO"
    try {
        $patchMyPCProcess = Start-Process -FilePath $PatchMyPCPath -ArgumentList "/auto" -PassThru -Wait -WindowStyle Hidden
        if ($patchMyPCProcess.ExitCode -ne 0) {
            Write-Status "PatchMyPC process exited with code $($patchMyPCProcess.ExitCode)" "WARN"
        }
        else {
            Write-Status "PatchMyPC updates completed" "INFO"
        }
    }
    catch {
        Write-Status "Error in PatchMyPC update: $_" "ERROR"
    }
}

function Update-Windows {
    Write-Status "Looking for Windows updates" "INFO"
    $WindowsUpdateModule = "PSWindowsUpdate"
    if (-not(Get-Module -ListAvailable -Name $WindowsUpdateModule)) {
        try {
            Install-Module -Name $WindowsUpdateModule -Confirm:$False -Force -Scope CurrentUser
        }
        catch {
            Write-Status "Failed to install PSWindowsUpdate module: $_" "ERROR"
            return
        }
    }

    try {
        Import-Module $WindowsUpdateModule
        $updates = Get-WindowsUpdate -Category 'Security Updates', 'Critical Updates' -AcceptAll -Install -IgnoreReboot | Out-String
        $updateCount = ($updates | Select-String "Installed" -AllMatches).Matches.Count
        Write-Status "Installed $updateCount Windows update(s)" "INFO"
        if ($updates -match "Reboot is required") {
            Write-Status "A system reboot is required to complete Windows updates" "WARN"
        }
    }
    catch {
        Write-Status "Error during Windows update: $_" "ERROR"
    }
}

# Main execution
try {
    Assert-AdminPrivileges

    Write-Progress -Activity "System Update" -Status "Updating Winget Packages" -PercentComplete 0
    Update-WingetPackages

    Write-Progress -Activity "System Update" -Status "Updating with PatchMyPC" -PercentComplete 25
    Update-PatchMyPC

    Write-Progress -Activity "System Update" -Status "Updating WSL Distro" -PercentComplete 50
    Update-WslDistro

    Write-Progress -Activity "System Update" -Status "Updating Windows" -PercentComplete 75
    Update-Windows

    Write-Progress -Activity "System Update" -Completed
    Write-Status "System update completed successfully" "INFO"
}
catch {
    Write-Status "An error occurred during system update: $_" "ERROR"
}