IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, *image.IplImage, select_object

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Demonstrates the ability to select an area on the webcam interface." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Highlight / Select area." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch background." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the webcam."

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
  Shared selection.CvRect
  Shared origin.CvPoint

  If select_object > 0
    selection\x = origin\x
    selection\y = origin\y
    CV_MIN(selection\x, x)
    CV_MIN(selection\y, y)
    selection\width = selection\x + CV_IABS(x - origin\x)
    selection\height = selection\y + CV_IABS(y - origin\y)
    CV_MAX(selection\x, 0)
    CV_MAX(selection\y, 0)
    CV_MIN(selection\width, *image\width)
    CV_MIN(selection\height, *image\height)
    selection\width - selection\x
    selection\height - selection\y
  EndIf

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      origin\x = x
      origin\y = y
      selection\x = x
      selection\y = y
      selection\width = 0
      selection\height = 0
      select_object = 1
    Case #CV_EVENT_LBUTTONUP
      If selection\width > 5 And selection\height > 5 : select_object = -1 : Else : select_object = 0 : EndIf
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
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *canny.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      Select select_object
        Case -1
          cvCvtColor(*image, *gray, #CV_BGR2GRAY, 1)
          threshold.d = cvThreshold(*gray, *gray, 0, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
          cvCanny(*image, *gray, threshold * 0.5, threshold, 3, #False)
          cvCvtColor(*gray, *canny, #CV_GRAY2BGR, 1)
          *select.IplImage = cvCreateImage(selection\width, selection\height, #IPL_DEPTH_8U, 3)
          cvSetImageROI(*canny, selection\x, selection\y, selection\width, selection\height)
          cvSetImageROI(*image, selection\x, selection\y, selection\width, selection\height)

          If keyPressed = 13 : select_object = 0 : ElseIf keyPressed = 32 : background ! #True : EndIf
          If Not background : cvAndS(*image, 0, 0, 0, 0, *image, #Null) : EndIf

          cvAdd(*image, *canny, *image, #Null)
          cvResetImageROI(*image)
          cvResetImageROI(*canny)
          cvReleaseImage(@*select)
        Case 1
          cvSetImageROI(*image, selection\x, selection\y, selection\width, selection\height)
          cvXorS(*image, 255, 255, 255, 0, *image, #Null)
          cvResetImageROI(*image)
        Default
          background = #False
      EndSelect
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*canny)
  cvReleaseImage(@*gray)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\