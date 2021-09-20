; Source: https://www.autohotkey.com/boards/viewtopic.php?t=73967
; Autostart: https://www.autohotkey.com/docs/FAQ.htm#Startup
#+z::
#SingleInstance Force
#NoTrayIcon                                       
; Read the app mode from the registry 
RegRead,L_LightMode,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme
If L_LightMode {                                  
	; change app mode to light
	RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme,0
	RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme   ,0
	}
else {                                            
	; change app mode to light
	RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,SystemUsesLightTheme,0
	RegWrite,Reg_Dword,HKCU,SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize,AppsUseLightTheme   ,1
	}
; trigger refresh of the user settings
run,RUNDLL32.EXE USER32.DLL`, UpdatePerUserSystemParameters `,2 `,True
; Exitapp 