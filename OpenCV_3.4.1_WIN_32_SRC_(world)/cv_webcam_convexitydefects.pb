IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the contour areas, finding the convex hull of point sets to convexity defects." + #LF$ + #LF$ +
                  "START       " + #TAB$ + ": Green." + #LF$ +
                  "END         " + #TAB$ + ": Red." + #LF$ +
                  "DEPTH       " + #TAB$ + ": Blue." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between views."

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

Procedure GetConvexHull(*image.IplImage, *contours.CvSeq)
  *hull.CvSeq = cvConvexHull2(*contours, #Null, #CV_CLOCKWISE, #False)
  *pt1.CvPoint = cvGetSeqElem(*hull, *hull\total - 1) : *pt2.CvPoint

  For rtnCount = 0 To *hull\total - 1
    *pt2 = cvGetSeqElem(*hull, rtnCount)
    pt1 = PeekL(*pt1\x) : pt2 = PeekL(*pt1\x + 4)
    pt3 = PeekL(*pt2\x) : pt4 = PeekL(*pt2\x + 4)
    cvLine(*image, pt1, pt2, pt3, pt4, 0, 255, 255, 0, 2, #CV_AA, #Null)
    *pt1 = *pt2
  Next
  ProcedureReturn *hull
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
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
  *YCrCb.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *mask.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *contour.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *storage.CvMemStorage = cvCreateMemStorage(0)
  *hull.CvSeq
  *defect.CvSeq
  *contours.CvSeq
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvSetZero(*mask)
      cvCvtColor(*image, *YCrCb, #CV_BGR2YCrCb, 1)
      cvSplit(*YCrCb, #Null, *mask, #Null, #Null)
      cvErode(*mask, *mask, *kernel, 2)
      cvDilate(*mask, *mask, *kernel, 3)
      cvSmooth(*mask, *mask, #CV_GAUSSIAN, 21, 0, 0, 0)
      cvThreshold(*mask, *mask, 130, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
      cvClearMemStorage(*storage)
      nContours = cvFindContours(*mask, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)
      cvSetZero(*contour)

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If area > 20000 And area < 100000
            cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
            *hull = GetConvexHull(*image, *contours)
            *defect = cvConvexityDefects(*contours, *hull, #Null)
            Dim elements.CvConvexityDefect(*defect\total)
            cvCvtSeqToArray(*defect, @elements(), 0, #CV_WHOLE_SEQ_END_INDEX)

            For rtnDefect = 0 To *defect\total - 1
              If elements(rtnDefect)\depth > 15 And elements(rtnDefect)\depth < 250
                startX = elements(rtnDefect)\start\x : startY = elements(rtnDefect)\start\y
                endX = elements(rtnDefect)\end\x : endY = elements(rtnDefect)\end\y
                depth_pointX = elements(rtnDefect)\depth_point\x : depth_pointY = elements(rtnDefect)\depth_point\y
                cvCircle(*image, startX, startY, 5, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
                cvCircle(*image, endX, endY, 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
                cvCircle(*image, depth_pointX, depth_pointY, 5, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
              EndIf
            Next
          EndIf
          *contours = *contours\h_next
        Next
      EndIf

      Select view
        Case 0
          cvShowImage(#CV_WINDOW_NAME, *image)
        Case 1
          cvShowImage(#CV_WINDOW_NAME, *mask)
        Case 2
          cvShowImage(#CV_WINDOW_NAME, *contour)
      EndSelect
      keyPressed = cvWaitKey(10)

      If keyPressed = 32 : view = (view + 1) % 3 : EndIf

    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*contour)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*YCrCb)
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