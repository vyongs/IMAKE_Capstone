IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Video is saved to a folder." + #LF$ + #LF$ +
                  "Use the context menu to start / stop capture." + #LF$ + #LF$ +
                  "Double-Click the window to open a folder to the saved videos."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared captureCV, exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          If captureCV
            SetMenuItemText(0, 1, "Capture")
            captureCV = #False
          Else
            SetMenuItemText(0, 1, "Pause")
            captureCV = #True
          EndIf
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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("explorer", "..\Videos", #Null$)
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
    MenuItem(1, "Pause")
    MenuBar()
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

  If FileSize("../Videos") <> -2 : CreateDirectory("../Videos") : EndIf

  sVideo.s = "../Videos/" + FormatDate("%mm-%dd-%yyyy %hh-%ii-%ss", Date()) + ".avi" : fps.d = 7 : captureCV = #True
  *writer.CvVideoWriter = cvCreateVideoWriter(sVideo, CV_FOURCC("X", "V", "I", "D"), fps, FrameWidth, FrameHeight, #True)

  If *writer
    *image.IplImage
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      *image = cvQueryFrame(*capture)

      If *image
        cvFlip(*image, #Null, 1)

        If captureCV : cvWriteFrame(*writer, *image) : EndIf

        cvShowImage(#CV_WINDOW_NAME, *image)
        keyPressed = cvWaitKey(100)
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseVideoWriter(@*writer)
  EndIf
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\