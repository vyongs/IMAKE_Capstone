IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draw a Spider Web sketch from a webcam frame." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Capture / Release frame." + #LF$ + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Save Spider Web image."

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

#ACCURACY = 100

Procedure TestColor(*image.IplImage, nTotal, nLocation)
  nB = PeekA(@*image\imageData\b + nLocation + 0)
  nG = PeekA(@*image\imageData\b + nLocation + 1)
  nR = PeekA(@*image\imageData\b + nLocation + 2)
  nPercent.f = nTotal / (nB + nG + nR) * 100

  If nPercent >= #ACCURACY : ProcedureReturn #True : Else : ProcedureReturn #False : EndIf

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
  *spiderweb.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If nSpiderWeb
        nDistance.f = 100
        nSpeed = 10000
        NewPixel = #True
        #MAX_TRIES = 1000
        #TESTS = 10
        cvSet(*spiderweb, 255, 255, 255, 0, #Null)

        Repeat
          If Not nStop
            If nDistance > 25 : nDistance - 0.1 : EndIf
            If nSpeed < 20000 : nSpeed + 1 : EndIf

            For rtnCount = 0 To nSpeed - 1
              If NewPixel Or nTries > #MAX_TRIES
                NewPixel = #False : nTries = 0
                nLocation = Random(*image\width - 1) * 3 + Random(*image\height - 1) * *image\widthStep
                x1 = nLocation % *image\widthStep / 3
                y1 = nLocation / *image\widthStep 
                nB = PeekA(@*image\imageData\b + nLocation + 0)
                nG = PeekA(@*image\imageData\b + nLocation + 1)
                nR = PeekA(@*image\imageData\b + nLocation + 2)
                nTotal = nB + nG + nR
              EndIf
              nLocation = Random(*image\width - 1) * 3 + Random(*image\height - 1) * *image\widthStep

              If TestColor(*image, nTotal, nLocation)
                x2 = nLocation % *image\widthStep / 3
                y2 = nLocation / *image\widthStep

                If Sqr((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)) <= nDistance
                  cvLine(*spiderweb, x1, y1, x2, y2, nB, nG, nR, 0, 1, 8, #Null) : nCount + 1
                EndIf
              EndIf

              If nCount > #TESTS : NewPixel = #True : nCount = 0 : EndIf

              nTries + 1
            Next
          EndIf
          cvShowImage(#CV_WINDOW_NAME, *spiderweb)

          If nStop : keyPressed = cvWaitKey(0) : Else : keyPressed = cvWaitKey(10) : EndIf

          Select keyPressed
            Case 32
              nStop ! #True : If Not nStop : Break : EndIf
            Case 83, 115
              If FileSize("../Frames") <> -2 : CreateDirectory("../Frames") : EndIf

              SaveDate.s = FormatDate("%yyyy-%mm-%dd %hh-%ii-%ss", Date())
              cvSaveImage("../Frames/" + SaveDate + "_SpiderWeb.jpg", *spiderweb, #Null)
          EndSelect
        Until keyPressed = 27 Or exitCV
      Else
        cvShowImage(#CV_WINDOW_NAME, *image)
        keyPressed = cvWaitKey(100)
      EndIf

      If keyPressed = 32 : nSpiderWeb ! #True : EndIf

    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*spiderweb)
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