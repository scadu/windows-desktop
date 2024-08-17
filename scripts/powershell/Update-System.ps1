$ErrorActionPreference = "Stop"
$AppsDirectory = "$HOME\Apps\"
$WslDistro = "Ubuntu-24.04"

# Based on https://github.com/crutkas/buildScripts/blob/dcc8312814137d7acc1f893289e846e6a9b3ef76/WSL_Setup.ps1#L13-L23
$mypath = $MyInvocation.MyCommand.Path
Write-Output "Path of the script : $mypath"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Restarting as Admin
if (!$isAdmin) {
	Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"cd '$pwd'; & '$mypath' $Args;`"";
	exit;
}


function Get-WslUpdate {
    Write-Output "Updating $WslDistro packages"
    wsl -d $WslDistro -u root -e apt-get update -qq
    wsl -d $WslDistro -u root -e apt-get upgrade --with-new-pkgs -yq
    # Check if it exited with a non-zero status
    if (!$?) {
        Write-Error "$WslDistro upgrade failed"
    }
}

function Get-ProgramsUpdate {
    Write-Output "Updating winget packages"
    # Using Start-Process to control the execution flow with -Wait 
    # to ensure PatchMyPC won't start until winget finishes
    Start-Process -FilePath "winget" -ArgumentList "upgrade --all" -NoNewWindow -Wait

    if (-not (Test-Path -Path $AppsDirectory)) {
        New-Item $AppsDirectory -ItemType Directory | Out-Null
    }

    $PatchMyPCBinary = "https://patchmypc.com/freeupdater/PatchMyPC.exe"
    if (-not(Test-Path $AppsDirectory\PatchMyPC.exe -PathType Leaf)) {
        Write-Warning "PatchMyPC not found. Downloading..."
        Invoke-WebRequest $PatchMyPCBinary -OutFile "$AppsDirectory\PatchMyPC.exe"
    }

    try {
        Write-Output "Updating programs with PatchMyPC"
        Start-Process -FilePath "$AppsDirectory\PatchMyPC.exe" -ArgumentList "/auto" -Wait
    }
    catch {
        Write-Error "Error in PatchMyPC update: $($_.Exception.Message)"
    }
}

function Get-WinUpdate {
    Write-Output "Looking for Windows updates"
    $WindowsUpdateModule = "PSWindowsUpdate"
    if (-not(Get-Module -ListAvailable -Name $WindowsUpdateModule)) {
        Install-Module -Name $WindowsUpdateModule -Confirm:$False -Force -Scope CurrentUser
    }
    try {
        # TODO: Check if it could be run with `-RunAs`
        Get-WindowsUpdate -Category 'Security Updates', 'Critical Updates' -Verbose -AcceptAll
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
    }
}

Get-ProgramsUpdate
Get-WslUpdate
# Get-WinUpdate
