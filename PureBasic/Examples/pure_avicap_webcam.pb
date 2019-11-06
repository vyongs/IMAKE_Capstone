#WM_CAP_START = #WM_USER
#WM_CAP_DRIVER_CONNECT = #WM_CAP_START + 10
#WM_CAP_DRIVER_DISCONNECT = #WM_CAP_START + 11
#WM_CAP_DRIVER_GET_CAPS = #WM_CAP_START + 14
#WM_CAP_SET_PREVIEW = #WM_CAP_START + 50
#WM_CAP_SET_PREVIEWRATE = #WM_CAP_START + 52
#WM_CAP_STOP = #WM_CAP_START + 68

If OpenWindow(0, 0, 0, 340, 260, "Cam Capture", #PB_Window_ScreenCentered | #PB_Window_SystemMenu)
  If OpenLibrary(0, "avicap32.dll")
    *capAddress = GetFunction(0, "capCreateCaptureWindowA")
    hWndC = CallFunctionFast(*capAddress, @"My Capture Window", #WS_CHILD | #WS_VISIBLE, 10, 10, 320, 240, WindowID(0),1)
    SendMessage_(hWndC, #WM_CAP_DRIVER_CONNECT, 0, 0)
    SendMessage_(hWndC, #WM_CAP_SET_PREVIEW, #True, 0)
    SendMessage_(hWndC, #WM_CAP_SET_PREVIEWRATE, 15, 0)
  EndIf
EndIf

Repeat
  Event = WaitWindowEvent()
Until Event = #PB_Event_CloseWindow

SendMessage_(hWndC, #WM_CAP_STOP, 0, 0)
SendMessage_(hWndC, #WM_CAP_DRIVER_DISCONNECT, 0, 0)
DestroyWindow_(hWndC)
CloseLibrary(0)

End
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 16
; EnableXP