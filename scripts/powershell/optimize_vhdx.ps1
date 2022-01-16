# https://www.blogabout.cloud/2020/05/1460/
wsl --shutdown
# 'com.docker.service' is running as SYSTEM and it's not required to stop that process to proceed.
$DockerProcesses = Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service'
# Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service' | Stop-Process
Stop-Process -InputObject $DockerProcesses
# Get-Process | Where-Object { $_.HasExited }
# Get-ChildItem -Path $env:LOCALAPPDATA -Include ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object -Parallel { Optimize-VHD -Path $_.fullname -Mode full }