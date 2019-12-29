IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, FrameWidth, FrameHeight, nSpread

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Apply a pixel spread effect to a webcam stream." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust pixel spread."

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

ProcedureC CvTrackbarCallback(pos)  
  nSpread = FrameWidth * (pos * 0.002)
EndProcedure

Procedure SpreadPixels(*image.IplImage, *spread.IplImage)
  nHalfSpread = nSpread / 2

  For y = 0 To FrameHeight - 1
    For x = 0 To FrameWidth - 1
      nRandomX.f = Random(2147483647) / 2147483647
      nRandomY.f = Random(2147483647) / 2147483647
      nRX = nRandomX * nSpread - nHalfSpread
      nRY = nRandomY * nSpread - nHalfSpread
      nX = x + nRX : nY = y + nRY

      If nX < 0 : nX = 0 : EndIf : If nX > FrameWidth - 1 : nX = FrameWidth - 1 : EndIf
      If nY < 0 : nY = 0 : EndIf : If nY > FrameHeight - 1 : nY = FrameHeight - 1 : EndIf

      nB = PeekA(@*image\imageData\b + (y * *image\widthStep) + x * 3 + 0)
      nG = PeekA(@*image\imageData\b + (y * *image\widthStep) + x * 3 + 1)
      nR = PeekA(@*image\imageData\b + (y * *image\widthStep) + x * 3 + 2)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 0, nB)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 1, nG)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 2, nR)
    Next
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
  cvResizeWindow(#CV_WINDOW_NAME, FrameWidth, FrameHeight + 48)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  cvCreateTrackbar("Spread", #CV_WINDOW_NAME, @nSpread, 100, @CvTrackbarCallback())
  *spread.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      SpreadPixels(*image, *spread)
      cvShowImage(#CV_WINDOW_NAME, *spread)
      keyPressed = cvWaitKey(10)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*spread)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\