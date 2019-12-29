IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Parametric Curve: A curve defined as a function of independent variables." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust parameter." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Predefined settings." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("https://en.wikipedia.org/w/index.php?title=Parametric_equation")
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_RETURN, 0, 0, 0)
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
*image.CvMat = cvCreateMat(500, 500, CV_MAKETYPE(#CV_8U, 3))
cvResizeWindow(#CV_WINDOW_NAME, *image\cols, *image\rows)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvCreateTrackbar("Parameter", #CV_WINDOW_NAME, @nParameter, 4, @CvTrackbarCallback())
font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.6, 0.6, 0, 1, #CV_AA)
Dim k.f(16)
k(0) = 0.25 : k(1) = 0.33 : k(2) = 0.5 : k(3) = 0.65 : k(4) = 0.7 : k(5) = 1.3 : k(6) = 1.4 : k(7) = 1.6
k(8) = 1.7 : k(9) = 1.8 : k(10) = 1.9 : k(11) = 2.5 : k(12) = 3 : k(13) = 4 : k(14) = 5 : k(15) = 6
Dim a.f(16)
a(0) = 20 : a(1) = 30 : a(2) = 55 : a(3) = 70 : a(4) = 75

For rtcount = 5 To 15
  a(rtcount) = 150
Next
centerX.f = 256
centerY.f = 256
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvSetZero(*image)
    b.f = a(count) / k(count)
    oldpX = (a(count) - b) * Cos(0) + b * Cos(0 * ((a(count) / b) - 1) * (nParameter + 1)) + centerX - 1
    oldpY = (a(count) - b) * Sin(0) - b * Sin(0 * ((a(count) / b) - 1) * (nParameter + 1)) + centerY - 1
    t.f = 0 : stepSize.f = 0.01
    nB = Random(255) : nG = Random(255) : nR = Random(255)
    nPixels = 0 : nIterations = 0

    Repeat
      pX = (a(count) - b) * Cos(t) + b * Cos(t * ((a(count) / b) - 1) * (nParameter + 1)) + centerX
      pY = (a(count) - b) * Sin(t) - b * Sin(t * ((a(count) / b) - 1) * (nParameter + 1)) + centerY

      If pX <> oldpX Or pY <> oldpY
        If Abs(oldpX - pX) <= 1 And Abs(oldpY - pY) <= 1
          If PeekA(@*image\ptr\b + pY * *image\Step + pX * 3 + 0) = 0 And
             PeekA(@*image\ptr\b + pY * *image\Step + pX * 3 + 1) = 0 And
             PeekA(@*image\ptr\b + pY * *image\Step + pX * 3 + 2) = 0
            PokeA(@*image\ptr\b + pY * *image\Step + pX * 3 + 0, nB)
            PokeA(@*image\ptr\b + pY * *image\Step + pX * 3 + 1, nG)
            PokeA(@*image\ptr\b + pY * *image\Step + pX * 3 + 2, nR)
            nPixels + 1
          EndIf
          oldpX = pX
          oldpY = pY
        Else
          t - stepSize
          stepSize / 2
        EndIf
      Else
       stepSize + stepSize / 2
      EndIf
      t + stepSize
      nIterations + 1
    Until t >= 50 * #PI
    cvPutText(*image, "Pixel Count: " + Str(nPixels), 10, 30, @font, 255, 255, 255, 0)
    cvPutText(*image, "Iterations: " + Str(nIterations), 10, 60, @font, 255, 255, 255, 0)
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)

    If keyPressed = 32
      If count = ArraySize(k()) - 1 : count = 0 : Else : count + 1 : EndIf
    EndIf
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMat(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\