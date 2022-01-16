# 'com.docker.service' is running as SYSTEM and it's not required to stop that process to continue.
$DockerProcesses = Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service'

# Stop Docker processes if found any
if ($DockerProcesses ) {
    Stop-Process -InputObject $DockerProcesses
}

wsl --shutdown
Get-ChildItem -Path $env:LOCALAPPDATA -Include ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue |
ForEach-Object -Parallel { Write-Output $_.fullname; Optimize-VHD -Path $_.fullname -Mode full }