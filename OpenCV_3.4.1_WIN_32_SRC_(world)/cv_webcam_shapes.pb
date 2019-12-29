IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draws moving and static shapes using various filters."

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
  ptLeft = FrameWidth / 2 - 200
  ptTop = FrameHeight / 2 - 100
  ptRight = ptLeft + 400
  ptBottom = ptTop + 200
  width = 200
  radius = 100
  x = 500
  angle.d = 4
  Dim pts1.CvPoint(4)
  pts1(0)\x = 50
  pts1(0)\y = 50
  pts1(1)\x = 200
  pts1(1)\y = 50
  pts1(2)\x = 200
  pts1(2)\y = 400
  pts1(3)\x = 100
  pts1(3)\y = 200
  npts1 = ArraySize(pts1())
  Dim pts2.CvPoint(4)
  pts2(0)\x = 500
  pts2(0)\y = 50
  pts2(1)\x = 500
  pts2(1)\y = 300
  pts2(2)\x = 400
  pts2(2)\y = 100
  pts2(3)\x = 400
  pts2(3)\y = 50
  npts2 = ArraySize(pts2())
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If width = 200 : adjust1.b = #True : ElseIf width = 10 : adjust1 = #False : EndIf
      If adjust1 : width - 10 : Else : width + 10 : EndIf
      If radius = 100 : adjust2.b = #True : ElseIf radius = 5 : adjust2 = #False : EndIf
      If adjust2 : radius - 5 : Else : radius + 5 : EndIf
      If x = 500 : adjust3.b = #True : ElseIf x = 20 : adjust3 = #False : EndIf
      If adjust3 : x - 20 : Else : x + 20 : EndIf
      If angle = 45 : adjust4.b = #True : ElseIf angle = 180 : adjust4 = #False : EndIf
      If adjust4 : angle - 5 : Else : angle + 5 : EndIf

      cvRectangle(*image, ptLeft, ptTop, ptRight, ptBottom, 0, 0, 255, 0, 2, #CV_AA, #Null)
      cvRectangleR(*image, ptLeft + 100, ptTop + 100, width, 200, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
      cvCircle(*image, ptLeft, 120, radius, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
      cvLine(*image, x, 100, 300, 400, 0, 255, 255, 0, 4, #CV_AA, #Null)
      cvEllipse(*image, 400, 250, 200, 100, angle, 0, 360, 255, 0, 255, 0, 3, #CV_AA, #Null)
      cvPolyLine(*image, pts1(), @npts1, 1, #False, 255, 200, 100, 0, 2, #CV_AA, #Null)
      cvFillPoly(*image, pts2(), @npts2, 1, 100, 200, 255, 0, #CV_AA, #Null)
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
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