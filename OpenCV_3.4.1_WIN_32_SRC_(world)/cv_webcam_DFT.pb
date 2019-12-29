IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Performs a discrete Fourier transform of a 1D floating-point array, displaying its power spectrum."

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
  M = cvGetOptimalDFTSize(FrameHeight)
  N = cvGetOptimalDFTSize(FrameWidth)
  cx = FrameWidth / 2
  cy = FrameHeight / 2
  *gray.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *border.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  Dim *planes.CvMat(2)
  *planes(0) = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  *planes(1) = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  *complex.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 2))
  *magnitude1.CvMat : magnitude.CvMat
  *magnitude2.CvMat = cvCreateMat(FrameHeight & -2, FrameWidth & -2, CV_MAKETYPE(#CV_8U, 1))
  *temp.CvMat = cvCreateMat(cy, cx, CV_MAKETYPE(#CV_32F, 1))
  *q0.CvMat : *q1.CvMat : *q2.CvMat : *q3.CvMat : q0.CvMat : q1.CvMat : q2.CvMat : q3.CvMat
  *big.CvMat = cvCreateMat(FrameHeight, FrameWidth * 2, CV_MAKETYPE(#CV_8U, 1))
  *roi1.CvMat : *roi2.CvMat : roi1.CvMat : roi2.CvMat
  *image.CvMat
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCvtColor(*image, *gray, #CV_RGB2GRAY, 1)
      cvCopyMakeBorder(*gray, *border, M - FrameHeight, N - FrameWidth, #IPL_BORDER_REPLICATE, 0, 0, 0, 0)
      cvConvertScale(*border, *planes(0), 1, 0)
      cvSetZero(*planes(1))
      cvMerge(*planes(0), *planes(1), #Null, #Null, *complex)
      cvDFT(*complex, *complex, #CV_DXT_FORWARD, 0)
      cvSplit(*complex, *planes(0), *planes(1), #Null, #Null)
      cvCartToPolar(*planes(0), *planes(1), *planes(0), #Null, #False)
      *magnitude1 = *planes(0)
      cvAbs(*magnitude1, *magnitude1)
      cvLog(*magnitude1, *magnitude1)
      *magnitude1 = cvGetSubRect(*magnitude1, @magnitude, 0, 0, FrameWidth & -2, FrameHeight & -2)
      *q0 = cvGetSubRect(*magnitude1, @q0, 0, 0, cx, cy)
      *q1 = cvGetSubRect(*magnitude1, @q1, cx, 0, cx, cy)
      *q2 = cvGetSubRect(*magnitude1, @q2, 0, cy, cx, cy)
      *q3 = cvGetSubRect(*magnitude1, @q3, cx, cy, cx, cy)
      cvCopy(*q0, *temp, #Null)
      cvCopy(*q3, *q0, #Null)
      cvCopy(*temp, *q3, #Null)
      cvCopy(*q1, *temp, #Null)
      cvCopy(*q2, *q1, #Null)
      cvCopy(*temp, *q2, #Null)
      cvNormalize(*magnitude1, *magnitude1, 0, 255, #NORM_MINMAX, #Null)
      cvConvert(*magnitude1, *magnitude2)
      *roi1 = cvGetSubRect(*big, @roi1, 0, 0, FrameWidth, FrameHeight)
      cvCopy(*border, *roi1, #Null)
      *roi2 = cvGetSubRect(*big, @roi2, FrameWidth, 0, FrameWidth, FrameHeight)
      cvCopy(*magnitude2, *roi2, #Null)
      cvShowImage(#CV_WINDOW_NAME, *big)
      keyPressed = cvWaitKey(1)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMat(@*big)
  cvReleaseMat(@*temp)
  cvReleaseMat(@*magnitude2)
  cvReleaseMat(@*complex)
  cvReleaseMat(@*planes(1))
  cvReleaseMat(@*planes(0))
  cvReleaseMat(@*border)
  cvReleaseMat(@*gray)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\