IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Displays either a second webcam or simulates a second webcam by duplicating the main one, " +
                  "located in a small PIP window and enclosed within a border." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle main webcam." + #LF$ + #LF$ +
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

*capture1.CvCapture : *capture2.CvCapture

Repeat
  nCreate + 1
  
  If *capture1
    *capture2 = cvCreateCameraCapture(nCreate)
  Else
    *capture1 = cvCreateCameraCapture(nCreate)
  EndIf
Until nCreate = 99 Or *capture2

If *capture1
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
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)

  If *capture2 : *temp.IplImage : EndIf

  FrameWidth = cvGetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_HEIGHT)

  If FrameWidth > 640
    nRatio.d = 640 / FrameWidth
    FrameWidth * nRatio : FrameHeight * nRatio
    cvSetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_WIDTH, FrameWidth)
    cvSetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight)
  EndIf
  FrameWidth = cvGetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture1, #CV_CAP_PROP_FRAME_HEIGHT)
  iRatio.d = 150 / FrameWidth
  iWidth = FrameWidth * iRatio
  iHeight = FrameHeight * iRatio
  *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    If nFlip And *capture2 : *image = cvQueryFrame(*capture2) : Else : *image = cvQueryFrame(*capture1) : EndIf

    If *image
      cvFlip(*image, #Null, 1)

      If *capture2
        If nFlip : *temp = cvQueryFrame(*capture1) : Else : *temp = cvQueryFrame(*capture2) : EndIf

        If *temp
          cvFlip(*temp, #Null, 1)
          cvResize(*temp, *PIP, #CV_INTER_AREA)
        EndIf
      Else
        cvResize(*image, *PIP, #CV_INTER_AREA)
      EndIf

      Select PIP
        Case 0
          cvSetImageROI(*image, 20, 20, iWidth, iHeight)
          cvAndS(*image, 0, 0, 0, 0, *image, #Null)
          cvAdd(*image, *PIP, *image, #Null)
          cvResetImageROI(*image)
          cvRectangleR(*image, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
        Case 1
          cvSetImageROI(*image, *image\width - (150 + 20), 20, iWidth, iHeight)
          cvAndS(*image, 0, 0, 0, 0, *image, #Null)
          cvAdd(*image, *PIP, *image, #Null)
          cvResetImageROI(*image)
          cvRectangleR(*image, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
      EndSelect
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)

      Select keyPressed
        Case 32
          nFlip ! #True
        Case 86, 118
          PIP = (PIP + 1) % 3
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*PIP)
  cvDestroyAllWindows()

  If *capture2 : cvReleaseCapture(@*capture2) : EndIf

  cvReleaseCapture(@*capture1)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.71 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\