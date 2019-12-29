IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, nFlag, nAnchor, Dim srcPoint.CvPoint2D32f(4), Dim dstPoint.CvPoint2D32f(4)

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates a perspective transform from four pairs of corresponding points." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Modify warp dimensions." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle control anchors." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset warp dimensions."

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

Procedure InRectangle(pX, pY, tlX, tlY, brX, brY)
 If pX >= tlX And pX <= brX And pY >= tlY And pY <= brY : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
EndProcedure

Procedure SetDimensions(width, height)
  srcPoint(0)\x = 0
  srcPoint(0)\y = 0
  srcPoint(1)\x = width - 1
  srcPoint(1)\y = 0
  srcPoint(2)\x = 0
  srcPoint(2)\y = height - 1
  srcPoint(3)\x = width - 1
  srcPoint(3)\y = height - 1
  dstPoint(0)\x = width * 0.05
  dstPoint(0)\y = height * 0.33
  dstPoint(1)\x = width * 0.9
  dstPoint(1)\y = height * 0.25
  dstPoint(2)\x = width * 0.2
  dstPoint(2)\y = height * 0.7
  dstPoint(3)\x = width * 0.8
  dstPoint(3)\y = height * 0.9
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      If nAnchor
        nFlag = -1

        For rtnCount = 0 To 4 - 1
          If InRectangle(x, y, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5)
            nFlag = rtnCount
            Break
          EndIf
        Next
      EndIf
    Case #CV_EVENT_MOUSEMOVE
      If nFlag <> -1 And Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        dstPoint(nFlag)\x = x
        dstPoint(nFlag)\y = y
      EndIf
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
  nFlag = -1 : nAnchor = 1
  SetDimensions(FrameWidth, FrameHeight)
  *warp.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
  *matrix.IplImage
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvReleaseImage(@*matrix)
      *matrix = cvCloneImage(*image)

      If nAnchor
        cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *warp)
        cvWarpPerspective(*image, *matrix, *warp, #CV_INTER_LINEAR + #CV_WARP_FILL_OUTLIERS, 100, 100, 50, 0)

        For rtnCount = 0 To 4 - 1
          cvRectangle(*matrix, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
        Next
      Else
        cvWarpPerspective(*image, *matrix, *warp, #CV_INTER_LINEAR + #CV_WARP_FILL_OUTLIERS, 100, 100, 50, 0)
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *matrix)
      keyPressed = cvWaitKey(10)

      Select keyPressed
        Case 13
          nFlag = -1 : nAnchor = 1
          SetDimensions(FrameWidth, FrameHeight)
        Case 32
          nAnchor ! #True
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*matrix)
  cvReleaseMat(@*warp)
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