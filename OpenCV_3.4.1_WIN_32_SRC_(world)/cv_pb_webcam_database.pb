IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Captures and saves webcam frames to a database, displaying a thumbnail version of the image loaded from the database." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Capture image frame." + #LF$ + #LF$ +
                  "[ < ] KEY   " + #TAB$ + ": Show pevious image." + #LF$ +
                  "[ > ] KEY   " + #TAB$ + ": Show next image." + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

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

UseSQLiteDatabase() : UseJPEGImageEncoder() : UseJPEGImageDecoder() : UsePNGImageEncoder() : UsePNGImageDecoder()

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
  iRatio.d = 150 / FrameWidth
  iWidth = FrameWidth * iRatio
  iHeight = FrameHeight * iRatio
  *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
  dbName.s = GetDBName()

  If dbName
    *dbimage.IplImage = GetDBImage(dbName)
    cvResize(*dbimage, *PIP, #CV_INTER_AREA)
  EndIf
  *import.IplImage : *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      Select keyPressed
        Case 32
          cvReleaseImage(@*import)
          *import = cvCloneImage(*image)
          dbName = ImportImage(*import, "JHPJHP")
          *dbimage = GetDBImage(dbName)
          cvResize(*dbimage, *PIP, #CV_INTER_AREA)
        Case 44, 60
          dbName = GetDBName(1, dbName)

          If dbName
            *dbimage = GetDBImage(dbName)
            cvResize(*dbimage, *PIP, #CV_INTER_AREA)
          EndIf
        Case 46, 62
          dbName = GetDBName(2, dbName)

          If dbName
            *dbimage = GetDBImage(dbName)
            cvResize(*dbimage, *PIP, #CV_INTER_AREA)
          EndIf
      EndSelect

      If dbName
        Select PIP
          Case 0
            cvSetImageROI(*image, 20, 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          Case 1
            cvSetImageROI(*image, *image\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
        EndSelect
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)

      If keyPressed = 86 Or keyPressed = 118 : PIP = (PIP + 1) % 3 : EndIf

    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*PIP)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\