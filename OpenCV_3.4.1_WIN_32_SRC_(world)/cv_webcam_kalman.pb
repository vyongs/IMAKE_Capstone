IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, hWnd_kalman

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Attempts to track the movements of an object by color (default blue) using the Kalman filter, " +
                  "estimating its position even under occlusions." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust Low-H value." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust Low-S value." + #LF$ +
                  "TRACKBAR 3  " + #TAB$ + ": Adjust Low-V value." + #LF$ +
                  "TRACKBAR 4  " + #TAB$ + ": Adjust High-H value." + #LF$ +
                  "TRACKBAR 5  " + #TAB$ + ": Adjust High-S value." + #LF$ +
                  "TRACKBAR 6  " + #TAB$ + ": Adjust High-V value." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Change display filter." + #LF$ + #LF$ +
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
      SendMessage_(hWnd_kalman, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("https://www.youtube.com/watch?v=sG-h5ONsj9s")
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback3(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback4(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback5(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback6(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
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
  cvResizeWindow(#CV_WINDOW_NAME, FrameWidth, FrameHeight + 48 + 42 + 84)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  LowH = 100 : LowS = 100 : LowV = 80
  cvCreateTrackbar("Low-H", #CV_WINDOW_NAME, @LowH, 179, @CvTrackbarCallback1())
  cvCreateTrackbar("Low-S", #CV_WINDOW_NAME, @LowS, 255, @CvTrackbarCallback2())
  cvCreateTrackbar("Low-V", #CV_WINDOW_NAME, @LowV, 255, @CvTrackbarCallback3())
  cvNamedWindow(#CV_WINDOW_NAME + " - Kalman Filter", #CV_WINDOW_AUTOSIZE)
  hWnd_kalman = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Kalman Filter"))
  SendMessage_(hWnd_kalman, #WM_SETICON, 0, opencv)
  wStyle = GetWindowLongPtr_(hWnd_kalman, #GWL_STYLE)
  SetWindowLongPtr_(hWnd_kalman, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
  cvResizeWindow(#CV_WINDOW_NAME + " - Kalman Filter", FrameWidth, FrameHeight + 48 + 42 + 84)
  cvMoveWindow(#CV_WINDOW_NAME + " - Kalman Filter", FrameWidth + 50, 20)
  HighH = 150 : HighS = 255 : HighV = 255
  cvCreateTrackbar("High-H", #CV_WINDOW_NAME + " - Kalman Filter", @HighH, 179, @CvTrackbarCallback4())
  cvCreateTrackbar("High-S", #CV_WINDOW_NAME + " - Kalman Filter", @HighS, 255, @CvTrackbarCallback5())
  cvCreateTrackbar("High-V", #CV_WINDOW_NAME + " - Kalman Filter", @HighV, 255, @CvTrackbarCallback6())
  stateSize = 6 : measurementSize = 4 : controlSize = 0
  *kalman.CvKalman = cvCreateKalman(stateSize, measurementSize, controlSize)
  Dim measurementMatrix.f(24) : Dim processNoiseCov.f(36) : Dim transitionMatrix.f(36) : Dim errorCovPre.f(36)
  measurementMatrix(0) = 1 : measurementMatrix(7) = 1 : measurementMatrix(16) = 1 : measurementMatrix(23) = 1
  CopyMemory(measurementMatrix(), @*kalman\measurement_matrix\fl\f, ArraySize(measurementMatrix()) * SizeOf(FLOAT))
  processNoiseCov(0) = 1e-2 : processNoiseCov(7) = 1e-2 : processNoiseCov(14) = 5
  processNoiseCov(21) = 5 : processNoiseCov(28) = 1e-2 : processNoiseCov(35) = 1e-2
  CopyMemory(processNoiseCov(), @*kalman\process_noise_cov\fl\f, ArraySize(processNoiseCov()) * SizeOf(FLOAT))
  cvSetIdentity(*kalman\measurement_noise_cov, 1e-1, 1e-1, 1e-1, 1e-1)
  transitionMatrix(0) = 1 : transitionMatrix(7) = 1 : transitionMatrix(14) = 1
  transitionMatrix(21) = 1 : transitionMatrix(28) = 1 : transitionMatrix(35) = 1
  errorCovPre(0) = 1 : errorCovPre(7) = 1 : errorCovPre(14) = 1
  errorCovPre(21) = 1 : errorCovPre(28) = 1 : errorCovPre(35) = 1
  Define.d prevTickCount, tickCount, dT
  *state.CvMat = cvCreateMat(stateSize, 1, CV_MAKETYPE(#CV_32F, 1))
  *measurement.CvMat = cvCreateMat(measurementSize, 1, CV_MAKETYPE(#CV_32F, 1))
  *result.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *blur.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *hsv.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *range.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *storage.CvMemStorage = cvCreateMemStorage(0) : cvClearMemStorage(*storage) : *contours.CvSeq
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, 0, 1, #CV_AA)
  *image.IplImage : center.CvPoint : predict.CvRect : bBox.CvRect
  BringWindowToTop(hWnd)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCopy(*image, *result, #Null)
      prevTickCount = tickCount
      tickCount = cvGetTickCount()
      dT = (tickCount - prevTickCount) / cvGetTickFrequency()

      If nFound
        transitionMatrix(2) = dT : transitionMatrix(9) = dT
        CopyMemory(transitionMatrix(), @*kalman\transition_matrix\fl\f, ArraySize(transitionMatrix()) * SizeOf(FLOAT))
        *state = cvKalmanPredict(*kalman, #Null)
        predict\width = PeekF(@*state\fl\f + 4 * 4)
        predict\height = PeekF(@*state\fl\f + 4 * 5)
        center\x = PeekF(@*state\fl\f + 4 * 0)
        center\y = PeekF(@*state\fl\f + 4 * 1)
        predict\x = center\x - predict\width / 2
        predict\y = center\y - predict\height / 2
        cvCircle(*result, center\x, center\y, 3, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
        cvRectangleR(*result, predict\x, predict\y, predict\width, predict\height, 0, 0, 255, 0, 2, #CV_AA, #Null)
      EndIf
      cvSmooth(*image, *blur, #CV_GAUSSIAN, 5, 5, 3, 3)
      cvCvtColor(*blur, *hsv, #CV_BGR2HSV, 1) : cvSetZero(*range)
      cvInRangeS(*hsv, LowH, LowS, LowV, 0, HighH, HighS, HighV, 0, *range)
      cvErode(*range, *range, *kernel, 2) : cvDilate(*range, *range, *kernel, 2)
      cvDilate(*range, *range, *kernel, 2) : cvErode(*range, *range, *kernel, 2)
      nContours = cvFindContours(*range, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)
      Dim *ballSeq.CvSeq(0) : Dim ballRect.CvRect(0)

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If area >= 20
            cvBoundingRect(@bBox, *contours, 0)
            ratio.f = bBox\width / bBox\height

            If ratio > 1 : ratio = 1 / ratio : EndIf

            If ratio > 0.75 And bBox\width * bBox\height >= 400
              arrSize = ArraySize(*ballSeq()) : ReDim *ballSeq(arrSize + 1) : ReDim ballRect(arrSize + 1)
              *ballSeq(arrSize) = *contours : ballRect(arrSize) = bBox
            EndIf
          EndIf
          *contours = *contours\h_next
        Next

        For rtnCount = 0 To ArraySize(*ballSeq()) - 1
          cvDrawContours(*range, *ballSeq(rtnCount), 255, 255, 255, 0, 255, 255, 255, 0, 0, 1, #CV_AA, 0, 0)
          center\x = ballRect(rtnCount)\x + ballRect(rtnCount)\width / 2
          center\y = ballRect(rtnCount)\y + ballRect(rtnCount)\height / 2
          cvCircle(*result, center\x, center\y, 3, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
          cvRectangleR(*result, ballRect(rtnCount)\x, ballRect(rtnCount)\y, ballRect(rtnCount)\width, ballRect(rtnCount)\height, 0, 255, 0, 0, 2, #CV_AA, #Null)
          cvRectangleR(*hsv, ballRect(rtnCount)\x, ballRect(rtnCount)\y, ballRect(rtnCount)\width, ballRect(rtnCount)\height, 0, 0, 0, 0, 2, #CV_AA, #Null)
          cvRectangleR(*range, ballRect(rtnCount)\x, ballRect(rtnCount)\y, ballRect(rtnCount)\width, ballRect(rtnCount)\height, 255, 255, 255, 0, 1, #CV_AA, #Null)
          cvPutText(*result, Str(center\x) + "," + Str(center\y), center\x + 10, center\y + 5, @font, 0, 255, 255, 0)
        Next
      EndIf

      If ArraySize(*ballSeq()) > 0
        notFoundCount = 0
        PokeF(@*measurement\fl\f + 4 * 0, ballRect(0)\x + ballRect(0)\width / 2)
        PokeF(@*measurement\fl\f + 4 * 1, ballRect(0)\y + ballRect(0)\height / 2)
        PokeF(@*measurement\fl\f + 4 * 2, ballRect(0)\width)
        PokeF(@*measurement\fl\f + 4 * 3, ballRect(0)\height)

        If nFound
          cvKalmanCorrect(*kalman, *measurement)
        Else
          CopyMemory(errorCovPre(), @*kalman\error_cov_pre\fl\f, ArraySize(errorCovPre()) * SizeOf(FLOAT))
          PokeF(@*state\fl\f + 4 * 0, PeekF(@*measurement\fl\f + 4 * 0))
          PokeF(@*state\fl\f + 4 * 1, PeekF(@*measurement\fl\f + 4 * 1))
          PokeF(@*state\fl\f + 4 * 2, 0)
          PokeF(@*state\fl\f + 4 * 3, 0)
          PokeF(@*state\fl\f + 4 * 4, PeekF(@*measurement\fl\f + 4 * 2))
          PokeF(@*state\fl\f + 4 * 5, PeekF(@*measurement\fl\f + 4 * 3))
          *kalman\state_post = *state
          nFound = #True
        EndIf
      Else
        notFoundCount + 1

        If notFoundCount >= 500 : nFound = #False : EndIf

      EndIf
      cvShowImage(#CV_WINDOW_NAME, *result)

      If nFilter : cvShowImage(#CV_WINDOW_NAME + " - Kalman Filter", *hsv) : Else : cvShowImage(#CV_WINDOW_NAME + " - Kalman Filter", *range) : EndIf

      keyPressed = cvWaitKey(1)

      If keyPressed = 32 : nFilter ! #True : EndIf

    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*range)
  cvReleaseImage(@*hsv)
  cvReleaseImage(@*blur)
  cvReleaseImage(@*result)
  cvReleaseMat(@*measurement)
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