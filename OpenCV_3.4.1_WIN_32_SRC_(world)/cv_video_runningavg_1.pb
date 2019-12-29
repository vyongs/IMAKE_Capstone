IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the weighted sum of the input image and the accumulator, used to detect moving objects of a certain size." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle foreground view." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

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
  *capture.CvCapture = cvCreateFileCapture("videos/walking.avi")
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
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  INIT_TIME = 50
  BG_RATIO.d = 0.02
  OBJ_RATIO.d = 0.005
  zeta.d = 10
  *imgAverage.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgSgm.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgTmp.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *img_lower.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *img_upper.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgSilhouette.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *imgResult.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  iRatio.d = 150 / FrameWidth
  iWidth = FrameWidth * iRatio
  iHeight = FrameHeight * iRatio
  *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  cvSetZero(*imgAverage)

  For rtnCount = 0 To INIT_TIME
    *image = cvQueryFrame(*capture)
    cvAcc(*image, *imgAverage, #Null)
  Next
  cvConvertScale(*imgAverage, *imgAverage, 1.0 / INIT_TIME, 0)
  cvSetZero(*imgSgm)

  For rtnCount = 0 To INIT_TIME
    *image = cvQueryFrame(*capture)
    cvConvert(*image, *imgTmp)
    cvSub(*imgTmp, *imgAverage, *imgTmp, #Null)
    cvPow(*imgTmp, *imgTmp, 2)
    cvConvertScale(*imgTmp, *imgTmp, 2, 0)
    cvPow(*imgTmp, *imgTmp, 0.5)
    cvAcc(*imgTmp, *imgSgm, #Null)
  Next
  cvConvertScale(*imgSgm, *imgSgm, 1.0 / INIT_TIME, 0)
  *storage.CvMemStorage = cvCreateMemStorage(0)
  *contours.CvContour
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvConvert(*image, *imgTmp)
      cvSub(*imgAverage, *imgSgm, *img_lower, #Null)
      cvSubS(*img_lower, zeta, zeta, zeta, zeta, *img_lower, #Null)
      cvAdd(*imgAverage, *imgSgm, *img_upper, #Null)
      cvAddS(*img_upper, zeta, zeta, zeta, zeta, *img_upper, #Null)
      cvInRange(*imgTmp, *img_lower, *img_upper, *imgSilhouette)
      cvSub(*imgTmp, *imgAverage, *imgTmp, #Null)
      cvPow(*imgTmp, *imgTmp, 2)
      cvConvertScale(*imgTmp, *imgTmp, 2, 0)
      cvPow(*imgTmp, *imgTmp, 0.5)
      cvRunningAvg(*image, *imgAverage, BG_RATIO, *imgSilhouette)
      cvRunningAvg(*imgTmp, *imgSgm, BG_RATIO, *imgSilhouette)
      cvNot(*imgSilhouette, *imgSilhouette)
      cvRunningAvg(*imgTmp, *imgSgm, OBJ_RATIO, *imgSilhouette)
      cvErode(*imgSilhouette, *imgSilhouette, *kernel, 1)
      cvDilate(*imgSilhouette, *imgSilhouette, *kernel, 2)
      cvErode(*imgSilhouette, *imgSilhouette, *kernel, 1)
      cvMerge(*imgSilhouette, *imgSilhouette, *imgSilhouette, #Null, *imgResult)
      cvClearMemStorage(*storage)
      nContours = cvFindContours(*imgSilhouette, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If area >= 400 And area <= 100000
            cvDrawContours(*imgResult, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, 2, #CV_AA, 0, 0)
            cvRectangleR(*image, *contours\rect\x, *contours\rect\y, *contours\rect\width, *contours\rect\height, 0, 0, 255, 0, 2, #CV_AA, #Null)
          EndIf
          *contours = *contours\h_next
        Next
      EndIf

      Select PIP
        Case 0
          If foreground
            cvResize(*image, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*imgResult, 20, 20, iWidth, iHeight)
            cvAndS(*imgResult, 0, 0, 0, 0, *imgResult, #Null)
            cvAdd(*imgResult, *PIP, *imgResult, #Null)
            cvResetImageROI(*imgResult)
            cvRectangleR(*imgResult, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *imgResult)
          Else
            cvResize(*imgResult, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*image, 20, 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *image)
          EndIf
        Case 1
          If foreground
            cvResize(*image, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*imgResult, *image\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*imgResult, 0, 0, 0, 0, *imgResult, #Null)
            cvAdd(*imgResult, *PIP, *imgResult, #Null)
            cvResetImageROI(*imgResult)
            cvRectangleR(*imgResult, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *imgResult)
          Else
            cvResize(*imgResult, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*image, *image\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *image)
          EndIf
        Case 2
          If foreground : cvShowImage(#CV_WINDOW_NAME, *imgResult) : Else : cvShowImage(#CV_WINDOW_NAME, *image) : EndIf
      EndSelect
      keyPressed = cvWaitKey(10)

      Select keyPressed
        Case 32
          foreground ! #True
        Case 86, 118
          PIP = (PIP + 1) % 3
      EndSelect
    Else
      Break
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*PIP)
  cvReleaseImage(@*imgResult)
  cvReleaseImage(@*imgSilhouette)
  cvReleaseImage(@*img_upper)
  cvReleaseImage(@*img_lower)
  cvReleaseImage(@*imgTmp)
  cvReleaseImage(@*imgSgm)
  cvReleaseImage(@*imgAverage)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to open video - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\