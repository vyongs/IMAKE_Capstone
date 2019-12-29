IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates a perspective transform from four pairs of corresponding points." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

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
    Dim srcPoint.CvPoint2D32f(4)
    Dim dstPoint.CvPoint2D32f(4)
    srcPoint(0)\x = 93
    srcPoint(0)\y = 90
    srcPoint(1)\x = 20
    srcPoint(1)\y = 422
    srcPoint(2)\x = 501
    srcPoint(2)\y = 468
    srcPoint(3)\x = 408
    srcPoint(3)\y = 43
    dstPoint(0)\x = 0
    dstPoint(0)\y = 0
    dstPoint(1)\x = 0
    dstPoint(1)\y = *resize\height - 1
    dstPoint(2)\x = *resize\width - 1
    dstPoint(2)\y = *resize\height - 1
    dstPoint(3)\x = *resize\width - 1
    dstPoint(3)\y = 0
    *srcPoint.CvMat = cvMat(4, 2, CV_MAKETYPE(#CV_32F, 1), srcPoint())
    *dstPoint.CvMat = cvMat(4, 2, CV_MAKETYPE(#CV_32F, 1), dstPoint())
    *homography.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
    *warp.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
    cvFindHomography(*srcPoint, *dstPoint, *homography, 0, 3, 0)
    cvWarpPerspective(*image, *warp, *homography, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)
    *reset.IplImage = cvCloneImage(*warp)
    iRatio.d = 150 / *resize\width
    iWidth = *resize\width * iRatio
    iHeight = *resize\height * iRatio
    *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
    cvResize(*image, *PIP, #CV_INTER_AREA)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *warp
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *warp
        Select PIP
          Case 0
            cvSetImageROI(*warp, 20, 20, iWidth, iHeight)
            cvAndS(*warp, 0, 0, 0, 0, *warp, #Null)
            cvAdd(*warp, *PIP, *warp, #Null)
            cvResetImageROI(*warp)
            cvRectangleR(*warp, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          Case 1
            cvSetImageROI(*warp, *warp\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*warp, 0, 0, 0, 0, *warp, #Null)
            cvAdd(*warp, *PIP, *warp, #Null)
            cvResetImageROI(*warp)
            cvRectangleR(*warp, *warp\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
        EndSelect
        cvShowImage(#CV_WINDOW_NAME, *warp)
        keyPressed = cvWaitKey(0)

        If keyPressed = 86 Or keyPressed = 118
          PIP = (PIP + 1) % 3
          cvReleaseImage(@*warp)
          *warp = cvCloneImage(*reset)
          *param\Pointer1 = *warp
        EndIf
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*PIP)
    cvReleaseImage(@*reset)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/perspective.jpg")
; IDE Options = PureBasic 5.31 Beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\