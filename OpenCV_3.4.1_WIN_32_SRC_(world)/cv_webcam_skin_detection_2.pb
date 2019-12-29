IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Detect skin tones using the HSV (Hue, Saturation and Value) color space." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle skin mode." + #LF$ + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Toggle smooth filters."

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
  *temp.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *hsv.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *H.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *S.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *V.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *H1.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *S1.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *H2.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *S2.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *H3.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *S3.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *mask.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *skin.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvSmooth(*image, *temp, #CV_GAUSSIAN, 3, 3, 0, 0)
      cvCvtColor(*temp, *hsv, #CV_BGR2HSV, 1)
      cvSplit(*hsv, *H, *S, *V, #Null)
      cvInRangeS(*H, 0, 0, 0, 0, 20, 0, 0, 0, *H1)
      cvInRangeS(*S, 75, 0, 0, 0, 200, 0, 0, 0, *S1)
      cvAnd(*H1, *S1, *H1, #Null)
      cvInRangeS(*H, 0, 0, 0, 0, 13, 0, 0, 0, *H2)
      cvInRangeS(*S, 20, 0, 0, 0, 90, 0, 0, 0, *S2)
      cvAnd(*H2, *S2, *H2, #Null)
      cvInRangeS(*H, 170, 0, 0, 0, 179, 0, 0, 0, *H3)
      cvInRangeS(*S, 15, 0, 0, 0, 90, 0, 0, 0, *S3)
      cvAnd(*H3, *S3, *H3, #Null)
      cvOr(*H3, *H2, *H2, #Null)
      cvOr(*H1, *H2, *H1, #Null)
      cvCopy(*H1, *mask, #Null)

      If smooth
        cvErode(*mask, *mask, *kernel, 1)
        cvDilate(*mask, *mask, *kernel, 1)
        cvSmooth(*mask, *mask, #CV_GAUSSIAN, 21, 0, 0, 0)
        cvThreshold(*mask, *mask, 130, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
      EndIf

      If skin
        cvSetZero(*skin)
        cvCopy(*image, *skin, *mask)
        cvShowImage(#CV_WINDOW_NAME, *skin)
      Else
        cvShowImage(#CV_WINDOW_NAME, *mask)
      EndIf
      keyPressed = cvWaitKey(10)

      Select keyPressed
        Case 32
          skin ! #True
        Case 83, 115
          smooth ! #True
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*skin)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*S3)
  cvReleaseImage(@*H3)
  cvReleaseImage(@*S2)
  cvReleaseImage(@*H2)
  cvReleaseImage(@*S1)
  cvReleaseImage(@*H1)
  cvReleaseImage(@*V)
  cvReleaseImage(@*S)
  cvReleaseImage(@*H)
  cvReleaseImage(@*hsv)
  cvReleaseImage(@*temp)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\