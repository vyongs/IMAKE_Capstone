IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Gradients of motion history are used to detect direction of motion.  Using thresholded layer gradients of decaying frame differencing, " +
                  "new movements are stamped on top of each other by time code; motions too old are thresholded away."

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

#MHI_DURATION = 1
#MAX_TIME_DELTA = 0.5
#MIN_TIME_DELTA = 0.05
#CLOCKS_PER_SEC = 1000
Global nCount = 4, last = 0
Global Dim *buf.IplImage(nCount)
Global StartTime = ElapsedMilliseconds()
Global *mhi.IplImage, *mask.IplImage, *orient.IplImage, *segmask.IplImage
Global *storage.CvMemStorage

Procedure UpdateMHI(*image.IplImage, *motion.IplImage, threshold)
  idx1 = last
  timestamp.d = (ElapsedMilliseconds() - StartTime) / #CLOCKS_PER_SEC

  If Not *mhi Or *mhi\width <> *image\width Or *mhi\height <> *image\height
    For rtnCount = 0 To nCount - 1
      cvReleaseImage(@*buf(rtnCount))
      *buf(rtnCount) = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 1)
      cvSetZero(*buf(rtnCount))
    Next
    cvReleaseImage(@*mhi)
    cvReleaseImage(@*mask)
    cvReleaseImage(@*orient)
    cvReleaseImage(@*segmask)
    *mhi = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_32F, 1)
    cvSetZero(*mhi)
    *mask = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 1)
    *orient = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_32F, 1)
    *segmask = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_32F, 1)
  EndIf
  cvCvtColor(*image, *buf(last), #CV_BGR2GRAY, 1)
  idx2 = (last + 1) % nCount
  last = idx2
  *silh.IplImage = *buf(idx2)
  cvAbsDiff(*buf(idx1), *buf(idx2), *silh)
  cvThreshold(*silh, *silh, threshold, 1, #CV_THRESH_BINARY)
  cvUpdateMotionHistory(*silh, *mhi, timestamp, #MHI_DURATION)
  cvConvertScale(*mhi, *mask, 255 / #MHI_DURATION, (#MHI_DURATION - timestamp) * 255 / #MHI_DURATION)
  cvSetZero(*motion)
  cvMerge(*mask, #Null, #Null, #Null, *motion)
  cvCalcMotionGradient(*mhi, *mask, *orient, #MAX_TIME_DELTA, #MIN_TIME_DELTA, 3)

  If Not *storage : *storage = cvCreateMemStorage(0) : Else : cvClearMemStorage(*storage) : EndIf

  *seq.CvSeq = cvSegmentMotion(*mhi, *segmask, *storage, timestamp, #MAX_TIME_DELTA)
  comp_rect.CvRect : *comp_test.CvConnectedComp

  For rtnCount = -1 To *seq\total - 1
    If rtnCount < 0
      comp_rect\x = 0
      comp_rect\y = 0
      comp_rect\width = *image\width
      comp_rect\height = *image\height
      B = 255
      G = 255
      R = 255
      magnitude.d = 100
    Else
      *comp_test = cvGetSeqElem(*seq, rtnCount)
      comp_rect\x = *comp_test\rect\x
      comp_rect\y = *comp_test\rect\y
      comp_rect\width = *comp_test\rect\width
      comp_rect\height = *comp_test\rect\height

      If comp_rect\width + comp_rect\height < 100 : Continue : EndIf

      B = 0
      G = 0
      R = 255
      magnitude.d = 30
    EndIf
    cvSetImageROI(*orient, comp_rect\x, comp_rect\y, comp_rect\width, comp_rect\height)
    cvSetImageROI(*mask, comp_rect\x, comp_rect\y, comp_rect\width, comp_rect\height)
    cvSetImageROI(*mhi, comp_rect\x, comp_rect\y, comp_rect\width, comp_rect\height)
    cvSetImageROI(*silh, comp_rect\x, comp_rect\y, comp_rect\width, comp_rect\height)
    angle.d = cvCalcGlobalOrientation(*orient, *mask, *mhi, timestamp, #MHI_DURATION)
    angle = 360 - angle
    count.d = cvNorm(*silh, #Null, #CV_L1, #Null)
    cvResetImageROI(*silh)
    cvResetImageROI(*mhi)
    cvResetImageROI(*mask)
    cvResetImageROI(*orient)

    If count < comp_rect\width * comp_rect\height * 0.05 : Continue : EndIf

    x1 = Round(comp_rect\x + comp_rect\width / 2, #PB_Round_Nearest)
    y1 = Round(comp_rect\y + comp_rect\height / 2, #PB_Round_Nearest)
    radius.d = Round(magnitude * 1.2, #PB_Round_Nearest)
    x2 = Round(x1 + magnitude * Cos(angle * #PI / 180), #PB_Round_Nearest)
    y2 = Round(y1 - magnitude * Sin(angle * #PI / 180), #PB_Round_Nearest)
    cvCircle(*motion, x1, y1, radius, B, G, R, 0, 3, #CV_AA, #Null)
    cvLine(*motion, x1, y1, x2, y2, B, G, R, 0, 3, #CV_AA, #Null)
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
  *motion.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  cvSetZero(*motion)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      UpdateMHI(*image, *motion, 30)
      cvShowImage(#CV_WINDOW_NAME, *motion)
      keyPressed = cvWaitKey(10)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseImage(@*segmask)
  cvReleaseImage(@*orient)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*mhi)

  For rtnCount = 0 To nCount - 1
    cvReleaseImage(@*buf(rtnCount))
  Next
  cvReleaseImage(@*motion)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS beta 3 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\