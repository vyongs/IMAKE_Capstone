IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draws text on the video frames, saving it as an AVI (Audio Video Interleaved) file; includes a blur-in / blur-out effect." + #LF$ + #LF$ +
                  "OpenCV only supports a single video track, no audio." + #LF$ + #LF$ +
                  "File size may increase exponentially (including loss in quality) depending on the codec." + #LF$ + #LF$ +
                  "Double-Click the window to open a folder to the saved videos."

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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("explorer", "..\Videos", #Null$)
  EndSelect
EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateFileCapture("videos/ball.mp4")
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

  If FileSize("../Videos") <> -2 : CreateDirectory("../Videos") : EndIf

  sVideo.s = "../Videos/ball.avi" : fps.d = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FPS)
  *writer.CvVideoWriter = cvCreateVideoWriter(sVideo, CV_FOURCC("X", "V", "I", "D"), fps, FrameWidth, FrameHeight, #True)

  If *writer
    font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_TRIPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
    *image.IplImage
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
    BlurIn = fps * 3 * 2
    BlurOut = 1

    Repeat
      *image = cvQueryFrame(*capture)

      If *image
        cvPutText(*image, "JHPJHP", 10, 30, @font, 255, 0, 0, 0)
        FramePos.d = cvGetCaptureProperty(*capture, #CV_CAP_PROP_POS_FRAMES)
        FrameCount.d = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_COUNT)

        If FramePos <= fps * 3
          BlurIn - 2
          cvSmooth(*image, *image, #CV_BLUR, BlurIn, 0, 0, 0)
        ElseIf FrameCount - FramePos <= fps * 3
          BlurOut + 2
          cvSmooth(*image, *image, #CV_BLUR, BlurOut, 0, 0, 0)
        EndIf
        cvWriteFrame(*writer, *image)
        cvShowImage(#CV_WINDOW_NAME, *image)
        keyPressed = cvWaitKey(10)
      Else
        Break
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseVideoWriter(@*writer)
  EndIf
  cvDestroyAllWindows()  
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to open video - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\