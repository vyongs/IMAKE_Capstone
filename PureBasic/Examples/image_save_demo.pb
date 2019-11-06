UsePNGImageDecoder()
UsePNGImageEncoder()
UseJPEGImageDecoder()
UseJPEG2000ImageDecoder()
UseTGAImageDecoder()

Procedure TransPNG(File$,TransColor)
LoadImage(0,File$)

If TransColor <> #White
   StartDrawing(ImageOutput(0))
       For x = 0 To ImageWidth(0) - 1
          For y = 0 To ImageHeight(0) - 1
             If Point(x,y) = TransColor
                Plot(x,y,RGB(255, 255, 255))
             EndIf
          Next
       Next
   StopDrawing()
 EndIf 

i.ICONINFO
i\fIcon = #False
i\hbmMask = ImageID(0)
i\hbmColor = ImageID(0)

curHnd = CreateIconIndirect_(i)

CreateImage(10,ImageWidth(0),ImageHeight(0),32)
StartDrawing(ImageOutput(10))
DrawingMode(#PB_2DDrawing_AllChannels)
DrawImage(curHnd,0,0,ImageWidth(0),ImageHeight(0))
StopDrawing()

FreeImage(0)
EndProcedure

TransPNG("girlgreen.bmp",#Green)   ;The filename including path ,The required color to be transparent
SaveImage(10, "girltrans.png",#PB_ImagePlugin_PNG)
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 21
; FirstLine = 6
; Folding = -
; EnableXP