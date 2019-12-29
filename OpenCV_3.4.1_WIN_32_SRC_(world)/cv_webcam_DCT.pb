IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Performs a discrete cosine transform of a 1D array, displaying its power spectrum."

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

  If FrameWidth % 2 = 0 : width = FrameWidth : Else : width = FrameWidth + 1 : EndIf
  If FrameHeight % 2 = 0 : height = FrameHeight : Else : height = FrameHeight + 1 : EndIf

  *gray.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *border.CvMat = cvCreateMat(height, width, CV_MAKETYPE(#CV_8U, 1))
  *dct.CvMat = cvCreateMat(height, width, CV_MAKETYPE(#CV_64F, 1))
  *frequency1.CvMat = cvCreateMat(height, width, CV_MAKETYPE(#CV_64F, 1))
  *frequency2.CvMat = cvCreateMat(height, width, CV_MAKETYPE(#CV_8U, 1))
  *big.CvMat = cvCreateMat(height, width * 2, CV_MAKETYPE(#CV_8U, 1))
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
      cvCopyMakeBorder(*gray, *border, height - FrameHeight, width - FrameWidth, #IPL_BORDER_REPLICATE, 0, 0, 0, 0)
      cvConvert(*border, *dct)
      cvDCT(*dct, *frequency1, #DCT_FORWARD)
      cvAbs(*frequency1, *frequency1)
      cvLog(*frequency1, *frequency1)
      cvNormalize(*frequency1, *frequency1, 0, 255, #NORM_MINMAX, #Null)
      cvConvert(*frequency1, *frequency2)
      *roi1 = cvGetSubRect(*big, @roi1, 0, 0, width, height)
      cvCopy(*border, *roi1, #Null)
      *roi2 = cvGetSubRect(*big, @roi2, width, 0, width, height)
      cvCopy(*frequency2, *roi2, #Null)
      cvShowImage(#CV_WINDOW_NAME, *big)
      keyPressed = cvWaitKey(1)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMat(@*big)
  cvReleaseMat(@*frequency2)
  cvReleaseMat(@*frequency1)
  cvReleaseMat(@*dct)
  cvReleaseMat(@*border)
  cvReleaseMat(@*gray)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\