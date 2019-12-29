IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Generates the top view of a chessboard pattern from its perspective view." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch to top view." + #LF$ + #LF$ +
                  "[ < ] KEY   " + #TAB$ + ": Adjust Z-height (zoom out)." + #LF$ +
                  "[ > ] KEY   " + #TAB$ + ": Adjust Z-height (zoom in)."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          FileName.s = SaveCVImage()

          If FileName
            params.CvSaveData

            Select LCase(GetExtensionPart(FileName))
              Case "bmp", "dib"
              Case "jpeg", "jpg", "jpe"
                params\paramId = #CV_IMWRITE_JPEG_QUALITY
                params\paramValue = 95
              Case "jp2"
              Case "png"
                params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                params\paramValue = 3
              Case "ppm", "pgm", "pbm"
                params\paramId = #CV_IMWRITE_PXM_BINARY
                params\paramValue = 1
              Case "sr", "ras"
              Case "tiff", "tif"
              Default
                Select SelectedFilePattern()
                  Case 0
                    FileName + ".bmp"
                  Case 1
                    FileName + ".jpg"
                    params\paramId = #CV_IMWRITE_JPEG_QUALITY
                    params\paramValue = 95
                  Case 2
                    FileName + ".jp2"
                  Case 3
                    FileName + ".png"
                    params\paramId = #CV_IMWRITE_PNG_COMPRESSION
                    params\paramValue = 3
                  Case 4
                    FileName + ".ppm"
                    params\paramId = #CV_IMWRITE_PXM_BINARY
                    params\paramValue = 1
                  Case 5
                    FileName + ".sr"
                  Case 6
                    FileName + ".tiff"
                EndSelect
            EndSelect
            cvSaveImage(FileName, *save, @params)
          EndIf
        Case 10
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
  EndSelect
EndProcedure

Procedure OpenCV(ImageFile.s)
  If FileSize(ImageFile) > 0
    cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
    window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
    *window_name = cvGetWindowName(window_handle)
    lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

    If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
      MenuItem(1, "Save")
      MenuBar()
      MenuItem(10, "Exit")
    EndIf
    hWnd = GetParent_(window_handle)
    iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
    SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
    wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
    SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - 100
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *image\width
      iHeight = dtHeight - 100
      iRatio2.d = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)
    *intrinsic.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
    cvmSet(*intrinsic, 0, 0, 418.7490)
    cvmSet(*intrinsic, 0, 1, 0)
    cvmSet(*intrinsic, 0, 2, 236.8528)
    cvmSet(*intrinsic, 1, 0, 0)
    cvmSet(*intrinsic, 1, 1, 558.6650)
    cvmSet(*intrinsic, 1, 2, 322.7346)
    cvmSet(*intrinsic, 2, 0, 0)
    cvmSet(*intrinsic, 2, 1, 0)
    cvmSet(*intrinsic, 2, 2, 1)
    *distortion.CvMat = cvCreateMat(1, 4, CV_MAKETYPE(#CV_32F, 1))
    cvmSet(*distortion, 0, 0, -0.0019)
    cvmSet(*distortion, 0, 1, 0.0161)
    cvmSet(*distortion, 0, 2, 0.0011)
    cvmSet(*distortion, 0, 3, -0.0016)
    *mapx.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
    *mapy.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
    cvInitUndistortMap(*intrinsic, *distortion, *mapx, *mapy)
    *temp.IplImage = cvCloneImage(*resize)
    cvRemap(*temp, *resize, *mapx, *mapy, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)
    board_w = 3
    board_h = 4
    board_n = board_w * board_h
    Dim corners.CvPoint2D32f(board_n)
    found = cvFindChessboardCorners(*resize, board_w, board_h, @corners(), @corner_count, #CV_CALIB_CB_ADAPTIVE_THRESH | #CV_CALIB_CB_FILTER_QUADS)

    If found
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
      cvFindCornerSubPix(*gray, @corners(), corner_count, 11, 11, -1, -1, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 20, 0.03)
      Dim imgPts.CvPoint2D32f(4)
      imgPts(0) = corners(0)
      imgPts(1) = corners(board_w - 1)
      imgPts(2) = corners((board_h - 1) * board_w)
      imgPts(3) = corners((board_h - 1) * board_w + board_w - 1)
      Dim objPts.CvPoint2D32f(4)
      objPts(0)\x = 0
      objPts(0)\y = 0
      objPts(1)\x = board_w - 1
      objPts(1)\y = 0
      objPts(2)\x = 0
      objPts(2)\y = board_h - 1
      objPts(3)\x = board_w - 1
      objPts(3)\y = board_h - 1
      cvCircle(*resize, imgPts(0)\x, imgPts(0)\y, 9, 255, 0, 0, 0, 3, #CV_AA, #Null)
      cvCircle(*resize, imgPts(1)\x, imgPts(1)\y, 9, 0, 255, 0, 0, 3, #CV_AA, #Null)
      cvCircle(*resize, imgPts(2)\x, imgPts(2)\y, 9, 0, 0, 255, 0, 3, #CV_AA, #Null)
      cvCircle(*resize, imgPts(3)\x, imgPts(3)\y, 9, 0, 255, 255, 0, 3, #CV_AA, #Null)
      cvDrawChessboardCorners(*resize, board_w, board_h, @corners(), corner_count, found)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        cvShowImage(#CV_WINDOW_NAME, *resize)
        keyPressed = cvWaitKey(0)
      Until keyPressed = 27 Or keyPressed = 32 Or exitCV

      If keyPressed = 32
        *H.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
        cvGetPerspectiveTransform(objPts(), imgPts(), *H)
        Z.f = 23
        *birds.IplImage = cvCloneImage(*resize)
        *param\Pointer1 = *birds

        Repeat
          If *resize
            cvmSet(*H, 2, 2, Z)
            cvWarpPerspective(*resize, *birds, *H, #CV_INTER_LINEAR | #CV_WARP_INVERSE_MAP | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *birds)
            keyPressed = cvWaitKey(0)

            Select keyPressed
              Case 44, 60
                Z - 0.5
              Case 46, 62
                Z + 0.5
            EndSelect
          EndIf
        Until keyPressed = 27 Or exitCV
      EndIf
      FreeMemory(*param)
      cvReleaseImage(@*birds)
      cvReleaseMat(@*H)
      cvReleaseImage(@*gray)
    EndIf
    cvReleaseImage(@*temp)
    cvReleaseImage(@*mapy)
    cvReleaseImage(@*mapx)
    cvReleaseMat(@*distortion)
    cvReleaseMat(@*intrinsic)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/topview.png")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\