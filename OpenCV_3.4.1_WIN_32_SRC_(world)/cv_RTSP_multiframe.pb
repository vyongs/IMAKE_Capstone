IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "View 6 RTSP (Real Time Streaming Protocol) feeds."

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

Dim arrRTSP.s(6) : Dim *capture.CvCapture(6)
arrRTSP(0) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"
arrRTSP(1) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"
arrRTSP(2) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"
arrRTSP(3) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"
arrRTSP(4) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"
arrRTSP(5) = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"

For rtnCount = 0 To ArraySize(*capture()) - 1
  *capture(rtnCount) = cvCreateFileCapture(arrRTSP(rtnCount))
Next

If *capture(0)
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
  FrameWidth = cvGetCaptureProperty(*capture(0), #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture(0), #CV_CAP_PROP_FRAME_HEIGHT)

  If FrameWidth > 320
    nRatio.d = 320 / FrameWidth
    FrameWidth * nRatio : FrameHeight * nRatio
  EndIf
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  *image1.IplImage : *image2.IplImage : *image3.IplImage : *image4.IplImage : *image5.IplImage : *image6.IplImage
  *frame.IplImage = cvCreateImage(FrameWidth * 3, FrameHeight * 2, #IPL_DEPTH_8U, 3)
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX_SMALL, 1, 1, #Null, 1, #CV_AA)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image1 = cvQueryFrame(*capture(0)) : *image2 = cvQueryFrame(*capture(1)) : *image3 = cvQueryFrame(*capture(2))
    *image4 = cvQueryFrame(*capture(3)) : *image5 = cvQueryFrame(*capture(4)) : *image6 = cvQueryFrame(*capture(5))

    If *image1 And *image2 And *image3 And *image4 And *image5 And *image6
      cvSetImageROI(*frame, 0, 0, FrameWidth, FrameHeight)
      cvResize(*image1, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 01", 20, 30, @font, 0, 255, 255, 0)
      cvSetImageROI(*frame, FrameWidth, 0, FrameWidth, FrameHeight)
      cvResize(*image2, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 02", FrameWidth + 20, 30, @font, 0, 255, 255, 0)
      cvSetImageROI(*frame, FrameWidth * 2, 0, FrameWidth, FrameHeight)
      cvResize(*image3, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 03", FrameWidth * 2 + 20, 30, @font, 0, 255, 255, 0)
      cvSetImageROI(*frame, 0, FrameHeight, FrameWidth, FrameHeight)
      cvResize(*image4, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 04", 20, FrameHeight + 30, @font, 0, 255, 255, 0)
      cvSetImageROI(*frame, FrameWidth, FrameHeight, FrameWidth, FrameHeight)
      cvResize(*image5, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 05", FrameWidth + 20, FrameHeight + 30, @font, 0, 255, 255, 0)
      cvSetImageROI(*frame, FrameWidth * 2, FrameHeight, FrameWidth, FrameHeight)
      cvResize(*image6, *frame, #CV_INTER_AREA)
      cvResetImageROI(*frame)
      cvPutText(*frame, "CAM 06", FrameWidth * 2 + 20, FrameHeight + 30, @font, 0, 255, 255, 0)
      cvShowImage(#CV_WINDOW_NAME, *frame)
      keyPressed = cvWaitKey(10)
    Else
      Break
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*frame)
  cvDestroyAllWindows()

  For rtnCount = 0 To ArraySize(*capture()) - 1
    If *capture(rtnCount) : cvReleaseCapture(@*capture(rtnCount)) : EndIf
  Next
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to open URLs - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.71 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\