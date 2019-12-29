IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, hWnd_undistort

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calibrate webcam with a 10 x 7 chessboard pattern, displaying the raw and undistorted images." + #LF$ + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Save image pair." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage to a usable chessboard pattern."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      SendMessage_(hWnd_undistort, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://www.clipartbest.com/cliparts/RiA/5yo/RiA5yoKiL.png")
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
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
  #CORNER_ROW = 6
  #CORNER_COL = 9
  #IMAGE_SIZE = 25
  #PATTERN_SIZE = #CORNER_ROW * #CORNER_COL
  #ALL_POINTS = #IMAGE_SIZE * #PATTERN_SIZE
  Dim corners.CvPoint2D32f(#ALL_POINTS)
  Dim points(#IMAGE_SIZE)
  *source.IplImage
  *image.IplImage
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  DBL_EPSILON.d = 2.2204460492503131 * Pow(10, -16)
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)

  While found_num < #IMAGE_SIZE
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvReleaseImage(@*source)
      *source = cvCloneImage(*image)
      cvCvtColor(*source, *gray, #CV_BGR2GRAY, 1)

      If cvCheckChessboard(*gray, #CORNER_COL, #CORNER_ROW)
        found = cvFindChessboardCorners(*source, #CORNER_COL, #CORNER_ROW, @corners(found_num * #PATTERN_SIZE), @corner_count, #CV_CALIB_CB_ADAPTIVE_THRESH | #CV_CALIB_CB_FILTER_QUADS)

        If found
          cvFindCornerSubPix(*gray, @corners(found_num * #PATTERN_SIZE), corner_count, 3, 3, -1, -1, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03)
          cvDrawChessboardCorners(*source, #CORNER_COL, #CORNER_ROW, @corners(found_num * #PATTERN_SIZE), corner_count, found)
          points(found_num) = corner_count
          found_num + 1
        EndIf
      EndIf
      cvPutText(*source, "Found " + Str(found_num) + "/" + Str(#IMAGE_SIZE) + " Chessboard Images", 10, 30, @font, 0, 255, 255, 0)
      cvShowImage(#CV_WINDOW_NAME, *source)
      keyPressed = cvWaitKey(100)
    EndIf

    If keyPressed = 27 Or exitCV : Break : EndIf

  Wend

  If found_num = #IMAGE_SIZE
    cvPutText(*image, "Calibrating Camera...", 10, 30, @font, 0, 255, 255, 0)
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(100)
    Dim objects.CvPoint3D32f(#ALL_POINTS)
    #CHESS_LENGTH = 24

    For i = 0 To #IMAGE_SIZE - 1
      For j = 0 To #CORNER_ROW - 1
        For k = 0 To #CORNER_COL - 1
          objects(i * #PATTERN_SIZE + j * #CORNER_COL + k)\x = j * #CHESS_LENGTH
          objects(i * #PATTERN_SIZE + j * #CORNER_COL + k)\y = k * #CHESS_LENGTH
          objects(i * #PATTERN_SIZE + j * #CORNER_COL + k)\z = 0.0
        Next
      Next
    Next
    *object_points.CvMat = cvMat(1, #ALL_POINTS, CV_MAKETYPE(#CV_32F, 3), @objects())
    *image_points.CvMat = cvMat(1, #ALL_POINTS, CV_MAKETYPE(#CV_32F, 2), @corners())
    *point_counts.CvMat = cvMat(1, #IMAGE_SIZE, CV_MAKETYPE(#CV_32S, 1), @points())
    *camera_matrix.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
    *distortion_coeffs.CvMat = cvCreateMat(4, 1, CV_MAKETYPE(#CV_32F, 1))
    *rotation_vectors.CvMat = cvCreateMat(#IMAGE_SIZE, 3, CV_MAKETYPE(#CV_32F, 1))
    *translation_vectors.CvMat = cvCreateMat(#IMAGE_SIZE, 3, CV_MAKETYPE(#CV_32F, 1))
    cvCalibrateCamera2(*object_points, *image_points, *point_counts, FrameWidth, FrameHeight, *camera_matrix, *distortion_coeffs, *rotation_vectors, *translation_vectors, #CV_CALIB_FIX_PRINCIPAL_POINT, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 50, DBL_EPSILON)
    cvReleaseMat(@*translation_vectors)
    cvReleaseMat(@*rotation_vectors)
    *mapx.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 1)
    *mapy.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 1)
    cvInitUndistortMap(*camera_matrix, *distortion_coeffs, *mapx, *mapy)
    cvNamedWindow(#CV_WINDOW_NAME + " - Undistorted Image", #CV_WINDOW_AUTOSIZE)
    hWnd_undistort = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Undistorted Image"))
    SendMessage_(hWnd_undistort, #WM_SETICON, 0, opencv)
    wStyle = GetWindowLongPtr_(hWnd_undistort, #GWL_STYLE)
    SetWindowLongPtr_(hWnd_undistort, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
    cvResizeWindow(#CV_WINDOW_NAME + " - Undistorted Image", FrameWidth, FrameHeight)
    cvMoveWindow(#CV_WINDOW_NAME + " - Undistorted Image", *image\width + 50, 20)

    Repeat
      *image = cvQueryFrame(*capture)

      If *image
        cvFlip(*image, #Null, 1)
        cvReleaseImage(@*undistort)
        *undistort = cvCloneImage(*image)
        cvUndistort2(*image, *undistort, *camera_matrix, *distortion_coeffs, #Null)
        cvShowImage(#CV_WINDOW_NAME, *image)
        cvShowImage(#CV_WINDOW_NAME + " - Undistorted Image", *undistort)
      EndIf
      keyPressed = cvWaitKey(100)

      If keyPressed = 83 Or keyPressed = 115
        If FileSize("../ImagePairs") <> -2 : CreateDirectory("../ImagePairs") : EndIf

        SaveDate.s = FormatDate("%yyyy-%mm-%dd %hh-%ii-%ss", Date())
        cvSaveImage("../ImagePairs/" + SaveDate + "_Raw.jpg", *image, #Null)
        cvSaveImage("../ImagePairs/" + SaveDate + "_Undistorted.jpg", *undistort, #Null)
      EndIf
    Until keyPressed = 27 Or exitCV
    cvReleaseImage(@*mapy)
    cvReleaseImage(@*mapx)
    cvReleaseMat(@*distortion_coeffs)
    cvReleaseMat(@*camera_matrix)
  EndIf
  FreeMemory(*param)
  cvReleaseImage(@*gray)
  cvReleaseImage(@*source)
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