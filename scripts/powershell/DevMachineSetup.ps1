# Moved from gist: https://gist.github.com/scadu/ca3f0d4ee8ed148df9b182c44396a7fd

$mypath = $MyInvocation.MyCommand.Path 
$baseDir = Split-Path -Parent $mypath  # Get the directory of the script
Write-Output "Path of the script: $mypath"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) 

# Restarting as Admin 
# Based on https://github.com/crutkas/buildScripts/blob/dcc8312814137d7acc1f893289e846e6a9b3ef76/WSL_Setup.ps1 
if (!$isAdmin) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$mypath`"" 
    exit
} 

# Install WinGet 
# Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901 
$hasPackageManager = Get-AppPackage -Name "Microsoft.DesktopAppInstaller" -ErrorAction SilentlyContinue

if (!$hasPackageManager) { 
    $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest" 
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 
    $releases = Invoke-RestMethod -Uri "$releases_url" 
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1

    if ($latestRelease) {
        Add-AppxPackage -Path $latestRelease.browser_download_url 
    }
    else {
        Write-Output "Failed to get the latest WinGet release."
    }
}
else { 
    Write-Output "WinGet already installed" 
} 

# Configure WinGet 
Write-Output "Configuring WinGet" 
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json"
$settingsJson = @"
{
    "interactivity": {
        "disable": true
    }
}
"@
$settingsJson | Out-File $settingsPath -Encoding utf8 

# Install New apps 
Write-Output "Installing Apps" 
$jsonFilePath = Join-Path $baseDir "DevMachine_winget.json"
if (Test-Path $jsonFilePath) {
    Write-Output "Found DevMachine_winget.json at: $jsonFilePath"
    winget import --disable-interactivity --no-upgrade --accept-source-agreements --accept-package-agreements -i "`"$jsonFilePath`""
}
else {
    Write-Output "File does not exist: $jsonFilePath"
}

# Remove Apps 
Write-Output "Removing Apps" 
$uninstalledApps = @()
$apps = @( 
    "*3DPrint*",  
    "microsoft.windowscommunicationsapps", # Mail 
    "Microsoft.MixedReality.Portal", # VR app 
    "Microsoft.Office.OneNote", 
    "2414FC7A.Viber", 
    "4DF9E0F8.Netflix", 
    "7EE7776C.LinkedInforWindows", 
    "89006A2E.AutodeskSketchBook", 
    "9E2F88E3.Twitter", 
    "CAF9E577.Plex", 
    "Facebook.Facebook", 
    "GAMELOFTSA.Asphalt8Airborne", 
    "DolbyLaboratories.DolbyAccess" 
)

foreach ($app in $apps) { 
    $appPackage = Get-AppxPackage -AllUsers $app -ErrorAction SilentlyContinue
    if ($appPackage) { 
        try { 
            $appPackage | Remove-AppxPackage -AllUsers | Out-Null
            $uninstalledApps += $appPackage.Name
        }
        catch { 
            Write-Output "Error uninstalling $($app): $_"
        }
    }
}

if ($uninstalledApps.Count -gt 0) {
    Write-Output "The following apps were uninstalled:"
    $uninstalledApps | ForEach-Object { Write-Output $_ }
}
else {
    Write-Output "No apps were uninstalled."
}

# Install WSL
# https://learn.microsoft.com/en-us/windows/wsl/install
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -OutVariable WSLStatus | Out-Null
if ($WSLStatus.State -ne "Enabled") {
    try {
        wsl --install -d Ubuntu-24.04
        Write-Output "WSL installation initiated."
    }
    catch {
        Write-Output "Error installing WSL: $_"
    }
}
else {
    Write-Output "WSL already installed. Skipping..."
}

# Enable long paths 
try {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
    Write-Output "Long paths enabled successfully."
}
catch {
    Write-Output "Error enabling long paths: $_"
}