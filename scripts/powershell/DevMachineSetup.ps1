# Moved from gist: https://gist.github.com/scadu/ca3f0d4ee8ed148df9b182c44396a7fd

$mypath = $MyInvocation.MyCommand.Path
Write-Output "Path of the script : $mypath"
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Restarting as Admin
# Based on https://github.com/crutkas/buildScripts/blob/dcc8312814137d7acc1f893289e846e6a9b3ef76/WSL_Setup.ps1
if (!$isAdmin) {
	Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -NoExit -Command `"cd '$pwd'; & '$mypath' $Args;`"";
	exit;
}

# Install WinGet
# Based on this gist: https://gist.github.com/crutkas/6c2096eae387e544bd05cde246f23901
$hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"

if (!$hasPackageManager) {
    $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $releases = Invoke-RestMethod -uri "$($releases_url)"
    $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith("msixbundle") } | Select-Object -First 1

    Add-AppxPackage -Path $latestRelease.browser_download_url
}

else {
    "WinGet already installed"
}

#Configure WinGet
Write-Output "Configuring WinGet"

#winget config path from: https://github.com/microsoft/winget-cli/blob/master/doc/Settings.md#file-location
$settingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\settings.json";
$settingsJson = 
@"
    {
        // For documentation on these settings, see: https://aka.ms/winget-settings
        "interactivity": {
            "disable": true
        }
    }
"@;
$settingsJson | Out-File $settingsPath -Encoding utf8

#Install New apps
Write-Output "Installing Apps"
winget import --disable-interactivity --no-upgrade --accept-source-agreements --accept-package-agreements -i scripts/powershell/DevMachine_winget.json

# Remove Apps
Write-Output "Removing Apps"

$apps = "*3DPrint*", "Microsoft.MixedReality.Portal"
foreach ($app in $apps) {
    try {
        Write-Host "Uninstalling $($app)"
        Get-AppxPackage -AllUsers $app | Remove-AppxPackage | Out-Null
    }
    catch {
        Write-Output "Error uninstalling $($app): $_"
    }
}

# Install WSL
# https://learn.microsoft.com/en-us/windows/wsl/install
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -OutVariable WSLStatus | Out-Null
if ($WSLStatus.State -ne "Enabled") {
    wsl --install
} 
else {
    Write-Host "WSL already installed. Skipping..."
}

# Enable long paths
try {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
        -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
}
catch {
    Write-Output "Error enabling long paths: $_"
}
