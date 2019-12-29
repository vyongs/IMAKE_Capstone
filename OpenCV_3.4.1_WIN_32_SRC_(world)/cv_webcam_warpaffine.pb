IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, Dim srcPoint.CvPoint2D32f(3), Dim dstPoint.CvPoint2D32f(3), nScale.d = 1

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Warp, stretch, rotate and resize a webcam stream." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust the angle." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust the scale."

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

ProcedureC CvTrackbarCallback2(pos)
  Select pos
    Case 0 : nScale = 1
    Case 1 : nScale = 0.9
    Case 2 : nScale = 0.8
    Case 3 : nScale = 0.7
    Case 4 : nScale = 0.6
    Case 5 : nScale = 0.5
    Case 6 : nScale = 0.4
    Case 7 : nScale = 0.3
    Case 8 : nScale = 0.2
    Case 9 : nScale = 0.1
  EndSelect
EndProcedure

Procedure SetDimensions(width, height)
  srcPoint(0)\x = 0
  srcPoint(0)\y = 0
  srcPoint(1)\x = width - 1
  srcPoint(1)\y = 0
  srcPoint(2)\x = 0
  srcPoint(2)\y = height - 1
  dstPoint(0)\x = width * 0.0
  dstPoint(0)\y = height * 0.35
  dstPoint(1)\x = width * 0.90
  dstPoint(1)\y = height * 0.15
  dstPoint(2)\x = width * 0.10
  dstPoint(2)\y = height * 0.75
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
  cvResizeWindow(#CV_WINDOW_NAME, FrameWidth, FrameHeight + 48 + 42)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  cvCreateTrackbar("Angle", #CV_WINDOW_NAME, @nAngle, 360, @CvTrackbarCallback1())
  cvCreateTrackbar("Scale", #CV_WINDOW_NAME, 0, 9, @CvTrackbarCallback2())
  *warp.CvMat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1))
  *rotate.CvMat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1))
  *matrix.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvSetZero(*matrix)
      SetDimensions(FrameWidth, FrameHeight)
      cvGetAffineTransform(@srcPoint(), @dstPoint(), *warp)
      cvWarpAffine(*image, *matrix, *warp, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 100, 100, 50, 0)
      cvCopy(*matrix, *image, #Null)
      cv2DRotationMatrix(FrameWidth / 2, FrameHeight / 2, nAngle, nScale, *rotate)
      cvWarpAffine(*image, *matrix, *rotate, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 100, 100, 50, 0)
      cvShowImage(#CV_WINDOW_NAME, *matrix)
      keyPressed = cvWaitKey(15)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMat(@*warp)
  cvReleaseMat(@*rotate)
  cvReleaseImage(@*matrix)
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