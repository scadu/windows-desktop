# TODO: Add comments
# TODO: Wrap up steps in functions
# TODO: Handle case when there's no VHD images found

$VHDImages = Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Filter ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue
# Fancy formatting, indeed. "{0:N2}" means two decimal places of zeros to show.
# https://hochwald.net/powershell-get-the-size-of-given-folder-in-human-readable-format/
Write-Output = "Found following VHDX images:"  $(VHDImages | Select-Object FullName, @{Name="GigaBytes";Expression={ "{0:N2}" -f ($_.Length / 1GB)}})

$WarningMessage = "Would you like to proceed? In order to optimize VHD images, it's required to stop WSL instances and Docker Desktop."
Write-Warning $WarningMessage -WarningAction Inquire

# 'com.docker.service' is running as SYSTEM and it's not required to stop that process to continue.
$DockerProcesses = Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service'

# Stop Docker processes if found any
if ($DockerProcesses ) {
    Stop-Process -InputObject $DockerProcesses
}

wsl --shutdown
$VHDImages | ForEach-Object -AsJob -Parallel { Optimize-VHD -Path $_.fullname -Mode full; Write-Output $_.fullname } |
Receive-Job -Wait -AutoRemoveJob