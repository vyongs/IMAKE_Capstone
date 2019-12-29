IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Finds the positions of internal corners for a 10 x 7 chessboard pattern, drawing a transparent cube in 3D space." + #LF$ + #LF$ +
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
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)
  #CORNER_ROW = 6
  #CORNER_COL = 9
  #IMAGE_SIZE = 25
  #PATTERN_SIZE = #CORNER_ROW * #CORNER_COL
  #ALL_POINTS = #IMAGE_SIZE * #PATTERN_SIZE
  Dim corners.CvPoint2D32f(#ALL_POINTS)
  Dim points(#IMAGE_SIZE)
  *source.IplImage
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
  DBL_EPSILON.d = 2.2204460492503131 * Pow(10, -16)

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
    cvPutText(*image, "Drawing Transparent Cube...", 10, 30, @font, 0, 255, 255, 0)
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
    cvCalibrateCamera2(*object_points, *image_points, *point_counts, FrameWidth, FrameHeight, *camera_matrix, *distortion_coeffs, *rotation_vectors, *translation_vectors, #CV_CALIB_FIX_PRINCIPAL_POINT, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 30, DBL_EPSILON)
    cvReleaseMat(@*translation_vectors)
    cvReleaseMat(@*rotation_vectors)
    Dim objects_forLoop.CvPoint3D32f(#PATTERN_SIZE)
    Dim corners_forLoop.CvPoint2D32f(#PATTERN_SIZE)

    For i = 0 To #CORNER_ROW - 1
      For j = 0 To #CORNER_COL - 1
        objects_forLoop(i * #CORNER_COL + j)\x = i * #CHESS_LENGTH
        objects_forLoop(i * #CORNER_COL + j)\y = j * #CHESS_LENGTH
        objects_forLoop(i * #CORNER_COL + j)\z = 0.0
      Next
    Next
    *srcPoints3D.CvMat = cvCreateMat(8, 1, CV_MAKETYPE(#CV_32F, 3))
    cube_size = 5

    For i = 0 To 8 - 1
      Select i
        Case 0
          PokeF(*srcPoints3D\fl, 0)
          PokeF(*srcPoints3D\fl + 4, 0)
          PokeF(*srcPoints3D\fl + 8, 0)
        Case 1
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, 0)
        Case 2
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, 0)
        Case 3
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, 0)
        Case 4
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, cube_size * #CHESS_LENGTH)
        Case 5
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, cube_size * #CHESS_LENGTH)
        Case 6
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, cube_size * #CHESS_LENGTH)
        Case 7
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step, 0)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 4, cube_size * #CHESS_LENGTH)
          PokeF(*srcPoints3D\fl + i * *srcPoints3D\Step + 8, cube_size * #CHESS_LENGTH)
        Case 8
          PokeF(*srcPoints3D\fl, 0)
          PokeF(*srcPoints3D\fl + 4, 0)
          PokeF(*srcPoints3D\fl + 8, 0)
      EndSelect
    Next
    *rotation_vectors.CvMat = cvCreateMat(1, 3, CV_MAKETYPE(#CV_32F, 1))
    *translation_vectors.CvMat = cvCreateMat(1, 3, CV_MAKETYPE(#CV_32F, 1))
    *dstPoints2D.CvMat = cvCreateMat(8, 1, CV_MAKETYPE(#CV_32F, 2))

    Repeat
      *image = cvQueryFrame(*capture)

      If *image
        cvFlip(*image, #Null, 1)
        cvReleaseImage(@*source)
        *source = cvCloneImage(*image)
        cvCvtColor(*source, *gray, #CV_BGR2GRAY, 1)

        If cvCheckChessboard(*gray, #CORNER_COL, #CORNER_ROW)
          found = cvFindChessboardCorners(*source, #CORNER_COL, #CORNER_ROW, @corners_forLoop(), @corner_count, #CV_CALIB_CB_ADAPTIVE_THRESH | #CV_CALIB_CB_FILTER_QUADS)

          If found
            cvFindCornerSubPix(*gray, @corners_forLoop(), corner_count, 11, 11, -1, -1, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03)
            *object_points = cvMat(1, #PATTERN_SIZE, CV_MAKETYPE(#CV_32F, 3), @objects_forLoop())
            *image_points = cvMat(1, #PATTERN_SIZE, CV_MAKETYPE(#CV_32F, 2), @corners_forLoop())
            cvFindExtrinsicCameraParams2(*object_points, *image_points, *camera_matrix, *distortion_coeffs, *rotation_vectors, *translation_vectors, #CV_ITERATIVE)
            cvProjectPoints2(*srcPoints3D, *rotation_vectors, *translation_vectors, *camera_matrix, *distortion_coeffs, *dstPoints2D, #Null, #Null, #Null, #Null, #Null, 0)

            For i = 0 To 2 - 1
              For j = 0 To 4 - 1
                If j = 3
                  startpointX = PeekF(@*dstPoints2D\fl\f + (i * 4 + j) * *dstPoints2D\Step)
                  startpointY = PeekF(@*dstPoints2D\fl\f + 4 + (i * 4 + j) * *dstPoints2D\Step)
                  endpointX = PeekF(@*dstPoints2D\fl\f + (i * 4) * *dstPoints2D\Step)
                  endpointY = PeekF(@*dstPoints2D\fl\f + 4 + (i * 4) * *dstPoints2D\Step)
                Else
                  startpointX = PeekF(@*dstPoints2D\fl\f + (i * 4 + j) * *dstPoints2D\Step)
                  startpointY = PeekF(@*dstPoints2D\fl\f + 4 + (i * 4 + j) * *dstPoints2D\Step)
                  endpointX = PeekF(@*dstPoints2D\fl\f + (i * 4 + j + 1) * *dstPoints2D\Step)
                  endpointY = PeekF(@*dstPoints2D\fl\f + 4 + (i * 4 + j + 1) * *dstPoints2D\Step)
                EndIf
                cvLine(*source, startpointX, startpointY, endpointX, endpointY, 0, 255, 0, 0, 2, #CV_AA, #Null)
              Next
            Next

            For i = 0 To 4 - 1
              startpointX = PeekF(@*dstPoints2D\fl\f + i * *dstPoints2D\Step)
              startpointY = PeekF(@*dstPoints2D\fl\f + 4 + i * *dstPoints2D\Step)
              endpointX = PeekF(@*dstPoints2D\fl\f + (i + 4) * *dstPoints2D\Step)
              endpointY = PeekF(@*dstPoints2D\fl\f + 4 + (i + 4) * *dstPoints2D\Step)
              cvLine(*source, startpointX, startpointY, endpointX, endpointY, 0, 255, 0, 0, 2, #CV_AA, #Null)
            Next
          EndIf
        EndIf
        cvShowImage(#CV_WINDOW_NAME, *source)
        keyPressed = cvWaitKey(100)
      EndIf
    Until keyPressed = 27 Or exitCV
    cvReleaseMat(@*dstPoints2D)
    cvReleaseMat(@*srcPoints3D)
    cvReleaseMat(@*translation_vectors)
    cvReleaseMat(@*rotation_vectors)
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
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\