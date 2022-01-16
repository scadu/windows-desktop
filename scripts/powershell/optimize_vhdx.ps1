# https://www.blogabout.cloud/2020/05/1460/
wsl --shutdown
Get-Process *docker* | Stop-Process
Get-ChildItem -Path $HOME\AppData\Local -Include ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue | ForEach-Object { Optimize-VHD -Path $_.fullname -Mode full }