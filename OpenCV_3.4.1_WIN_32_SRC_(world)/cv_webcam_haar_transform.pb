IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Builds a direct and inverse Haar wavelet transform." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle direct / inverse." + #LF$ + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Shrinkage (inverse only)."

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

Procedure HaarWavelet(*src.CvMat, *dst.CvMat, nIterations)
  width = *src\cols : height = *src\rows

  For k = 0 To nIterations - 1
    For y = 0 To (height >> (k + 1)) - 1
      For x = 0 To (width >> (k + 1)) - 1
        c.f = (cvmGet(*src, 2 * y, 2 * x) + cvmGet(*src, 2 * y, 2 * x + 1) + cvmGet(*src, 2 * y + 1, 2 * x) + cvmGet(*src, 2 * y + 1, 2 * x + 1)) * 0.5
        cvmSet(*dst, y, x, c)
        dh.f = (cvmGet(*src, 2 * y, 2 * x) + cvmGet(*src, 2 * y + 1, 2 * x) - cvmGet(*src, 2 * y, 2 * x + 1) - cvmGet(*src, 2 * y + 1, 2 * x + 1)) * 0.5
        cvmSet(*dst, y, x + (width >> (k + 1)), dh)
        dv.f = (cvmGet(*src, 2 * y, 2 * x) + cvmGet(*src, 2 * y, 2 * x + 1) - cvmGet(*src, 2 * y + 1, 2 * x) - cvmGet(*src, 2 * y + 1, 2 * x + 1)) * 0.5
        cvmSet(*dst, y + (height >> (k + 1)), x, dv)
        dd.f = (cvmGet(*src, 2 * y, 2 * x) - cvmGet(*src, 2 * y, 2 * x + 1) - cvmGet(*src, 2 * y + 1, 2 * x) + cvmGet(*src, 2 * y + 1, 2 * x + 1)) * 0.5
        cvmSet(*dst, y + (height >> (k + 1)), x + (width >> (k + 1)), dd)
      Next
    Next
    cvCopy(*dst, *src, #Null)
  Next
EndProcedure

Procedure.f Signum(x.f)
  Select #True
    Case Bool(x = 0)
      ProcedureReturn 0
    Case Bool(x > 0)
      ProcedureReturn 1
    Case Bool(x < 0)
      ProcedureReturn -1
  EndSelect
EndProcedure

Procedure.f HardShrink(d.f, T.f)
  If Abs(d) > T : ProcedureReturn d : Else : ProcedureReturn 0 : EndIf
EndProcedure

Procedure.f SoftShrink(d.f, T.f)
  If Abs(d) > T : ProcedureReturn Signum(d) * (Abs(d) - T) : Else : ProcedureReturn 0 : EndIf
EndProcedure

Procedure.f GarrotShrink(d.f, T.f)
  If Abs(d) > T : ProcedureReturn d - T * T / d : Else : ProcedureReturn 0 : EndIf
EndProcedure

#NONE = 0
#HARD = 1
#SOFT = 2
#GARROTE = 3

Procedure InverseHaarWavelet(*src.CvMat, *dst.CvMat, nIterations, SHRINKAGE_TYPE, SHRINKAGE_T.f)
  width = *src\cols : height = *src\rows
  *D.CvMat : *S.CvMat
  temp1.CvMat : temp2.CvMat

  For k = nIterations To 1 Step -1
    For y = 0 To (height >> k) - 1
      For x = 0 To (width >> k) - 1
        c.f = cvmGet(*src, y, x)
        dh.f = cvmGet(*src, y, x + (width >> k))
        dv.f = cvmGet(*src, y + (height >> k), x)
        dd.f = cvmGet(*src, y + (height >> k), x + (width >> k))

        Select SHRINKAGE_TYPE
          Case #HARD
            dh = HardShrink(dh, SHRINKAGE_T)
            dv = HardShrink(dv, SHRINKAGE_T)
            dd = HardShrink(dd, SHRINKAGE_T)
          Case #SOFT
            dh = SoftShrink(dh, SHRINKAGE_T)
            dv = SoftShrink(dv, SHRINKAGE_T)
            dd = SoftShrink(dd, SHRINKAGE_T)
          Case #GARROTE
            dh = GarrotShrink(dh, SHRINKAGE_T)
            dv = GarrotShrink(dv, SHRINKAGE_T)
            dd = GarrotShrink(dd, SHRINKAGE_T)
        EndSelect
        cvmSet(*dst, 2 * y, 2 * x, 0.5 * (c + dh + dv + dd))
        cvmSet(*dst, 2 * y, 2 * x + 1, 0.5 * (c - dh + dv - dd))
        cvmSet(*dst, 2 * y + 1, 2 * x, 0.5 * (c + dh - dv - dd))
        cvmSet(*dst, 2 * y + 1, 2 * x + 1, 0.5 * (c - dh - dv + dd))
      Next
    Next
    *D = cvGetSubRect(*dst, @temp1, 0, 0, width >> (k - 1), height >> (k - 1))
    *S = cvGetSubRect(*src, @temp2, 0, 0, width >> (k - 1), height >> (k - 1))
    cvCopy(*D, *S, #Null)
  Next
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
  nIterations = 4
  *gray.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_8U, 1))
  *src.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  *dst.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  *temp.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  *filtered.CvMat = cvCreateMat(FrameHeight, FrameWidth, CV_MAKETYPE(#CV_32F, 1))
  convert.CvMat : *convert.CvMat : *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      *convert = cvGetMat(*image, @convert, #Null, 0)
      cvCvtColor(*convert, *gray, #CV_BGR2GRAY, 1)
      cvConvert(*gray, *src) : cvSetZero(*dst)
      HaarWavelet(*src, *dst, nIterations)

      If filter
        cvCopy(*dst, *temp, #Null)
        InverseHaarWavelet(*temp, *filtered, nIterations, SHRINKAGE_TYPE, 30)
        cvMinMaxLoc(*filtered, @min_val.d, @max_val.d, #Null, #Null, #Null)

        If max_val - min_val > 0 : cvConvertScale(*filtered, *filtered, 1 / (max_val - min_val), 1 * -min_val / (max_val - min_val)) : EndIf

        cvShowImage(#CV_WINDOW_NAME, *filtered)
      Else
        cvMinMaxLoc(*dst, @min_val.d, @max_val.d, #Null, #Null, #Null)

        If max_val - min_val > 0 : cvConvertScale(*dst, *dst, 1 / (max_val - min_val), 1 * -min_val / (max_val - min_val)) : EndIf

        cvShowImage(#CV_WINDOW_NAME, *dst)
      EndIf
      keyPressed = cvWaitKey(5)

      Select keyPressed
        Case 32
          filter ! #True
        Case 83, 115
          If filter : SHRINKAGE_TYPE = (SHRINKAGE_TYPE + 1) % 4 : Else : SHRINKAGE_TYPE = 0 : EndIf
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  cvReleaseMat(@*filtered)
  cvReleaseMat(@*temp)
  cvReleaseMat(@*dst)
  cvReleaseMat(@*src)
  cvReleaseMat(@*gray)
  FreeMemory(*param)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\