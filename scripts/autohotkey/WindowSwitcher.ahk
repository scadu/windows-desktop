; Source: https://github.com/microsoft/PowerToys/issues/2954#issuecomment-1881754076
!`::
{
    Active_ID := WinGetID("A")
    Active_Process := WinGetProcessName(Active_ID)
    class := WinGetClass("A")
    id := WinGetList("ahk_class " class " ahk_exe " Active_Process)
    lastItem := id.Pop()
    WinActivate("ahk_id " lastItem)
    WinMoveTop("ahk_id " lastItem)
}