IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, centerX.f, centerY.f

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Pixel manipulation through direct memory access, demonstrating two webcam effects." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Move the fisheye X / Y axis." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle fisheye / mirror."

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
    Case #CV_EVENT_LBUTTONUP
      centerX = x
      centerY = y
  EndSelect
EndProcedure

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
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  centerX = FrameWidth / 2 : centerY = FrameHeight / 2
  halfFrame = FrameWidth / 2
  frameBytes = FrameWidth * 3 - 1
  *fisheye.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If camStuff
        For i = 0 To FrameHeight - 1
          offset = i * FrameWidth * 3

          For j = 0 To halfFrame - 1
            jBytes = offset + frameBytes - (j * 3)
            ojBytes = offset + (j * 3)
            PokeA(@*image\imageData\b + jBytes - 2, PeekA(@*image\imageData\b + ojBytes))
            PokeA(@*image\imageData\b + jBytes - 1, PeekA(@*image\imageData\b + ojBytes + 1))
            PokeA(@*image\imageData\b + jBytes, PeekA(@*image\imageData\b + ojBytes + 2))
          Next
        Next
        cvShowImage(#CV_WINDOW_NAME, *image)
      Else
        For y = 0 To FrameHeight - 1
          For x = 0 To FrameWidth - 1
            rp.d = Sqr(140 * 140 + Pow((x - centerX), 2) + Pow(y - centerY, 2))
            vx = rp * (x - FrameWidth / 2) / FrameWidth + FrameWidth / 2
            vy = rp * (y - FrameHeight / 2) / FrameWidth + FrameHeight / 2

            If vx >= 0 And vx < FrameWidth And vy >= 0 And vy < FrameHeight
              PokeA(@*fisheye\imageData\b + *fisheye\widthStep * y + x * 3 + 0, PeekA(@*image\imageData\b + *image\widthStep * vy + vx * 3 + 0))
              PokeA(@*fisheye\imageData\b + *fisheye\widthStep * y + x * 3 + 1, PeekA(@*image\imageData\b + *image\widthStep * vy + vx * 3 + 1))
              PokeA(@*fisheye\imageData\b + *fisheye\widthStep * y + x * 3 + 2, PeekA(@*image\imageData\b + *image\widthStep * vy + vx * 3 + 2))
      			EndIf
          Next
        Next
        cvShowImage(#CV_WINDOW_NAME, *fisheye)
      EndIf
      keyPressed = cvWaitKey(10)

      If keyPressed = 32
        camStuff ! #True
        centerX = FrameWidth / 2
        centerY = FrameHeight / 2
      EndIf
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*fisheye)
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