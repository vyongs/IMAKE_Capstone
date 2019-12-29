IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using RTSP (Real Time Streaming Protocol) an online video is saved to a local folder." + #LF$ + #LF$ +
                  "Double-Click the window to open a folder to the saved videos."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared captureCV, exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
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

URL.s = "http://hubblesource.stsci.edu/sources/video/clips/details/images/centaur_1.mpg"

Repeat
  nCreate + 1
  *capture.CvCapture_FFMPEG = cvCreateFileCapture_FFMPEG(URL)
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
  FrameWidth = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_FRAME_HEIGHT)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)

  If FileSize("../Videos") <> -2 : CreateDirectory("../Videos") : EndIf

  sVideo.s = "../Videos/" + FormatDate("%mm-%dd-%yyyy %hh-%ii-%ss", Date()) + ".mpeg"
  avi_ratio.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_POS_AVI_RATIO)
  fps.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_FPS)
  FOURCC.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_FOURCC)
  frame_count.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_FRAME_COUNT)
  *writer.CvVideoWriter_FFMPEG = cvCreateVideoWriter_FFMPEG(sVideo, CV_FOURCC("X", "V", "I", "D"), fps, FrameWidth, FrameHeight, #True)

  If *writer
    *data.BYTE : *convert.CvMat
    *source.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
    *frame.IplImage = cvCreateImage(500, 430, #IPL_DEPTH_8U, 3)
    font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 0.5, 0.5, #Null, 1, #CV_AA)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If cvGrabFrame_FFMPEG(*capture)
        If cvRetrieveFrame_FFMPEG(*capture, @*data, @cvStep, @width, @height, @cn)
          *convert = cvMat(height, width, CV_MAKETYPE(#CV_8U, cn), *data)
          cvConvertScale(*convert, *source, 1, 1 / 128)
          msec.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_POS_MSEC)
          frame_position.d = cvGetCaptureProperty_FFMPEG(*capture, #CV_FFMPEG_CAP_PROP_POS_FRAMES)
          cvSetZero(*frame)
          cvSetImageROI(*frame, *frame\width - width, 25, width, height)
          cvAndS(*frame, 0, 0, 0, 0, *frame, #Null)
          cvAdd(*frame, *source, *frame, #Null)
          cvResetImageROI(*frame)
          cvPutText(*frame, "FRAME MSEC: " + Str(msec), 20, 40, @font, 255, 255, 255, 0)
          cvPutText(*frame, "FRAME POSITION: " + Str(frame_position), 20, 80, @font, 255, 255, 255, 0)
          cvPutText(*frame, "AVI RATIO: " + Str(avi_ratio), 20, 120, @font, 255, 255, 255, 0)
          cvPutText(*frame, "WIDTH: " + Str(FrameWidth), 20, 160, @font, 255, 255, 255, 0)
          cvPutText(*frame, "HEIGHT: " + Str(FrameHeight), 20, 200, @font, 255, 255, 255, 0)
          cvPutText(*frame, "FPS: " + Str(fps), 20, 240, @font, 255, 255, 255, 0)
          cvPutText(*frame, "FOURCC: " + Str(FOURCC), 20, 280, @font, 255, 255, 255, 0)
          cvPutText(*frame, "FRAME COUNT: " + Str(frame_count), 20, 320, @font, 255, 255, 255, 0)
          cvPutText(*frame, "-----------------------------------", 20, 360, @font, 255, 255, 255, 0)
          cvWriteFrame_FFMPEG(*writer, *data, cvStep, width, height, cn, #IPL_ORIGIN_TL)
          cvShowImage(#CV_WINDOW_NAME, *frame)
          keyPressed = cvWaitKey(1)
        EndIf
      Else
        cvPutText(*frame, "SAVED FILE: " + sVideo, 20, 400, @font, 255, 255, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *frame)
        cvReleaseVideoWriter_FFMPEG(@*writer)
        cvWaitKey(0)
        Break
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*frame)
    cvReleaseImage(@*source)
    cvReleaseVideoWriter_FFMPEG(@*writer)
  EndIf
  cvDestroyAllWindows()
  cvReleaseCapture_FFMPEG(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to open URL - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\