IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Detect skin tones using the YUV (Luma [Y] and Chroma [UV]) color space." + #LF$ + #LF$ +
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
  total = FrameWidth * FrameHeight
  *YUV.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *Y.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *U.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *V.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
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
      cvCvtColor(*image, *YUV, #CV_BGR2YUV, 1)
      cvSplit(*YUV, *Y, *U, *V, #Null)
      cvSetZero(*mask)

      For rtnCount = 0 To total - 1
        nY = PeekA(@*Y\imageData\b + rtnCount)
        nU = PeekA(@*U\imageData\b + rtnCount) - 152
        nV = PeekA(@*V\imageData\b + rtnCount) - 109
        x1 = (819 * nU - 614 * nV) / 32 + 51
        y1 = (819 * nU + 614 * nV) / 32 + 77
        x1 * 41 / 1024
        y1 * 73 / 1024
        value = x1 * x1 + y1 * y1

        If nY < 0
          If value < 700 : PokeA(@*mask\imageData\b + rtnCount, 255) : Else : PokeA(@*mask\imageData\b + rtnCount, 0) : EndIf
        Else
          If value < 850 : PokeA(@*mask\imageData\b + rtnCount, 255) : Else : PokeA(@*mask\imageData\b + rtnCount, 0) : EndIf
        EndIf
      Next

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
  cvReleaseImage(@*V)
  cvReleaseImage(@*U)
  cvReleaseImage(@*Y)
  cvReleaseImage(@*YUV)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.31 Beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\