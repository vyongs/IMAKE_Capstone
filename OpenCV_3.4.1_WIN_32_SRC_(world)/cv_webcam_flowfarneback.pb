IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Dense optical flow technique using the Gunnar Farneback algorithm."

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

Procedure DrawOptFlowMap(*flow.CvMat, *flowmap.CvMat, scale.d, B, G, R)
  *fxy.CvPoint2D32f

  For y = 16 To *flowmap\rows - 16 Step 16
    For x = 16 To *flowmap\cols - 16 Step 16
      CV_MAT_ELEM(*flow, CvPoint2D32f, y, x, *fxy)
      cvLine(*flowmap, x, y, x + *fxy\x, y + *fxy\y, B, G, R, 0, 1, #CV_AA, #Null)
      cvCircle(*flowmap, x, y, 2, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
    Next
  Next
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
  *next.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *prev.CvMat = cvCreateMat(*next\rows, *next\cols, *next\type)
  *flow.CvMat = cvCreateMat(*next\rows, *next\cols, CV_MAKETYPE(#CV_32F, 2))
  *flowmap.CvMat = cvCreateMat(*next\rows, *next\cols, CV_MAKETYPE(#CV_8U, 3))
  *swap_mat.CvMat
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCvtColor(*image, *next, #CV_BGR2GRAY, 1)

      If *prev\ptr\b
        cvCalcOpticalFlowFarneback(*prev, *next, *flow, 0.5, 3, 10, 3, 5, 1.1, #OPTFLOW_FARNEBACK_GAUSSIAN)
        cvCvtColor(*prev, *flowmap, #CV_GRAY2BGR, 1)
        DrawOptFlowMap(*flow, *flowmap, 1.5, 0, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *flowmap)
      EndIf
      keyPressed = cvWaitKey(10)
      CV_SWAP(*prev, *next, *swap_mat)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMat(@*flowmap)
  cvReleaseMat(@*flow)
  cvReleaseMat(@*prev)
  cvReleaseMat(@*next)
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