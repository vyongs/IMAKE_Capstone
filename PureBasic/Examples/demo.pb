XIncludeFile "escapi.pb"
UsePNGImageEncoder()

device = 0

count = setupESCAPI()
Debug "init: " + Str(count)

If count = 0
  End
EndIf

name$ = Space(1000)
getCaptureDeviceName(device, @name$, 1000)
;Debug "name: " + name$

scp.SimpleCapParams
scp\mWidth = 800
scp\mHeight = 600
scp\mTargetBuf = AllocateMemory (scp\mWidth * scp\mHeight * 4)

If initCapture(device, @scp)
  Debug "cap init successful" 
 
  image = CreateImage(#PB_Any, 800, 600)
 
  OpenWindow(0, 0, 0, 800, 600, "WebCam-DSCHO", #PB_Window_ScreenCentered|#PB_Window_SystemMenu)
  UseGadgetList(WindowID(0))
  ImageGadget(0, 0, 0, 800, 600, ImageID(image))
 
  Quit = 0
  Repeat
 
    doCapture(device)
    While isCaptureDone(device) = 0
      If WaitWindowEvent(1) = #PB_Event_CloseWindow
        Quit = 1
        Break
      EndIf       
    Wend
   
    If StartDrawing(ImageOutput(image))   
      For y = 0 To scp\mHeight - 1
        For x = 0 To scp\mWidth - 1
          pixel = PeekL(scp\mTargetBuf + (y*scp\mWidth + x) * 4)
          rgb   = RGB((pixel >> 16) & $FF, (pixel >> 8) & $FF, pixel & $FF)
          Plot(x, y, rgb)
        Next
      Next
      Circle(100,100,50,RGB(100,200,120))
     
      StopDrawing()
      SetGadgetState(0, ImageID(image))
    EndIf
     
 
  Until Quit
  
  SaveImage(image, "dscho_webcam.png",#PB_ImagePlugin_PNG)
  
  deinitCapture(device)
Else
  Debug "init capture failed!"
EndIf

End
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 52
; FirstLine = 33
; EnableXP