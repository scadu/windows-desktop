function Stop-DockerAndWSL {
    # 'com.docker.service' is running as SYSTEM and it's not required to stop that process to continue.
    $DockerProcesses = Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service'
    $WarningMessage = "Would you like to proceed? In order to optimize VHD images, it's required to stop WSL instances and Docker Desktop."
    Write-Warning $WarningMessage -WarningAction Inquire
    # Stop Docker processes if found any
    if ($DockerProcesses ) {
        Stop-Process -InputObject $DockerProcesses
    }
    &wsl --shutdown
}

function Get-VHDXImages {
    $VHDXImages = Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Filter ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue
    if ($VHDXImages) {
        Write-Output "Found following VHDX images:"  $VHDXImages
    }
    else {
        Write-Output "No VHDX images found."
        break
    }
}
function Optimize-VHDXImages {
    $VHDXImages = Get-VHDXImages
    Stop-DockerAndWSL
    if ($VHDXImages) {
        Optimize-VHD -AsJob -Path $VHDXImages.fullname -Mode full | Receive-Job -Wait -AutoRemoveJob
    }
}


Optimize-VHDXImages