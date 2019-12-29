IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Slit-Scan Imaging: A technique used to create time lapse image effects." + #LF$ + #LF$ +
                  "[ L ] KEY   " + #TAB$ + ": Set scan loop ON / OFF." + #LF$ +
                  "[ O ] KEY   " + #TAB$ + ": Toggle scan orientation." + #LF$ +
                  "[ R ] KEY   " + #TAB$ + ": Reverse scan direction." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Pause / Resume scan." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset scan from start." + #LF$ + #LF$ +
                  "Double-Click the window to open a folder to the auto-saved images."

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
      RunProgram("explorer", "..\SlitScans", #Null$)
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
  *slitimage.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *slitscan.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage : SlitSize = 2 : SlitFinish = FrameHeight : SlitScan = #True
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If SlitScan
        If nHorizontal
          cvSetImageROI(*image, SlitStart, 0, SlitSize, FrameHeight)
          cvSetImageROI(*slitimage, SlitStart, 0, SlitSize, FrameHeight)
        Else
          cvSetImageROI(*image, 0, SlitStart, FrameWidth, SlitSize)
          cvSetImageROI(*slitimage, 0, SlitStart, FrameWidth, SlitSize)
        EndIf
        cvCopy(*image, *slitimage, #Null)
        cvResetImageROI(*image)
        cvResetImageROI(*slitimage)

        If nReverse : SlitStart - SlitSize : Else : SlitStart + SlitSize : EndIf

      EndIf
      cvCopy(*image, *slitscan, #Null)

      If nReverse
        If nHorizontal
          cvSetImageROI(*slitimage, SlitStart, 0, FrameWidth, FrameHeight)
          cvSetImageROI(*slitscan, SlitStart, 0, FrameWidth, FrameHeight)
        Else
          cvSetImageROI(*slitimage, 0, SlitStart, FrameWidth, FrameHeight)
          cvSetImageROI(*slitscan, 0, SlitStart, FrameWidth, FrameHeight)
        EndIf
      Else
        If nHorizontal
          cvSetImageROI(*slitimage, 0, 0, SlitStart, FrameHeight)
          cvSetImageROI(*slitscan, 0, 0, SlitStart, FrameHeight)
        Else
          cvSetImageROI(*slitimage, 0, 0, FrameWidth, SlitStart)
          cvSetImageROI(*slitscan, 0, 0, FrameWidth, SlitStart)
        EndIf
      EndIf
      cvCopy(*slitimage, *slitscan, #Null)
      cvResetImageROI(*slitscan)
      cvResetImageROI(*slitimage)

      If nHorizontal
        cvLine(*slitscan, SlitStart, 0, SlitStart, FrameHeight, 0, 0, 255, 0, SlitSize, #CV_AA, #Null)
      Else
        cvLine(*slitscan, 0, SlitStart, FrameWidth, SlitStart, 0, 0, 255, 0, SlitSize, #CV_AA, #Null)
      EndIf

      Select #True
        Case Bool(((SlitStart >= SlitFinish And Not nReverse) Or (SlitStart < SlitFinish And nReverse)) And SlitScan = #False)
          cvShowImage(#CV_WINDOW_NAME, *slitimage)
          keyPressed = cvWaitKey(0)
        Case Bool((SlitStart >= SlitFinish And Not nReverse) Or (SlitStart < SlitFinish And nReverse))
          If FileSize("../SlitScans") <> -2 : CreateDirectory("../SlitScans") : EndIf

          SaveDate.s = FormatDate("%yyyy-%mm-%dd %hh-%ii-%ss", Date())
          cvSaveImage("../SlitScans/" + SaveDate + ".jpg", *slitimage, #Null)

          If nLoop
            If nReverse
              If nHorizontal : SlitStart = FrameWidth - SlitSize : Else : SlitStart = FrameHeight - SlitSize : EndIf
            Else
              SlitStart = 0
            EndIf
          Else
            SlitScan = #False
          EndIf
        Default
          cvShowImage(#CV_WINDOW_NAME, *slitscan)
          keyPressed = cvWaitKey(1)
      EndSelect

      Select keyPressed
        Case 13
          If nReverse
            If nHorizontal : SlitStart = FrameWidth - SlitSize : Else : SlitStart = FrameHeight - SlitSize : EndIf
          Else
            SlitStart = 0
          EndIf
          SlitScan = #True
        Case 32
          If nReverse
            If SlitStart > 0 : SlitScan ! #True : EndIf
          Else
            If SlitStart < SlitFinish : SlitScan ! #True : EndIf
          EndIf
        Case 76, 108
          nLoop ! #True

          If nReverse
            If nHorizontal : SlitStart = FrameWidth - SlitSize : Else : SlitStart = FrameHeight - SlitSize : EndIf
          Else
            SlitStart = 0
          EndIf
          SlitScan = #True
        Case 79, 111
          nHorizontal ! #True

          If nReverse
            If nHorizontal : SlitStart = FrameWidth - SlitSize : Else : SlitStart = FrameHeight - SlitSize : EndIf
          Else
            SlitStart = 0

            If nHorizontal : SlitFinish = FrameWidth : Else : SlitFinish = FrameHeight : EndIf

          EndIf
          SlitScan = #True
        Case 82, 114
          nReverse ! #True

          If nReverse
            If nHorizontal : SlitStart = FrameWidth - SlitSize : Else : SlitStart = FrameHeight - SlitSize : EndIf

            SlitFinish = 0
          Else
            SlitStart = 0

            If nHorizontal : SlitFinish = FrameWidth : Else : SlitFinish = FrameHeight : EndIf

          EndIf
          SlitScan = #True
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*slitscan)
  cvReleaseImage(@*slitimage)
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