IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, *flow.IplImage, pt.CvPoint2D32f, add_remove

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Sparse optical flow technique using the Lucas-Kanade algorithm." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Add / Remove tracking dots." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Default tracking dots." + #LF$ +
                  "ENTER       " + #TAB$ + ": Clear all tracking dots." + #LF$ + #LF$ +
                  "[ N ] KEY   " + #TAB$ + ": Enter / Exit Night-Mode." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage to a demonstration video."

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
    Case #CV_EVENT_LBUTTONDOWN
      If *flow
        pt\x = x
        pt\y = y
        add_remove = #True
      EndIf
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://www.youtube.com/watch?v=7saI-51zPYc")
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
  *flow = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *prev.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *curr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *eig_image.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 1)
  *temp_image.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 1)
  *prev_pyr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *curr_pyr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *swap_image.IplImage
  #NUM_FEATURES = 500
  Dim prev_features.CvPoint2D32f(#NUM_FEATURES)
  Dim curr_features.CvPoint2D32f(#NUM_FEATURES)
  Dim swap_features.CvPoint2D32f(#NUM_FEATURES)
  Dim status.b(#NUM_FEATURES)
  Dim error.f(#NUM_FEATURES)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCopy(*image, *flow, #Null)
      cvCvtColor(*flow, *curr, #CV_BGR2GRAY, 1)

      If night_mode : cvSetZero(*flow) : EndIf

      If feature_init
        feature_count = #NUM_FEATURES
        cvGoodFeaturesToTrack(*curr, *eig_image, *temp_image, curr_features(), @feature_count, 0.01, 10, #Null, 3, 0, 0.04)
        cvFindCornerSubPix(*curr, curr_features(), feature_count, 11, 11, -1, -1, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03)
        add_remove = #False
      ElseIf feature_count > 0
        cvCalcOpticalFlowPyrLK(*prev, *curr, *prev_pyr, *curr_pyr, prev_features(), curr_features(), feature_count, 31, 31, 3, status(), error(), #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03, flags)
        flags = #CV_LKFLOW_PYR_A_READY
        rtnPoint = 0

        For rtnCount = 0 To feature_count - 1
          If add_remove
            dx.d = pt\x - curr_features(rtnCount)\x
            dy.d = pt\y - curr_features(rtnCount)\y

            If dx * dx + dy * dy <= 5
              add_remove = #False
              Continue
            EndIf
          EndIf

          If Not status(rtnCount) : Continue : EndIf

          rtnPoint + 1
          curr_features(rtnPoint - 1) = curr_features(rtnCount)
          cvCircle(*flow, curr_features(rtnCount)\x, curr_features(rtnCount)\y, 3, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
        Next
        feature_count = rtnPoint
      EndIf

      If add_remove And feature_count < #NUM_FEATURES
        feature_count + 1
        curr_features(feature_count - 1)\x = pt\x
        curr_features(feature_count - 1)\y = pt\y
        cvFindCornerSubPix(*curr, curr_features() + feature_count - 1, 0, 31, 31, -1, -1, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03)
        add_remove = #False
      EndIf
      CV_SWAP(*prev, *curr, *swap_image)
      CV_SWAP(*prev_pyr, *curr_pyr, *swap_image)
      CopyArray(prev_features(), swap_features())
      CopyArray(curr_features(), prev_features())
      CopyArray(swap_features(), curr_features())
      feature_init = #False
      cvShowImage(#CV_WINDOW_NAME, *flow)
      keyPressed = cvWaitKey(10)

      Select keyPressed
        Case 13
          feature_count = 0
        Case 32
          feature_init ! #True
        Case 78, 110
          night_mode ! #True
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*curr_pyr)
  cvReleaseImage(@*prev_pyr)
  cvReleaseImage(@*temp_image)
  cvReleaseImage(@*eig_image)
  cvReleaseImage(@*curr)
  cvReleaseImage(@*prev)
  cvReleaseImage(@*flow)
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