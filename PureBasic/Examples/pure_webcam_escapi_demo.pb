XIncludeFile "escapi.pbi"

device = 0

count = setupESCAPI()
Debug "init: " + Str(count)

If count = 0
  End
EndIf

*name = AllocateMemory(1000)
getCaptureDeviceName(device, *name, 1000)
name$ = PeekS(*name, -1, #PB_Ascii)
Debug "name: " + name$
FreeMemory(*name)

scp.SimpleCapParams
scp\mWidth = 640
scp\mHeight = 360
scp\mTargetBuf = AllocateMemory (scp\mWidth * scp\mHeight * 4)

If initCapture(device, @scp)
  Debug "cap init successful"
 
  gadgetimage = CreateImage(#PB_Any, scp\mWidth, scp\mHeight)
  webcamimage = CreateImage(#PB_Any, scp\mWidth, scp\mHeight, 32)
  CopyImage(gadgetimage, renderedimage)
 
  OpenWindow(0, 0, 0, scp\mWidth, scp\mHeight, name$, #PB_Window_ScreenCentered|#PB_Window_SystemMenu)
  ImageGadget(0, 0, 0, scp\mWidth, scp\mHeight, ImageID(gadgetimage))
  LoadFont(0, "Impact", 20, #PB_Font_Bold)
 
  Quit = 0
  Repeat
   
    doCapture(device)
    While isCaptureDone(device) = 0
      If WaitWindowEvent(1) = #PB_Event_CloseWindow
        Quit = 1
        Break
      EndIf       
    Wend
   
    If StartDrawing(ImageOutput(webcamimage))
      Buffer      = DrawingBuffer()             ; Get the start address of the screen buffer
      Pitch       = DrawingBufferPitch()        ; Get the length (in byte) took by one horizontal line
      PixelFormat = DrawingBufferPixelFormat()  ; Get the pixel format.
      CopyMemory(scp\mTargetBuf, Buffer, scp\mWidth * scp\mHeight * 4)
      StopDrawing()
    EndIf
   
    If StartDrawing(ImageOutput(renderedimage))
      DrawImage(ImageID(webcamimage), 0, 0)
      StopDrawing()
    EndIf
   
    now = ElapsedMilliseconds()
    fps.f = now - then
    If fps > 0 : fps$ = StrF((1/fps)*1000, 2) ;:EndIf
      If (1 / fps) * 1000 < 10: fps$ = "0" + fps$: EndIf
    EndIf 
    then = ElapsedMilliseconds()
     
    If StartVectorDrawing(ImageVectorOutput(gadgetimage, #PB_Unit_Pixel))
      VectorSourceColor(RGBA(0, 0, 0, 255))
      FillVectorOutput()
      RotateCoordinates(scp\mWidth/2, scp\mHeight/2, now / 10)
      MovePathCursor(0, 0)     
      DrawVectorImage(ImageID(renderedimage), 128)
      ResetCoordinates()
      MovePathCursor(10, 10)     
      VectorFont(FontID(0), 25)
      VectorSourceColor(RGBA(255, 255, 0, 255))
      DrawVectorText(fps$ + " fps")
      StopVectorDrawing()
    EndIf
    SetGadgetState(0, ImageID(gadgetimage))
   
  Until Quit
 
  deinitCapture(device)
Else
  Debug "init capture failed!"
EndIf

End
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 86
; FirstLine = 49
; EnableXP