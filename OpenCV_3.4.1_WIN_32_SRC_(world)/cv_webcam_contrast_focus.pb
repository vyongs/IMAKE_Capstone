IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Contrast based focusing using the first derivative by X of a selected region."

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
  #SensorWidth = 50 : #SensorHeight = 50 : Dim arrMedium(4)
  centerX = FrameWidth / 2 - #SensorWidth / 2 : centerY = FrameHeight / 2 - #SensorHeight / 2
  centerWidth = FrameWidth / 2 + #SensorWidth / 2 : centerHeight = FrameHeight / 2 + #SensorHeight / 2
  *contrastColor.IplImage = cvCreateImage(#SensorWidth, #SensorHeight, #IPL_DEPTH_8U, 3)
  *contrastGray.IplImage = cvCreateImage(#SensorWidth, #SensorHeight, #IPL_DEPTH_8U, 1)
  *contrastSobel.IplImage = cvCreateImage(#SensorWidth, #SensorHeight, #IPL_DEPTH_8U, 1)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If nFrame % 4
        contrastMax = 0
        cvSetImageROI(*image, centerX, centerY, #SensorWidth, #SensorHeight)
        cvCopy(*image, *contrastColor, #Null)
        cvCvtColor(*contrastColor, *contrastGray, #CV_BGR2GRAY, 1)
        cvResetImageROI(*image)
        cvSmooth(*contrastGray, *contrastGray, #CV_GAUSSIAN, 3, 0, 0, 0)
        cvSobel(*contrastGray, *contrastSobel, 1, 1, 3)

        For y = 0 To *contrastSobel\height - 1
          For x = 0 To *contrastSobel\width - 1
            nPixel = PeekA(@*contrastSobel\imagedata\b + y * *contrastSobel\widthStep + x)

            If nPixel > contrastMax : contrastMax = nPixel : EndIf

          Next
        Next

        If nCount > 3 : nCount = 0 : EndIf

        arrMedium(nCount) = contrastMax
        nCount + 1 : contrastMax = 0

        For rtnCount = 0 To 4 - 1
          contrastMax + arrMedium(rtnCount)
        Next
        contrastMax / 4
      EndIf
      nFrame + 1
      cvRectangle(*image, centerX, centerY, centerWidth, centerHeight, 0, 255, 255, 0, 1, #CV_AA, 0)
      cvRectangle(*image, 10, FrameHeight / 2, 30, FrameHeight - 10, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
      cvRectangle(*image, 10, FrameHeight - 10 - contrastMax, 30, FrameHeight - 10, 0, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(10)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.61 beta 1 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\