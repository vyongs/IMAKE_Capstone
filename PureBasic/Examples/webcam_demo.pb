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

; Macro GetColorXY(DataPointer, PixelX, PixelY, ImageWidth, ImageHeight)
;   PeekL(DataPointer + ((ImageHeight - PixelY) * ImageWidth + PixelX) * 3) & $00FFFFFF
; EndMacro

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
;   Protected leftred1, leftred2, leftgreen1, leftgreen2, leftblue1, leftblue2
;   Protected red1, red2, green1, green2, blue1, blue2
;   Protected density1, density2
;   Protected maxChange, change
;   Protected posX, posY

  If made <= 0
    CopyMemory(*lpVHdr\lpData, *oldMem, 320 * 240 * 3)
    made = 1
  EndIf

;   maxChange = 0

  For y = 240 - 1 To 0 Step -1

;     blue1  = *VideoMemoryAdress1\b & $FF
;     green1 = *VideoMemoryAdress1\g & $FF
;     red1   = *VideoMemoryAdress1\r & $FF
; 
;     blue2  = *VideoMemoryAdress2\b & $FF
;     green2 = *VideoMemoryAdress2\g & $FF
;     red2   = *VideoMemoryAdress2\r & $FF
; 
;     *VideoMemoryAdress1 + 3
;     *VideoMemoryAdress2 + 3

    For x = 320 - 1 To 1 Step -1

;       leftblue1  = blue1
;       leftgreen1 = green1
;       leftred1   = red1
; 
;       leftblue2  = blue2
;       leftgreen2 = green2
;       leftred2   = red2
; 
;       blue1  = (*VideoMemoryAdress1\b & $FF + leftblue1) * 0.5
;       green1 = (*VideoMemoryAdress1\g & $FF + leftgreen1) * 0.5
;       red1   = (*VideoMemoryAdress1\r & $FF + leftred1) * 0.5
; 
;       blue2  = (*VideoMemoryAdress2\b & $FF + leftblue2) * 0.5
;       green2 = (*VideoMemoryAdress2\g & $FF + leftgreen2) * 0.5
;       red2   = (*VideoMemoryAdress2\r & $FF + leftred2) * 0.5
; 
;       density1 = (red1 + green1 + blue1) * 0.3333
;       density2 = (red2 + green2 + blue2) * 0.3333
; 
;       change = Pow(density2 - density1, 2) * 0.1
; 
;       *VideoMemoryAdress1\b = change
;       *VideoMemoryAdress1\g = *VideoMemoryAdress1\b
;       *VideoMemoryAdress1\r = *VideoMemoryAdress1\b

      ;       change * (320 * 320 + 240 * 240) * 3 / (Pow(x - oldPosX, 2) + Pow(y - oldPosY, 2))

;       If maxChange < change
;         maxChange = change
;         posX = x
;         posY = y
;       EndIf

;       *VideoMemoryAdress1 + 3
;       *VideoMemoryAdress2 + 3
    Next x
  Next y

;   posX = Int((DesktopWidth(0)  / (320.0 * 2)) * posX) * 2
;   posY = Int((DesktopHeight(0) / (240.0 * 2)) * posY) * 2
  
;   *VideoMemoryAdress1 = *lpVHdr\lpData

  StartDrawing(ImageOutput(0))
  For y = 240 - 1 To 0 Step -1
    For x = 0 To 320 - 1
      Plot(x, y, RGB(*VideoMemoryAdress1\r & $FF, *VideoMemoryAdress1\g & $FF, *VideoMemoryAdress1\b & $FF))
      *VideoMemoryAdress1 + 3
    Next
  Next
  StopDrawing()

;   If maxChange > 130
;     posX = oldPosX + (posX - oldPosX) * 0.25
;     posY = oldPosY + (posY - oldPosY) * 0.25
; 
;     SetWindowTitle(0, Str(posX) + ":" + Str(posY))
;     ;SetCursorPos_(posX, posY)
;     oldPosX = posX
;     oldPosY = posY
;   EndIf

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
; CursorPosition = 152
; FirstLine = 146
; Folding = -
; EnableXP