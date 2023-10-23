$ErrorActionPreference = "Stop"
$AppsDirectory = "$HOME\Apps\"
$WslDistro = "Ubuntu"

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
        Start-Process -FilePath "$AppsDirectory\PatchMyPC.exe" -ArgumentList "/auto"
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
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
Get-WinUpdate
