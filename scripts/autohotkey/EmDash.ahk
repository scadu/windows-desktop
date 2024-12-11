#Requires AutoHotkey v2.0

; This hotstring will convert -- to em dash (—)
; The * means you don't need to press space/enter after typing
; The ? allows the hotstring to trigger even when it's part of another word
#HotIf !IsExcludedWindow()
:*?:--::—
#HotIf

IsExcludedWindow() {
    ; Get active window's class and process name
    activeWindow := WinGetProcessName("A")
    activeClass := WinGetClass("A")
    
    ; List of excluded windows (add more as needed)
    excludedProcesses := ["Code.exe", "WindowsTerminal.exe"]
    
    ; Check if current window is in excluded list
    for process in excludedProcesses {
        if (activeWindow = process)
            return true
    }
    
    return false
}

; Hotkey to get window info (Ctrl + Shift + W)
^+w:: {
    activeWindow := WinGetProcessName("A")
    activeClass := WinGetClass("A")
    activeTitle := WinGetTitle("A")
    
    info := "Window Info:"
        . "`nProcess Name: " activeWindow
        . "`nWindow Class: " activeClass
        . "`nWindow Title: " activeTitle
    
    MsgBox(info)
}