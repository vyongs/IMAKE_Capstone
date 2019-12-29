IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Sparse optical flow technique using the Lucas-Kanade algorithm." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle good features."

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
  *flow.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *hsv.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *prev.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *curr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *eig_image.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *temp_image.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *prev_pyr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *curr_pyr.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  #NUM_FEATURES = 400
  #MIN_VECT_COMP = 2000
  Dim prev_features.CvPoint2D32f(#NUM_FEATURES)
  Dim curr_features.CvPoint2D32f(#NUM_FEATURES)
  Dim status.b(#NUM_FEATURES)
  Dim error.f(#NUM_FEATURES)
  good = 1
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvConvertImage(*image, *flow, #CV_CVTIMG_DEFAULT)
      cvCvtColor(*image, *hsv, #CV_BGR2HSV, 1)
   		cvInRangeS(*hsv, 0, 30, 80, 0, 50, 100, 255, 0, *prev)
   		cvSet(*hsv, 0, 0, 0, 0, #Null)
   		cvCopy(*image, *hsv, *prev)
   		cvConvertImage(*hsv, *prev, #CV_CVTIMG_DEFAULT)
      *image = cvQueryFrame(*capture)

      If *image
        cvFlip(*image, #Null, 1)
        cvCvtColor(*image, *hsv, #CV_BGR2HSV, 1)
    		cvInRangeS(*hsv, 0, 30, 80, 0, 50, 100, 255, 0, *curr)
    		cvSet(*hsv, 0, 0, 0, 0, #Null)
    		cvCopy(*image, *hsv, *curr)
    		cvConvertImage(*hsv, *curr, #CV_CVTIMG_DEFAULT)
    		feature_count = #NUM_FEATURES
    		cvGoodFeaturesToTrack(*prev, *eig_image, *temp_image, prev_features(), @feature_count, 0.05, 0.001, #Null, 3, 0, 0.04)
        cvCalcOpticalFlowPyrLK(*prev, *curr, *prev_pyr, *curr_pyr, prev_features(), curr_features(), feature_count, 3, 3, 5, status(), error(), #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.1, 0)

        For rtnCount = 0 To feature_count - 1
          If status(rtnCount) = 1
            x1 = prev_features(rtnCount)\x
            y1 = prev_features(rtnCount)\y
            x2 = curr_features(rtnCount)\x
            y2 = curr_features(rtnCount)\y
            hypotenuse.d = Sqr((y1 - y2) * (y1 - y2) + (x1 - x2) * (x1 - x2))

            If hypotenuse >= 10 And hypotenuse <= 100
              If good
                cvCircle(*flow, x1, y1, 2, 0, 0, 255, 0, 1, #CV_AA, #Null)
  			        cvCircle(*flow, x2, y2, 2, 255, 0, 0, 0, 1, #CV_AA, #Null)
  			        cvLine(*flow, x1, y1, x2, y2, 0, 255, 0, 0, 1, #CV_AA, #Null)
  			      EndIf
        			xt.d + (x1 - x2)
        			yt.d + (y1 - y2)
        		EndIf
          EndIf
        Next
        x1 = FrameWidth / 2
        y1 = FrameHeight / 2
        x2 = x1 + xt
        y2 = y1 + yt
        hypotenuse = Sqr(yt * yt + xt * xt)
        angle.d = ATan2(xt, yt)
        x2 = x1 - hypotenuse * Cos(angle)
        y2 = y1 - hypotenuse * Sin(angle)
        cvLine(*flow, x1, y1, x2, y2, 255, 0, 0, 0, 1, #CV_AA, #Null)

        If Abs(xt) > #MIN_VECT_COMP
          If xt > 0 : xt = -50 : Else : xt = 50 : EndIf
        Else
          xt = 0
        EndIf

        If Abs(yt) > #MIN_VECT_COMP
          If yt > 0 : yt = -50 : Else : yt = 50 : EndIf
        Else
          yt = 0
        EndIf
        x2 = x1 + xt
        y2 = y1 + yt
        cvLine(*flow, x1, y1, x2, y2, 0, 255, 255, 0, 2, #CV_AA, #Null)
        x1 = x2 + 9 * Cos(angle + #PI / 4)
        y1 = y2 + 9 * Sin(angle + #PI / 4)
        cvLine(*flow, x1, y1, x2, y2, 0, 255, 255, 0, 2, #CV_AA, #Null)
        x1 = x2 + 9 * Cos(angle - #PI / 4)
        y1 = y2 + 9 * Sin(angle - #PI / 4)
        cvLine(*flow, x1, y1, x2, y2, 0, 255, 255, 0, 2, #CV_AA, #Null)
        cvShowImage(#CV_WINDOW_NAME, *flow)
        keyPressed = cvWaitKey(10)

        If keyPressed = 32 : good ! #True : EndIf

      EndIf
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*curr_pyr)
  cvReleaseImage(@*prev_pyr)
  cvReleaseImage(@*temp_image)
  cvReleaseImage(@*eig_image)
  cvReleaseImage(@*curr)
  cvReleaseImage(@*prev)
  cvReleaseImage(@*hsv)
  cvReleaseImage(@*flow)
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