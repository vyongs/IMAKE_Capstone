IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Generates a Mandelbrot Set, the most popular geometrical fractal." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Flip RGB / BGR."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          FileName.s = SaveCVImage()

          If FileName
            params.CvSaveData

            Select LCase(GetExtensionPart(FileName))
              Case "bmp", "dib"
              Case "jpeg", "jpg", "jpe"
                params\paramId = #CV_IMWRITE_JPEG_QUALITY
                params\paramValue = 95
              Case "jp2"
              Case "png"
                params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                params\paramValue = 3
              Case "ppm", "pgm", "pbm"
                params\paramId = #CV_IMWRITE_PXM_BINARY
                params\paramValue = 1
              Case "sr", "ras"
              Case "tiff", "tif"
              Default
                Select SelectedFilePattern()
                  Case 0
                    FileName + ".bmp"
                  Case 1
                    FileName + ".jpg"
                    params\paramId = #CV_IMWRITE_JPEG_QUALITY
                    params\paramValue = 95
                  Case 2
                    FileName + ".jp2"
                  Case 3
                    FileName + ".png"
                    params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                    params\paramValue = 3
                  Case 4
                    FileName + ".ppm"
                    params\paramId = #CV_IMWRITE_PXM_BINARY
                    params\paramValue = 1
                  Case 5
                    FileName + ".sr"
                  Case 6
                    FileName + ".tiff"
                EndSelect
            EndSelect
            cvSaveImage(FileName, *save, @params)
          EndIf
        Case 10
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
  EndSelect
EndProcedure

cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
*window_name = cvGetWindowName(window_handle)
lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
  MenuItem(1, "Save")
  MenuBar()
  MenuItem(10, "Exit")
EndIf
hWnd = GetParent_(window_handle)
iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
*image.IplImage = cvCreateImage(600, 400, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvSetZero(*image)
xStart.f = -2.2
yStart.f = -1
xScale.f = 3
yScale.f = 2
bOut.f = 4
xIncrement.f = xScale / *image\width
yIncrement.f = yScale / *image\height
iMax = 1000
*mandelbrot.IplImage = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 3)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *mandelbrot
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)
y.f = yStart

For nLine = 0 To *image\height - 1
  x.f = xStart

  For nPixel = 0 To *image\width - 1
    x1.f = 0
    y1.f = 0
    i = 0

    While x1 * x1 + y1 * y1 <= bOut And i < iMax
      temp.f = (x1 * x1) - (y1 * y1) + x
      y1 = (2 * x1 * y1) + y
      x1 = temp
      i + 1
    Wend

    If i >= iMax
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 0, 0)
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 1, 0)
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 2, 0)
    Else
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 0, i % 255)
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 1, 255)
      PokeA(@*image\imageData\b + *image\widthStep * (*image\height - 1 - nLine) + nPixel * 3 + 2, 255)
    EndIf
    x + xIncrement
  Next

  If fractal : cvCvtColor(*image, *mandelbrot, #CV_HSV2BGR, 1) : Else : cvCvtColor(*image, *mandelbrot, #CV_HSV2RGB, 1) : EndIf

  cvShowImage(#CV_WINDOW_NAME, *mandelbrot)
  keyPressed = cvWaitKey(1)

  If keyPressed = 27 Or exitCV : Break : ElseIf keyPressed = 32 : fractal ! #True : EndIf

  y + yIncrement
Next

If keyPressed <> 27 And exitCV = #False
  Repeat
    If *mandelbrot
      cvShowImage(#CV_WINDOW_NAME, *mandelbrot)
      keyPressed = cvWaitKey(0)

      If keyPressed = 32
        fractal ! #True

        If fractal : cvCvtColor(*image, *mandelbrot, #CV_HSV2BGR, 1) : Else : cvCvtColor(*image, *mandelbrot, #CV_HSV2RGB, 1) : EndIf

      EndIf
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
EndIf
cvReleaseImage(@*mandelbrot)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\