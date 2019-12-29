IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, *image.IplImage, nFont.CvFont, nActivate

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Fractal Art: Created by calculating fractal objects represented as images." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust Real part." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust Imaginary part." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Predefined settings."

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

Global nMax = 255, rMax.d = 20, nCR, nCI

Procedure GetNumber(i, j)
  cRealPart.d = (nCR - 50) / 100 * 2 * 2
  cImaginaryPart.d = (nCI - 50) / 100 * 2 * 2
  RealPart.d = i / *image\width
  ImaginaryPart.d = j / *image\height

  While n < nMax
    ZM.d = RealPart * RealPart + ImaginaryPart * ImaginaryPart

    If ZM > rMax : Break : EndIf

    tRealPart.d = RealPart * RealPart - ImaginaryPart * ImaginaryPart + cRealPart
    tImaginaryPart.d = 2 * ImaginaryPart * RealPart + cImaginaryPart
    RealPart = tRealPart
		ImaginaryPart = tImaginaryPart
		n + 1
	Wend
	ProcedureReturn n
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  If nActivate
    cvPutText(*image, "Working...", 22, 42, @nFont, 0, 0, 0, 0)
    cvPutText(*image, "Working...", 20, 40, @nFont, 255, 255, 255, 0)
    cvShowImage(#CV_WINDOW_NAME, *image)
    StartTime = ElapsedMilliseconds()

    Repeat
      ElapsedTime = ElapsedMilliseconds() - StartTime

      If ElapsedTime > 1000
        cvSetZero(*image)
        scalar1.CvScalar
        scalar2.CvScalar

        For i = 0 To *image\height - 1
          For j = 0 To *image\width - 1
            n1 = GetNumber(i, j)
      			n2 = GetNumber(j, i)
      			n3 = GetNumber(j, i / 2)

      			If n1 > nMax - 2 : n1 = 0 : EndIf
      			If n2 > nMax - 2 : n2 = 0 : EndIf
      			If n3 > nMax - 2 : n3 = 0 : EndIf

      			scalar1\val[0] = Abs(255 * n1 / nMax)
      			scalar1\val[1] = Abs(255 * n2 / nMax)
      			scalar1\val[2] = Abs(255 * n3 / nMax)
      			cvSet2D(*image, i, j, scalar1\val[0], scalar1\val[1], scalar1\val[2], 0)
          Next
        Next
        nValue.d = cvNorm(*image, 0, #CV_C, #Null)

        For i = 0 To *image\height - 1
          For j = 0 To *image\width - 1
            cvGet2D(@scalar2, *image, i, j)
            scalar1\val[0] = Abs(255 * scalar2\val[0] / nValue)
      			scalar1\val[1] = Abs(255 * scalar2\val[1] / nValue)
      			scalar1\val[2] = Abs(255 * scalar2\val[2] / nValue)
      			cvSet2D(*image, i, j, scalar1\val[0], scalar1\val[1], scalar1\val[2], 0)
          Next
        Next
        cvShowImage(#CV_WINDOW_NAME, *image)
        nActivate = #True
      Else
        nActivate = #False
        cvShowImage(#CV_WINDOW_NAME, *image)
        cvWaitKey(100)
      EndIf
    Until ElapsedTime > 1000
  EndIf
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
*image = cvCreateImage(700, 500, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvCreateTrackbar("Real", #CV_WINDOW_NAME, @nCR, 100, @CvTrackbarCallback())
cvCreateTrackbar("Imaginary", #CV_WINDOW_NAME, @nCI, 100, @CvTrackbarCallback())
cvInitFont(@nFont, #CV_FONT_HERSHEY_SIMPLEX, 1, 1, #Null, 1, #CV_AA)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    Select fractal
      Case 0
        nCR = 30 : nCI = 45
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 1
        nCR = 38 : nCI = 35
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 2
        nCR = 38 : nCI = 36
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 3
        nCR = 40 : nCI = 24
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 4
        nCR = 46 : nCI = 29
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 5
        nCR = 48 : nCI = 34
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 6
        nCR = 50 : nCI = 30
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 7
        nCR = 53 : nCI = 63
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 8
        nCR = 59 : nCI = 51
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
      Case 9
        nCR = 59 : nCI = 52
        nActivate = #False
        cvSetTrackbarPos("Real", #CV_WINDOW_NAME, nCR)
        cvSetTrackbarPos("Imaginary", #CV_WINDOW_NAME, nCI)
        nActivate = #True
        CvTrackbarCallback(0)
    EndSelect
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)

    If keyPressed = 32 : fractal = (fractal + 1) % 10 : EndIf

  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\