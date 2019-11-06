;WORKS WITH ESCAPI
;UPDATED 8/28/2017
;PRESS CTL-Q TO QUIT

; http://sol.gfxile.net/zip/escapi3.zip


ExamineDesktops()

gamma.f = 1.34 ;WEBCAM OUTPUT IS ALREADY GAMMA CORRECTED
#PEDESTAL = 16
gain.f = (235-16)/235
gain * 0.97

factor.f = 255/Pow(255,gamma)

;SET WEBCAM TO DEFAULTS AND SHARPNESS TO 255

;MAKE LUTS
Dim gammaTable.f(256)
For cnt = 0 To 255
cnf.f = cnt
gammaTable.f(cnt)=cnt;(Pow(cnf,gamma) * factor * gain) + #PEDESTAL
Next

Dim x3table.l(1921)
For cnt = 0 To 1920
x3table(cnt) = cnt * 3
Next

LoadFont(1,"Arial",24)

IncludeFile "escapi.pb"
Global WIDTH = 800; DesktopWidth(0) ;640
Global HEIGHT = 600; DesktopHeight(0) ;480
Global WIDTHM1 = WIDTH - 1
Global HEIGHTM1 = HEIGHT - 1
Global pixCount = (WIDTH * HEIGHT) - 2

Global Dim pixcolor.l(WIDTH, HEIGHT): Global Dim unsmoothedY.d(WIDTH, HEIGHT)
Global Dim Cr.d(WIDTH, HEIGHT): Global Dim Y.d(WIDTH, HEIGHT): Global Dim Cb.d(WIDTH, HEIGHT)
Global imHeight, imWidth, xCoord, yCoord,Rd,Gd,Bd

#DEVICE = 0   
If setupESCAPI() = #Null
      MessageRequester("Error", "Unable to initialize ESCAPI.")
    End
EndIf

    bufSize = WIDTH * HEIGHT * 4
    scp.SimpleCapParams
    scp\mWidth = WIDTH
    scp\mHeight = HEIGHT
    scp\mTargetBuf = AllocateMemory(bufSize)
    *buf = scp\mTargetBuf

    If initCapture(#DEVICE, @scp)
     
image = CreateImage(1, WIDTH, HEIGHT, 24)
OpenWindow(1, 0, 0, WIDTH, HEIGHT,"",#PB_Window_BorderLess)
AddKeyboardShortcut(1, #PB_Shortcut_Control|#PB_Shortcut_Q, 113);CTL Q TO QUIT
ImageGadget(0, 0, 0, WIDTH, HEIGHT, ImageID(1))
Quit = #False

StartDrawing(ImageOutput(1))
*writeBuffer = DrawingBuffer()
pitch = DrawingBufferPitch()
StopDrawing()

Repeat
If WindowEvent() = #PB_Event_Menu ;KEYBOARD INPUT
If EventMenu() = 113
  Quit = #True
EndIf
EndIf       
     
doCapture(#DEVICE)

Repeat: Delay(1):Until isCaptureDone(#DEVICE) <> #False

;If isCaptureDone(#DEVICE) <> #False
;If isCaptureDone(#DEVICE) = #False

;PIXEL-BY-PIXEL READING AND WRITING
hm1 = *writebuffer + (HEIGHTM1 * pitch)
*bufoff = *buf

;Goto skip
For y = 0 To HEIGHTM1
For x = 0 To WIDTHM1
x3 = hm1 + x3table(x)

p1.l = PeekL(*bufoff)

PokeA(x3,gammaTable(p1 & 255))
PokeA(x3+1,gammaTable(p1 >> 8 & 255))
PokeA(x3+2,gammaTable(p1 >> 16 & 255))

*bufoff + 4
Next
hm1 - pitch
Next

skip:
SetGadgetState(0, ImageID(1))

StartDrawing(WindowOutput(1))
DrawingFont(FontID(1))

now.f = ElapsedMilliseconds()
fps.f = now.f-then.f

If fps > 0:fps$ = StrF((1/fps)*1000,2) ;:EndIf
If (1/fps)*1000 < 10: fps$ = "0" + fps$: EndIf
EndIf

DrawText(100, 200, fps$+" fps",#White)
then.f = ElapsedMilliseconds()
StopDrawing()

Until Quit = #True

deinitCapture(#DEVICE)
FreeImage(1)
FreeMemory(scp\mTargetBuf)
CloseWindow(1)

    Else
      Debug "Init capture failed."
    EndIf

    End
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 34
; FirstLine = 25
; EnableXP