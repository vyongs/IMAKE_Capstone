IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Adds a glow effect to red objects." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust Blue value." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust Green value." + #LF$ +
                  "TRACKBAR 3  " + #TAB$ + ": Adjust Red value." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle white core."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos) : EndProcedure
ProcedureC CvTrackbarCallback2(pos) : EndProcedure
ProcedureC CvTrackbarCallback3(pos) : EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
Until nCreate = 99 Or *capture

If *capture
  cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
  window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
  *window_name = cvGetWindowName(window_handle)
  lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

  If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
    MenuItem(10, "Exit")
  EndIf
  hWnd = GetParent_(window_handle)
  iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
  SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
  wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
  SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)

  If FrameWidth > 640
    nRatio.d = 640 / FrameWidth
    FrameWidth * nRatio : FrameHeight * nRatio
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH, FrameWidth)
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight)
  EndIf
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
  cvResizeWindow(#CV_WINDOW_NAME, FrameWidth, FrameHeight + 48 + 42 + 84)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  nR = 120
  cvCreateTrackbar("Blue", #CV_WINDOW_NAME, @nB, 255, @CvTrackbarCallback1())
  cvCreateTrackbar("Green", #CV_WINDOW_NAME, @nG, 255, @CvTrackbarCallback2())
  cvCreateTrackbar("Red", #CV_WINDOW_NAME, @nR, 255, @CvTrackbarCallback3())
  *blur.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 3))
  *hsv.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 3))
  *output.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *copy1.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *copy2.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 3))
  *white.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 3))
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *image.CvMat
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvSmooth(*image, *blur, #CV_GAUSSIAN, 11, 11, 0, 0)
      cvCvtColor(*blur, *hsv, #CV_BGR2HSV, 1)
      cvInRangeS(*hsv, 160, 140, 40, 0, 179, 255, 255, 0, *output)
      cvSmooth(*output, *copy1, #CV_GAUSSIAN, 101, 101, 0, 0)
      cvCvtColor(*copy1, *copy2, #CV_GRAY2BGR, 1)
      cvCvtColor(*output, *white, #CV_GRAY2BGR, 1)
      cvDilate(*white, *white, *kernel, 1)
      cvErode(*white, *white, *kernel, 1)
      cvSmooth(*white, *white, #CV_GAUSSIAN, 21, 21, 0, 0)

      For i = 0 To FrameHeight - 1
        For j = 0 To FrameWidth - 1
          B.f = PeekA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 0)
          G.f = PeekA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 1)
          R.f = PeekA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 2)
          PokeA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 0, B / 255 * nB)
          PokeA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 1, G / 255 * nG)
          PokeA(@*copy2\ptr\b + i * *copy2\Step + j * 3 + 2, R / 255 * nR)
        Next
      Next
      cvMul(*copy2, *copy2, *copy2, 5)
      cvAdd(*image, *copy2, *image, #Null)

      If white : cvAdd(*image, *white, *image, #Null) : EndIf

      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(10)

      If keyPressed = 32 : white ! #True : EndIf

    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseMat(@*white)
  cvReleaseMat(@*copy2)
  cvReleaseMat(@*copy1)
  cvReleaseMat(@*output)
  cvReleaseMat(@*hsv)
  cvReleaseMat(@*blur)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\