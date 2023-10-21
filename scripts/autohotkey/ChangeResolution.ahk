#NoTrayIcon

; The function ChangeResolution changes the screen resolution.
; It accepts width, height and bit depth as parameters.
; Original code: https://www.reddit.com/r/AutoHotkey/comments/11w816x/autohotkey_v2_code_to_change_screen_resolution/
ChangeResolution(Screen_Width := 1920, Screen_Height := 1080, Color_Depth := 32)
{
    ; Create a buffer to hold device information, initialized with 0s.
    ; Its size is 156, matching the size of the DEVMODE struct used by Windows API for display settings.
    ; https://learn.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-devmodea
    Device_Mode := Buffer(156, 0)
    
    ; Set the size of the structure (device mode).
    ; This is important when interacting with Windows API, which expects the size of the structure at this offset.
    ; The number 36 is the offset in the buffer where the 'dmSize' member of the DEVMODEA struct is placed.
    NumPut("UShort", 156, Device_Mode, 36)
    
    ; Call EnumDisplaySettings to fill the structure with data about the current display settings.
    DllCall("EnumDisplaySettingsA", "UInt", 0, "UInt", -1, "Ptr", Device_Mode)
    
    ; Update the bits per pixel (color depth) in the structure.
    ; The number 104 is the offset in the buffer where the 'dmBitsPerPel' member of the DEVMODEA struct is placed.
    NumPut("UInt", Color_Depth, Device_Mode, 104)
    
    ; Update the screen width and height in the structure.
    ; The numbers 108 and 112 are offsets in the buffer where the 'dmPelsWidth' and 'dmPelsHeight' members of the DEVMODEA struct are placed.
    NumPut("UInt", Screen_Width, Device_Mode, 108)
    NumPut("UInt", Screen_Height, Device_Mode, 112)
    
    ; Call ChangeDisplaySettings to apply the new settings.
    ; The 0 passed as argument tells Windows to change the display settings immediately.
    Return DllCall( "ChangeDisplaySettingsA", "Ptr",Device_Mode, "UInt",0 )
}

; Ctrl + Alt + F1
^!F1::
{
    ChangeResolution(1920,1080,32)
    return
}

; Ctrl + Alt + F2
^!F2::
{
    ChangeResolution(3440,1440,32)
    return
}