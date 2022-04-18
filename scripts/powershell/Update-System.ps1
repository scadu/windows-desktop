$ErrorActionPreference = "Stop"
$BinariesDirectory = "$HOME\bin"
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

function Get-ScoopUpdate {
    try {
        Write-Output "Updating scoop packages"
        Start-Process -RunAsUser { scoop update * }
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        Write-Output "Scoop not found. Skipping"
    }
}

function Get-ProgramsUpdate {
    $PatchMyPCBinary = "https://patchmypc.com/freeupdater/PatchMyPC.exe"
    if (-not(Test-Path $BinariesDirectory\PatchMyPC.exe -PathType Leaf)) {
        Write-Warning "PatchMyPC not found. Downloading..."
        Invoke-WebRequest $PatchMyPCBinary -OutFile "$BinariesDirectory\PatchMyPC.exe"
    }
    try {
        Write-Output "Updating programs with PatchMyPC"
        Start-Process -FilePath "$BinariesDirectory\PatchMyPC.exe" -ArgumentList "/auto"
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
    }
}

function Get-WindowsUpdate {
    Write-Output "Looking for Windows updates"
    $WindowsUpdateModule = "PSWindowsUpdate"
    if (-not(Get-Module -ListAvailable -Name $WindowsUpdateModule)) {
        Install-Module -Name $WindowsUpdateModule -Confirm:$False -Force -Scope CurrentUser
    }
    try {
        # TODO: Check if it could be run with `-RunAs`
        sudo Get-WindowsUpdate -Category 'Security Updates', 'Critical Updates' -Verbose -AcceptAll
    }
    catch {
        Write-Error "Error: $($_.Exception.Message)"
    }
}

Get-ProgramsUpdate
Get-WslUpdate
Get-ScoopUpdate
Get-WindowsUpdate
