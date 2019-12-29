IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, hWnd_control, *ycrcb.IplImage, *filter.IplImage, *sum.IplImage, *hist.IplImage
Global nMinCr, nMaxCr, nMinCb, nMaxCb, nErosion1, nDilation1, nDeviation, nErosion2, nDilation2, nWeighting

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Skin detection using various filters applied against the YCrCb (Luma [Y] and Chroma [CrCb]) color space." + #LF$ + #LF$ +
                  "CONTROLS    " + #TAB$ + ": Adjust settings." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch display mode." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset controls."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      SendMessage_(hWnd_control, #WM_CLOSE, 0, 0)
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

Procedure ColorSegmentation()
  cvInRangeS(*ycrcb, 0, nMinCr, nMinCb, 0, 255, nMaxCr, nMaxCb, 0, *filter)
EndProcedure

Procedure DensityRegularisation()
  cvSetZero(*sum)

  For i = 0 To *ycrcb\height - 1 Step 4
    For j = 0 To *ycrcb\width - 1 Step 4
      nSum = PeekA(@*sum\imageData\b + i * *sum\widthStep + j)

      For k = 0 To 4 - 1
        For l = 0 To 4 - 1
          If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) <> 0
            nSum + 1 : PokeA(@*sum\imageData\b + i * *sum\widthStep + j, nSum)
          EndIf
        Next
      Next

      If nSum = 0 Or i = 0 Or j = 0 Or i = *ycrcb\height - 4 Or j = *ycrcb\width - 4 : nOp = 0
      ElseIf nSum > 0 And nSum < 16 : nOp = 128
      Else : nOp = 255 : EndIf

      For k = 0 To 4 - 1
        For l = 0 To 4 - 1
          PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, nOp)
        Next
      Next
    Next
  Next

  For i = 4 To *ycrcb\height - 4 - 1 Step 4
    For j = 4 To  *ycrcb\width - 4 - 1 Step 4
      nErode = 0

      If PeekA(@*filter\imageData\b + i * *filter\widthStep + j) = 255
        For k = -4 To 5 - 1 Step 4
          For l = -4 To 5 - 1 Step 4
            If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) = 255 : nErode + 1 : EndIf
          Next
        Next

        If nErode < nErosion1
          For k = 0 To 4 - 1
            For l = 0 To 4 - 1
              PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, 0)
            Next
          Next
        EndIf
      EndIf
    Next
  Next

  For i = 4 To *ycrcb\height - 4 - 1 Step 4
    For j = 4 To  *ycrcb\width - 4 - 1 Step 4
      nDilate = 0

      If PeekA(@*filter\imageData\b + i * *sum\widthStep + j) < 255
        For k = -4 To 5 - 1 Step 4
          For l = -4 To 5 - 1 Step 4
            If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) = 255 : nDilate + 1 : EndIf
          Next
        Next

        If nDilate > nDilation1
          For k = 0 To 4 - 1
            For l = 0 To 4 - 1
              PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, 255)
            Next
          Next
        EndIf

        For k = 0 To 4 - 1
          For l = 0 To 4 - 1
            If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) <> 255
              PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, 0)
            EndIf
          Next
        Next
      EndIf
    Next
  Next
EndProcedure

Procedure LuminanceRegularisation()
  For i = 4 To *ycrcb\height - 4 - 1 Step 4
    For j = 4 To  *ycrcb\width - 4 - 1 Step 4
      nXbar.f = 0 : nSse.f = 0 : nStdDev.f = 0 : nOp = 0

      For k = 0 To 4 - 1
        For l = 0 To 4 - 1
          nXbar + PeekA(@*ycrcb\imageData\b + (i + k) * *ycrcb\widthStep + (j + l) * 3)
        Next
      Next
      nXbar / 16

      For k = 0 To 4 - 1
        For l = 0 To 4 - 1
          nSse + Pow(PeekA(@*ycrcb\imageData\b + (i + k) * *ycrcb\widthStep + (j + l) * 3 - nXbar), 2)
        Next
      Next
      nStdDev = Pow(nSse / 16, 0.5)

      If PeekA(@*filter\imageData\b + i * *filter\widthStep + j) = 255 And nStdDev >= nDeviation : nOp = 255 : EndIf

      For k = 0 To 4 - 1
        For l = 0 To 4 - 1
          PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, nOp)
        Next
      Next
    Next
  Next
EndProcedure

Procedure GeometricCorrection()
  For i = 4 To *ycrcb\height - 4 - 1 Step 4
    For j = 4 To  *ycrcb\width - 4 - 1 Step 4
      nErode = 0

      If PeekA(@*filter\imageData\b + i * *filter\widthStep + j) = 255
        For k = -4 To 5 - 1 Step 4
          For l = -4 To 5 - 1 Step 4
            If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) = 255 : nErode + 1 : EndIf
          Next
        Next

        If nErode < nErosion2
          For k = 0 To 4 - 1
            For l = 0 To 4 - 1
              PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, 0)
            Next
          Next
        EndIf
      EndIf
    Next
  Next

  For i = 4 To *ycrcb\height - 4 - 1 Step 4
    For j = 4 To  *ycrcb\width - 4 - 1 Step 4
      nDilate = 0

      If PeekA(@*filter\imageData\b + i * *sum\widthStep + j) < 255
        For k = -4 To 5 - 1 Step 4
          For l = -4 To 5 - 1 Step 4
            If PeekA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l) = 255 : nDilate + 1 : EndIf
          Next
        Next

        If nDilate > nDilation2
          For k = 0 To 4 - 1
            For l = 0 To 4 - 1
              PokeA(@*filter\imageData\b + (i + k) * *filter\widthStep + j + l, 255)
            Next
          Next
        EndIf
      EndIf
    Next
  Next
