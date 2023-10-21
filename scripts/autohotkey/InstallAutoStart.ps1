$WshShell = New-Object -comObject WScript.Shell

# Specify the directory where your AHK scripts are stored
$ahkDirectory = $PSScriptRoot
$ahkScripts = Get-ChildItem $ahkDirectory -Filter "*.ahk"

foreach ($script in $ahkScripts) {
    $Shortcut = $WshShell.CreateShortcut("$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\" + $script.BaseName + ".lnk")
    $Shortcut.TargetPath = $script.FullName
    $Shortcut.Save()
}