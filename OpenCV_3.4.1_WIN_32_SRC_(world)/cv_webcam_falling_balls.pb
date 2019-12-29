IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Falling Balls: Try to stop the balls from reaching the bottom of the screen." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage to a demonstration video."

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
      RunProgram("http://youtu.be/gaeJX2A8GvA")
  EndSelect
EndProcedure

Structure SPEED_XY
  x.l
  y.l
EndStructure

Structure TARGET
  x.l
  y.l
  width.l
  height.l
  speed.SPEED_XY
  active.b
EndStructure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
Until nCreate = 99 Or *capture

If *capture
  InitSound() : LoadSound(0, "sounds/pop.wav") : PlaySound(0, #PB_Sound_MultiChannel, 0)
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
  *current.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *previous.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *difference.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *ball_original.IplImage = cvLoadImage("images/ball.png", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *ball.IplImage = cvCreateImage(64, 64, *ball_original\depth, *ball_original\nChannels)
  *mask_original.IplImage = cvLoadImage("images/mask.png", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *mask.IplImage = cvCreateImage(64, 64, *mask_original\depth, *mask_original\nChannels)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(9, 9, 4, 4, #CV_SHAPE_ELLIPSE, #Null)
  *roi.CvMat
  submat.CvMat
  cvSetZero(*current)
  cvSetZero(*previous)
  cvSetZero(*difference)
  cvResize(*ball_original, *ball, #CV_INTER_AREA)
  cvReleaseImage(@*ball_original)
  cvResize(*mask_original, *mask, #CV_INTER_AREA)
  cvReleaseImage(@*mask_original)
  nBalls = 7
  Dim self.TARGET(nBalls)

  For rtnCount = 0 To ArraySize(self()) - 1
    self(rtnCount)\x = Random(FrameWidth - *ball\width)
    self(rtnCount)\y = 0
    self(rtnCount)\width = *ball\width
    self(rtnCount)\height = *ball\height
    self(rtnCount)\speed\x = 0
    self(rtnCount)\speed\y = 1
    self(rtnCount)\active = #True
  Next
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 1, 1, #Null, 2, #CV_AA)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If nBalls > 0
        cvSmooth(*image, *current, #CV_BLUR, 15, 15, 0, 0)
        cvAbsDiff(*current, *previous, *difference)
        cvCvtColor(*difference, *gray, #CV_BGR2GRAY, 1)
        cvThreshold(*gray, *gray, 10, 255, #CV_THRESH_BINARY)
        cvDilate(*gray, *gray, *kernel, 3)

        If wait < 20 : wait + 1 : EndIf

        If wait >= 20
          For rtnCount = 0 To ArraySize(self()) - 1
            If self(rtnCount)\active
              *roi = cvGetSubRect(*gray, @submat, self(rtnCount)\x, self(rtnCount)\y, self(rtnCount)\width, self(rtnCount)\height)
              nZero = cvCountNonZero(*roi)

              If nZero < 1000
                cvSetImageROI(*image, self(rtnCount)\x, self(rtnCount)\y, self(rtnCount)\width, self(rtnCount)\height)
                cvCopy(*ball, *image, *mask)
                cvResetImageROI(*image)
                self(rtnCount)\x + self(rtnCount)\speed\x
                self(rtnCount)\y + self(rtnCount)\speed\y

                If self(rtnCount)\y + self(rtnCount)\height >= FrameHeight
                  self(rtnCount)\active = #False
                  nBalls - 1
                EndIf
              Else
                If IsSound(0) : PlaySound(0, #PB_Sound_MultiChannel) : EndIf

                self(rtnCount)\x = Random(FrameWidth - *ball\width)
                self(rtnCount)\y = 0

                If self(rtnCount)\speed\y < 25
                  self(rtnCount)\speed\x = 0
                  self(rtnCount)\speed\y + 1
                EndIf
                score + 1
              EndIf
            EndIf
          Next
        EndIf
        cvReleaseImage(@*previous)
        *previous = cvCloneImage(*current)
        cvPutText(*image, "Score: " + Str(score), 10, FrameHeight - 10, @font, 0, 255, 255, 0)
      Else
        hDc = GetDC_(window_handle)
        lpString.s = "GAME OVER - Final Score: " + Str(score)
        GetTextExtentPoint32_(hDc, lpString, Len(lpString), @lpSize)
        ReleaseDC_(window_handle, hDc)
        cvPutText(*image, lpString, (FrameWidth / 2) - (lpSize + 5 + (Len(lpString) * 2)), FrameHeight / 2, @font, 0, 0, 255, 0)
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(1)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*ball)
  cvReleaseImage(@*gray)
  cvReleaseImage(@*difference)
  cvReleaseImage(@*previous)
  cvReleaseImage(@*current)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)

  If IsSound(0) : FreeSound(0) : EndIf

Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS beta 3 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\