EndProcedure

Procedure AverageFrame()
  cvRunningAvg(*filter, *hist, nWeighting / 255, #Null)
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  ColorSegmentation()
  DensityRegularisation()
  LuminanceRegularisation()
  GeometricCorrection()
  AverageFrame()
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
  cvNamedWindow(#CV_WINDOW_NAME + " - Skin Detection", #CV_WINDOW_AUTOSIZE)
  hWnd_control = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Skin Detection"))
  SendMessage_(hWnd_control, #WM_SETICON, 0, opencv)
  wStyle = GetWindowLongPtr_(hWnd_control, #GWL_STYLE)
  SetWindowLongPtr_(hWnd_control, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
  cvResizeWindow(#CV_WINDOW_NAME + " - Skin Detection", 320, 430)
  cvMoveWindow(#CV_WINDOW_NAME + " - Skin Detection", FrameWidth + 50, 20)
  nMinCr = 133 : nMaxCr = 173 : nMinCb = 77 : nMaxCb = 127 : nErosion1 = 4 : nDilation1 = 6
  nDeviation = 0 : nErosion2 = 4 : nDilation2 = 6 : nWeighting = 200
  cvCreateTrackbar("Min. Cr", #CV_WINDOW_NAME + " - Skin Detection", @nMinCr, 255, @CvTrackbarCallback())
  cvCreateTrackbar("Max. Cr", #CV_WINDOW_NAME + " - Skin Detection", @nMaxCr, 255, @CvTrackbarCallback())
  cvCreateTrackbar("Min. Cb", #CV_WINDOW_NAME + " - Skin Detection", @nMinCb, 255, @CvTrackbarCallback())
  cvCreateTrackbar("Max. Cb", #CV_WINDOW_NAME + " - Skin Detection", @nMaxCb, 255, @CvTrackbarCallback())
  cvCreateTrackbar("Erosion 1", #CV_WINDOW_NAME + " - Skin Detection", @nErosion1, 9, @CvTrackbarCallback())
  cvCreateTrackbar("Dilation 1", #CV_WINDOW_NAME + " - Skin Detection", @nDilation1, 9, @CvTrackbarCallback())
  cvCreateTrackbar("Deviation", #CV_WINDOW_NAME + " - Skin Detection", @nDeviation, 10, @CvTrackbarCallback())
  cvCreateTrackbar("Erosion 2", #CV_WINDOW_NAME + " - Skin Detection", @nErosion2, 9, @CvTrackbarCallback())
  cvCreateTrackbar("Dilation 2", #CV_WINDOW_NAME + " - Skin Detection", @nDilation2, 9, @CvTrackbarCallback())
  cvCreateTrackbar("Averaging", #CV_WINDOW_NAME + " - Skin Detection", @nWeighting, 255, @CvTrackbarCallback())
  *ycrcb = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *filter = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *sum = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *hist = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 1) : cvSetZero(*hist)
  *skin.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *mask.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *image.IplImage : BringWindowToTop(hWnd)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      Select nSkin
        Case 0
          cvShowImage(#CV_WINDOW_NAME, *image)
        Case 1
          cvCvtColor(*image, *ycrcb, #CV_BGR2YCrCb, 1)
          CvTrackbarCallback(#Null)
          cvShowImage(#CV_WINDOW_NAME, *hist)
        Case 2
          cvCvtColor(*image, *ycrcb, #CV_BGR2YCrCb, 1)
          CvTrackbarCallback(#Null)
          cvSetZero(*skin)
          cvConvert(*hist, *mask)
          cvCopy(*image, *skin, *mask)
          cvShowImage(#CV_WINDOW_NAME, *skin)
      EndSelect
      keyPressed = cvWaitKey(20)

      Select keyPressed
        Case 13
          cvSetTrackbarPos("Min. Cr", #CV_WINDOW_NAME + " - Skin Detection", 133)
          cvSetTrackbarPos("Max. Cr", #CV_WINDOW_NAME + " - Skin Detection", 173)
          cvSetTrackbarPos("Min. Cb", #CV_WINDOW_NAME + " - Skin Detection", 77)
          cvSetTrackbarPos("Max. Cb", #CV_WINDOW_NAME + " - Skin Detection", 127)
          cvSetTrackbarPos("Erosion 1", #CV_WINDOW_NAME + " - Skin Detection", 4)
          cvSetTrackbarPos("Dilation 1", #CV_WINDOW_NAME + " - Skin Detection", 6)
          cvSetTrackbarPos("Deviation", #CV_WINDOW_NAME + " - Skin Detection", 0)
          cvSetTrackbarPos("Erosion 2", #CV_WINDOW_NAME + " - Skin Detection", 4)
          cvSetTrackbarPos("Dilation 2", #CV_WINDOW_NAME + " - Skin Detection", 6)
          cvSetTrackbarPos("Averaging", #CV_WINDOW_NAME + " - Skin Detection", 200)
        Case 32
          nSkin = (nSkin + 1) % 3
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*skin)
  cvReleaseImage(@*hist)
  cvReleaseImage(@*sum)
  cvReleaseImage(@*filter)
  cvReleaseImage(@*ycrcb)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\