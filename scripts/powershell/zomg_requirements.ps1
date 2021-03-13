# https://github.com/microsoft/Requirements

if (-not(Get-Module -ListAvailable -Name Requirements)) {
    Write-Output "Module Requirements not found. Installing..."
    Install-Module -Name Requirements -Confirm:$False -Force -Scope CurrentUser
}

$ErrorActionPreference = "Stop"
Import-Module Requirements



$Requirements = @(
    @{
        Describe = "WSL is enabled"
        Test     = { (Get-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' | Select-Object -ExpandProperty State) -eq "Enabled" }
        Set      = {
            Enable-WindowsOptionalFeature -Online -FeatureName 'Microsoft-Windows-Subsystem-Linux' -All -NoRestart | Out-Null
        }
    },
    @{
        Describe = "Virtual Machine Platform is enabled"
        Test     = { (Get-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' | Select-Object -ExpandProperty State) -eq "Enabled" }
        Set      = {
            Enable-WindowsOptionalFeature -Online -FeatureName 'VirtualMachinePlatform' -All -NoRestart | Out-Null
        }
    }
)

$Requirements | Invoke-Requirement | Format-Checklist