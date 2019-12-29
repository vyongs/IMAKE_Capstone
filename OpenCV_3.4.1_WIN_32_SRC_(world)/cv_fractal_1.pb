IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, *fractal.IplImage, iCount, nFont.CvFont

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Generates an iterative Mandelbrot Set, the most popular geometrical fractal." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Select an area to enlarge." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Flip RGB / BGR." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the fractal." + #LF$ + #LF$ +
                  "[ P ] KEY   " + #TAB$ + ": Show previous selection."

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

#MAX_COLOR = 256
Global Dim nB(#MAX_COLOR), Dim nG(#MAX_COLOR), Dim nR(#MAX_COLOR)

Procedure InitColor()
  For rtnCount = 0 To #MAX_COLOR - 1
    nB(rtnCount) = rtnCount * 4 % 256
    nG(rtnCount) = 0.7 * 255
    nR(rtnCount) = 255 * (1 - rtnCount / 255 * rtnCount / 255 / 1.2)
  Next
EndProcedure

Structure FRACTAL_INDEX Align #PB_Structure_AlignC
  *image.IplImage
  xMax.d
  xMin.d
  yMax.d
  yMin.d
  nFractal.l
EndStructure

Structure Complex Align #PB_Structure_AlignC
  real.d
  imaginary.d
EndStructure

Global Dim fi.FRACTAL_INDEX(1)

Procedure DrawPicture()
  deltaX.d = (fi(iCount)\xMax - fi(iCount)\xMin) / fi(iCount)\image\width
  deltaY.d = (fi(iCount)\yMax - fi(iCount)\yMin) / fi(iCount)\image\height
  maxIterations = 256 : maxSize.d = 4
  c.Complex : z.Complex

  For row = 0 To fi(iCount)\image\height - 1
    For col = 0 To fi(iCount)\image\width - 1
      color = 0
      z\real = 0
      z\imaginary = 0
      c\real = fi(iCount)\xMin + col * deltaX
      c\imaginary = fi(iCount)\yMin + row * deltaY

      While color < maxIterations And z\imaginary * z\imaginary + z\real * z\real < maxSize
        temp.d = z\real * z\real - z\imaginary * z\imaginary + c\real
        z\imaginary * z\real + z\real * z\imaginary + c\imaginary
        z\real = temp
        color + 1
      Wend

      If color >= maxIterations : color = 255 : EndIf

      color % #MAX_COLOR
      PokeA(@fi(iCount)\image\imageData\b + (row * fi(iCount)\image\widthStep) + col * 3 + 0, nB(color))
      PokeA(@fi(iCount)\image\imageData\b + (row * fi(iCount)\image\widthStep) + col * 3 + 1, nG(color))
      PokeA(@fi(iCount)\image\imageData\b + (row * fi(iCount)\image\widthStep) + col * 3 + 2, nR(color))
    Next
  Next

  If fi(iCount)\nFractal
    cvCvtColor(fi(iCount)\image, fi(iCount)\image, #CV_HSV2RGB, 1)
  Else
    cvCvtColor(fi(iCount)\image, fi(iCount)\image, #CV_HSV2BGR, 1)
  EndIf
  cvShowImage(#CV_WINDOW_NAME, fi(iCount)\image)
EndProcedure

Global pt1.CvPoint, pt2.CvPoint

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select #True
    Case Bool(event = #CV_EVENT_RBUTTONDOWN)
      *save = fi(iCount)\image
      DisplayPopupMenu(0, *param\Value)
    Case Bool(event = #CV_EVENT_LBUTTONDOWN)
      pt1\x = x : pt1\y = y
    Case Bool(event = #CV_EVENT_LBUTTONUP)
      If Abs(pt2\x - pt1\x) > Abs(pt2\y - pt1\y)
        iRatio.d = Abs(pt2\x - pt1\x) / fi(iCount)\image\width

        If pt2\y > pt1\y
          pt2\y = pt1\y + fi(iCount)\image\height * iRatio
        Else
          pt1\y = pt2\y + fi(iCount)\image\height * iRatio
        EndIf
      Else
        iRatio.d = Abs(pt2\y - pt1\y) / fi(iCount)\image\height

        If pt2\x > pt1\x
          pt2\x = pt1\x + fi(iCount)\image\width * iRatio
        Else
          pt1\x = pt2\x + fi(iCount)\image\width * iRatio
        EndIf
      EndIf

      If pt1\x > 0 And pt1\y > 0 And pt2\x > 0 And pt2\y > 0 And Abs(pt2\x - pt1\x) > 5 And Abs(pt2\y - pt1\y) > 5
        iCount = ArraySize(fi())
        ReDim fi(iCount + 1)
        fi(iCount)\image = cvCreateImage(800, 600, #IPL_DEPTH_8U, 3)
        fi(iCount)\xMax = fi(iCount - 1)\xMax : fi(iCount)\xMin = fi(iCount - 1)\xMin
        fi(iCount)\yMax = fi(iCount - 1)\yMax : fi(iCount)\yMin = fi(iCount - 1)\yMin
        fi(iCount)\nFractal = fi(iCount - 1)\nFractal
        cvPutText(*fractal, "Working...", 22, 42, @nFont, 0, 0, 0, 0)
        cvPutText(*fractal, "Working...", 20, 40, @nFont, 255, 255, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *fractal)
        cvWaitKey(1)
        DX.d = fi(iCount)\xMax - fi(iCount)\xMin
        DY.d = fi(iCount)\yMax - fi(iCount)\yMin
        offX.d = DX / fi(iCount)\image\width
        offY.d = DY / fi(iCount)\image\height

        If pt1\x < pt2\x
          fi(iCount)\xMax = offX * pt2\x + fi(iCount)\xMin
          fi(iCount)\xMin = offX * pt1\x + fi(iCount)\xMin
        Else
          fi(iCount)\xMax = offX * pt1\x + fi(iCount)\xMin
          fi(iCount)\xMin = offX * pt2\x + fi(iCount)\xMin
        EndIf

        If pt1\y < pt2\y
          fi(iCount)\yMax = offY * pt2\y + fi(iCount)\yMin
          fi(iCount)\yMin = offY * pt1\y + fi(iCount)\yMin
        Else
          fi(iCount)\yMax = offY * pt1\y + fi(iCount)\yMin
          fi(iCount)\yMin = offY * pt2\y + fi(iCount)\yMin
        EndIf
        pt1\x = -1 : pt1\y = -1 : pt2\x = -1 : pt2\y = -1
        DrawPicture()
      Else
        pt1\x = -1 : pt1\y = -1 : pt2\x = -1 : pt2\y = -1
        cvShowImage(#CV_WINDOW_NAME, fi(iCount)\image)
      EndIf
    Case Bool(event = #CV_EVENT_MOUSEMOVE And (flags & #CV_EVENT_FLAG_LBUTTON))
      pt2\x = x : pt2\y = y

      If pt1\x > 0 And pt1\y > 0 And pt2\x > 0 And pt2\y > 0 And Abs(pt2\x - pt1\x) > 5 And Abs(pt2\y - pt1\y) > 5
        cvCopy(fi(iCount)\image, *fractal, #Null)
        cvRectangle(*fractal, pt1\x, pt1\y, pt2\x, pt2\y, 0, 0, 255, 0, 2, #CV_AA, #Null)
        cvShowImage(#CV_WINDOW_NAME, *fractal)
      EndIf
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
fi(0)\image = cvCreateImage(800, 600, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, fi(0)\image\width, fi(0)\image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
*fractal = cvCreateImage(fi(0)\image\width, fi(0)\image\height, #IPL_DEPTH_8U, 3)
cvInitFont(@nFont, #CV_FONT_HERSHEY_SIMPLEX, 1, 1, #Null, 1, #CV_AA)
fi(0)\xMax = 2.5 : fi(0)\xMin = -2.5 : fi(0)\yMax = 2.5 : fi(0)\yMin = -2.5
pt1\x = -1 : pt1\y = -1 : pt2\x = -1 : pt2\y = -1
InitColor() : DrawPicture()
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If fi(iCount)\image
    cvShowImage(#CV_WINDOW_NAME, fi(iCount)\image)
    keyPressed = cvWaitKey(0)

    Select keyPressed
      Case 13
        iCount = 0 : ReDim fi(1)

        If fi(0)\nFractal
          cvPutText(fi(iCount)\image, "Working...", 22, 42, @nFont, 0, 0, 0, 0)
          cvPutText(fi(iCount)\image, "Working...", 20, 40, @nFont, 255, 255, 255, 0)
          cvShowImage(#CV_WINDOW_NAME, fi(iCount)\image)
          cvWaitKey(1)
          fi(0)\nFractal = 0
          DrawPicture()
        EndIf
      Case 32
        cvPutText(fi(iCount)\image, "Working...", 22, 42, @nFont, 0, 0, 0, 0)
        cvPutText(fi(iCount)\image, "Working...", 20, 40, @nFont, 255, 255, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, fi(iCount)\image)
        cvWaitKey(1)
        fi(iCount)\nFractal ! #True
        DrawPicture()
      Case 80, 112
        If iCount > 0
          iCount = ArraySize(fi()) - 2
          ReDim fi(iCount + 1)
        EndIf
    EndSelect
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*fractal)

For rtnCount = iCount To 0 Step -1
  cvReleaseImage(@fi(rtnCount)\image)
Next
cvDestroyAllWindows()
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 3
; FirstLine = 2
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\