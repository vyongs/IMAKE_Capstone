#WM_CAP_START = #WM_USER

;#WM_CAP_SET_CALLBACK_ERROR = #WM_CAP_START + 2
;#WM_CAP_SET_CALLBACK_STATUS = #WM_CAP_START + 3
#WM_CAP_SET_CALLBACK_YIELD = #WM_CAP_START + 4
#WM_CAP_SET_CALLBACK_FRAME = #WM_CAP_START + 5
#WM_CAP_SET_CALLBACK_VIDEOSTREAM = #WM_CAP_START + 6
#WM_CAP_SET_CALLBACK_WAVESTREAM = #WM_CAP_START + 7

#WM_CAP_DRIVER_CONNECT        =  #WM_USER + 10
#WM_CAP_DRIVER_DISCONNECT     =  #WM_USER + 11
#WM_CAP_DRIVER_GET_CAPS = #WM_CAP_START + 14

#WM_CAP_DLG_VIDEOFORMAT = #WM_CAP_START + 41
#WM_CAP_DLG_VIDEOSOURCE = #WM_CAP_START + 42
#WM_CAP_DLG_VIDEODISPLAY = #WM_CAP_START + 43

#WM_CAP_SET_PREVIEW = #WM_CAP_START + 50
#WM_CAP_SET_PREVIEWRATE = #WM_CAP_START + 52
#WM_CAP_GET_STATUS = #WM_CAP_START + 54

;#WM_CAP_FILE_SAVEDIB          =  #WM_USER + 25
#WM_CAP_SET_SCALE             =  #WM_USER + 53

#WM_CAP_SET_CALLBACK_CAPCONTROL = #WM_CAP_START + 85

Structure VIDEOHDR
  lpData.l
  dwBufferLength.l
  dwBytesUsed.l
  dwTimeCaptured.l
  dwUser.l
  dwFlags.l
  dwReserved.l[3]
EndStructure

Structure CAPSTATUS
  uiImageWidth.l
  uiImageHeight.l
  fLiveWindow.l
  fOverlayWindow.l
  fScale.l
  ptScroll.Point
  fUsingDefaultPalette.l
  fAudioHardware.l
  fCapFileExists.l
  dwCurrentVideoFrame.l
  dwCurrentVideoFramesDropped.l
  dwCurrentWaveSamples.l
  dwCurrentTimeElapsedMS.l
  hPalCurrent.l
  fCapturingNow.l
  dwReturn.l
  wNumVideoAllocated.l
  wNumAudioAllocated.l
EndStructure


CompilerIf #PB_Compiler_Unicode = 0
  Import "avicap32.lib"
    capCreateCaptureWindow.l(name.s, style.l, x.l, y.l, width.l, height.l, hWndParent.l, nId.l) As "_capCreateCaptureWindowA@32"
    capGetDriverDescription.l(index.l, name.l, cbName.l, ver.l, cbVer.l) As "_capGetDriverDescriptionA@20"
  EndImport
  CompilerElse
  Import "avicap32.lib"
    capCreateCaptureWindow.l(name.s, style.l, x.l, y.l, width.l, height.l, hWndParent.l, nId.l) As "_capCreateCaptureWindowW@32"
    capGetDriverDescription.l(index.l, name.l, cbName.l, ver.l, cbVer.l) As "_capGetDriverDescriptionW@20"
  EndImport
CompilerEndIf

ExamineDesktops()


Structure SBGR
  b.b
  g.b
  r.b
EndStructure

Global *oldMem.BYTE, oldPosX, oldPosY, made

*oldMem = AllocateMemory(320 * 240 * 3)
made = 0

CreateImage(0, 320, 240)

Procedure FrameCallback(hWnd.l, *lpVHdr.VIDEOHDR)
  Protected *VideoMemoryAdress1.SBGR = *lpVHdr\lpData
  Protected *VideoMemoryAdress2.SBGR = *oldMem


  If made <= 0
    CopyMemory(*lpVHdr\lpData, *oldMem, 320 * 240 * 3)
    made = 1
  EndIf


;   For y = 240 - 1 To 0 Step -1
;     For x = 320 - 1 To 1 Step -1
        ;pass
;     Next x
;   Next y


  StartDrawing(ImageOutput(0))
  For y = 240 - 1 To 0 Step -1
    For x = 0 To 320 - 1
      Plot(x, y, RGB(*VideoMemoryAdress1\r & $FF, *VideoMemoryAdress1\g & $FF, *VideoMemoryAdress1\b & $FF))
      *VideoMemoryAdress1 + 3
 
      Plot(x, y, RGB(*VideoMemoryAdress2\r & $FF, *VideoMemoryAdress2\g & $FF, *VideoMemoryAdress2\b & $FF))
      *VideoMemoryAdress2 + 3
    Next
  Next
  Box(0, 0, 200, 200, RGB(255, 255, 255))
  StopDrawing()

EndProcedure

hWnd = OpenWindow(0, 0, 0, 320,240, "Webcam DSCHO", #PB_Window_SystemMenu)

hWebcam = capCreateCaptureWindow("Webcam DSCHO", #WS_VISIBLE | #WS_CHILD, 0, 0, 320, 240, hWnd, 0)

SendMessage_(hWebcam, #WM_CAP_DRIVER_CONNECT          , 0, 0)
SendMessage_(hWebcam, #WM_CAP_SET_SCALE               , 1, 0)
SendMessage_(hWebcam, #WM_CAP_SET_PREVIEWRATE         , 10, 0)
SendMessage_(hWebcam, #WM_CAP_SET_PREVIEW             , 1, 0)
SendMessage_(hWebcam, #WM_CAP_SET_CALLBACK_FRAME      , 0, @FrameCallback())

Repeat
Until WaitWindowEvent(3) = #PB_Event_CloseWindow
End

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 104
; FirstLine = 100
; Folding = -
; EnableXP
; Executable = webcam_DSCHO.exe