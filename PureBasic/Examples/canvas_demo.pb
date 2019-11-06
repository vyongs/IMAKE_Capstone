CompilerIf Not #PB_Compiler_Thread
   MessageRequester("", "Enable Create thread-safe executable")
   End
CompilerEndIf

Declare.i InsertImage()

OpenWindow(0, 0, 0, 800, 800, "Test", #PB_Window_SystemMenu)
CanvasGadget(0, 0, 0, 500, 500)
StartDrawing(CanvasOutput(0))
For y = 0 To 4 Step 1
  For x = 0 To 4 Step 1
    DrawImage(ImageID(InsertImage()), x * 100, y * 100)
  Next x
Next y
StopDrawing()

Repeat : ev = WindowEvent() : Until ev = #PB_Event_CloseWindow

Procedure.i InsertImageThread(*Image.Integer)
  Protected im = CreateImage(#PB_Any, 100, 100)
  StartDrawing(ImageOutput(im))
  Box(0,0, 100, 100, RGB(Random(255), Random(255), Random(255)))
  StopDrawing()
  *Image\i = im
EndProcedure

Procedure.i InsertImage()
   Protected Image.i
   WaitThread(CreateThread(@InsertImageThread(), @Image))
   ProcedureReturn Image
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 9
; Folding = -
; EnableThread
; EnableXP