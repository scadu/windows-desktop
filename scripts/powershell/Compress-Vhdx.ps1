# TODO: Add comments
# TODO: Wrap up steps in functions
# TODO: Handle case when there's no VHD images found

# function Stop-DockerAndWSL {
#     # 'com.docker.service' is running as SYSTEM and it's not required to stop that process to continue.
#     $DockerProcesses = Get-Process -Name *docker* | Where-Object ProcessName -NE 'com.docker.service'
#     $WarningMessage = "Would you like to proceed? In order to optimize VHD images, it's required to stop WSL instances and Docker Desktop."
#     Write-Warning $WarningMessage -WarningAction Inquire
#     # Stop Docker processes if found any
#     if ($DockerProcesses ) {
#         Stop-Process -InputObject $DockerProcesses
#     }
#     &wsl --shutdown
# }

function Get-VHDImages {
    $VHDImages = Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Filter ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue
    # Fancy formatting, indeed. "{0:N2}" means two decimal places of zeros to show.
    # https://hochwald.net/powershell-get-the-size-of-given-folder-in-human-readable-format/
    if ($VHDImages) {
        Write-Output "Found following VHDX images:"  $($VHDImages | Select-Object FullName, @{Name = "GigaBytes"; Expression = { "{0:N2}" -f ($_.Length / 1GB) } })
    }
    else {
        Write-Output "No VHD images found."
    }
}

# # https://4sysops.com/archives/compress-vhdx-compress-multiple-vhdx-files-using-the-powershell-cmdlet-optimize-vhd/
# function Optimize-VHDImages {
#     $VHDImages = Get-VHDImages
#     Stop-DockerAndWSL
#     if ($VHDImages) {
#         $VHDImages | ForEach-Object -AsJob -Parallel { Optimize-VHD -Path $_.fullname -Mode full; Write-Output $_.fullname } |
#         Receive-Job -Wait -AutoRemoveJob
#     }
# }

function Compress-Vhdx {
    <#
    .Synopsis
       Compresses all the VHDX files from a specified location
    .DESCRIPTION
       Compress-Vhdx retrieves each VHDX files from a specified location and compacts each using the native command Optimize-VHD
    .EXAMPLE
       Compress-Vhdx -Path "C:\MyVMs" -Recurse
       Compacts all the VHDX files from the specified path, including subfolders
    .NOTES
       Last updated on 2021.11.05
    #>
    [CmdletBinding(SupportsShouldProcess)]
    
    # [CmdletBinding()]
    Param
    (
        # Path to the VHDX files
        [Parameter(ValueFromPipelineByPropertyName)]$Path = $env:LOCALAPPDATA,

        [Parameter(ValueFromPipelineByPropertyName)][int]$Depth = 3
    )
    
    Begin {
        $StartTime = Get-Date
     
        # Search for VHDX files in subfolders?
        # if ($IncludeSubfolders) {
        $AllVhdx = Get-ChildItem -LiteralPath $env:LOCALAPPDATA -Filter ext4.vhdx -File -Recurse -Depth 3 -ErrorAction SilentlyContinue
        # }
        # else {
        # $AllVhdx = Get-ChildItem ext4.vhdx -Path $Path -ErrorAction SilentlyContinue
        # }
    
        # Are there any VHDX files in the location?
        if ($AllVhdx.Count -lt 1) {
            Write-Output $AllVhdx.Count
            Write-Warning "There is no VHDX file to compress in `"$Path`". Make sure that the path is correct and it contains VHDX files"
            break
        }
        #Clear-Host
        Write-Verbose "Compacting $($AllVhdx.Count) VHDX files, please wait"
    } #Begin
        
    Process {
    
        $Stats = foreach ($v in $AllVhdx) {
                
            $OldSize = $v.Length
    
            try {
                if ($PSCmdlet.ShouldProcess(
                        ("Optimizing $v.FullName")
                    )) {                        
                    Optimize-VHD -Path $v.FullName -Mode Full -ErrorAction Stop -WhatIf:$WhatIfPreference
                }
                Write-Verbose "Compressing $($v.Name)"
                $NewSize = (Get-ChildItem -Path $v.FullName).Length                
                $Saved = $OldSize - $NewSize
                              
                [PSCustomObject] @{
                    #Name = $v.Name
                    Path                = $v.FullName
                    "Initial Size [GB]" = [math]::round($OldSize / 1Gb, 2)
                    "Current Size [GB]" = [math]::round($NewSize / 1Gb, 2)
                    "Saved [GB]"        = [math]::round($Saved / 1Gb, 2)
                }
            }
    
            catch {
                Write-Verbose "Skipping $($v.Name). File may be in use "
            }   
                
            $TotalSaved += $Saved  
    
        } #$Stats
    
    } #Process
    
    End {
        $Duration = New-TimeSpan -Start $StartTime -End (Get-Date)
        $DurationPretty = $($Duration.Hours).ToString() + "h:" + $($Duration.Minutes).ToString() + "m:" + $($Duration.Seconds).ToString() + "s"
        $Stats | Format-Table -Wrap -AutoSize
    
        Write-Verbose "The operation completed in $DurationPretty"
        Write-Verbose "Disk space saved: $([math]::round($TotalSaved /1Gb, 2)) GB"
    } #End
    
} #function 

# Get-VHDImages

Compress-Vhdx
