IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Add a motion-blur filter to an image blurring in only one direction." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch direction of blur." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          openCV = #True
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
        Case 2
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
      MenuItem(1, "Open")
      MenuBar()
      MenuItem(2, "Save")
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

    If *resize\width > 200 And *resize\height > 200
      Dim kernel1.d(81) : Dim kernel2.d(81) : Dim kernel3.d(81) : Dim kernel4.d(81)
      kernel1(0) = 1 : kernel1(10) = 1 : kernel1(20) = 1 : kernel1(30) = 1 : kernel1(40) = 1 : kernel1(50) = 1 : kernel1(60) = 1 : kernel1(70) = 1 : kernel1(80) = 1
      kernel2(4) = 1 : kernel2(13) = 1 : kernel2(22) = 1 : kernel2(31) = 1 : kernel2(40) = 1 : kernel2(49) = 1 : kernel2(58) = 1 : kernel2(67) = 1 : kernel2(76) = 1
      kernel3(8) = 1 : kernel3(16) = 1 : kernel3(24) = 1 : kernel3(32) = 1 : kernel3(40) = 1 : kernel3(48) = 1 : kernel3(56) = 1 : kernel3(64) = 1 : kernel3(72) = 1
      kernel4(36) = 1 : kernel4(37) = 1 : kernel4(38) = 1 : kernel4(39) = 1 : kernel4(40) = 1 : kernel4(41) = 1 : kernel4(42) = 1 : kernel4(43) = 1 : kernel4(44) = 1
      *kernel1.CvMat = cvCreateMatHeader(9, 9, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel1, @kernel1(), 0)
      *kernel2.CvMat = cvCreateMatHeader(9, 9, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel2, @kernel2(), 0)
      *kernel3.CvMat = cvCreateMatHeader(9, 9, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel3, @kernel3(), 0)
      *kernel4.CvMat = cvCreateMatHeader(9, 9, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel4, @kernel4(), 0)
      *filter.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_16S, *resize\nChannels)
      *blur.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *resize\nChannels)
      *reset.IplImage
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *resize\nChannels)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *blur
          Select nBlur
            Case 0
              cvFilter2D(*resize, *filter, *kernel1, -1, -1)
            Case 1
              cvFilter2D(*resize, *filter, *kernel2, -1, -1)
            Case 2
              cvFilter2D(*resize, *filter, *kernel3, -1, -1)
            Case 3
              cvFilter2D(*resize, *filter, *kernel4, -1, -1)
          EndSelect
          cvConvertScale(*filter, *blur, 1 / 9, 0)
          cvReleaseImage(@*reset)
          *reset = cvCloneImage(*blur)

          Select PIP
            Case 0
              cvSetImageROI(*blur, 20, 20, iWidth, iHeight)
              cvAndS(*blur, 0, 0, 0, 0, *blur, #Null)
              cvAdd(*blur, *PIP, *blur, #Null)
              cvResetImageROI(*blur)
              cvRectangleR(*blur, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*blur, *blur\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*blur, 0, 0, 0, 0, *blur, #Null)
              cvAdd(*blur, *PIP, *blur, #Null)
              cvResetImageROI(*blur)
              cvRectangleR(*blur, *blur\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          *param\Pointer1 = *blur
          cvShowImage(#CV_WINDOW_NAME, *blur)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              nBlur = (nBlur + 1) % 4
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*blur)
              *blur = cvCloneImage(*reset)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*blur)
      cvReleaseImage(@*filter)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/stitch1b.jpg")
; IDE Options = PureBasic 5.60 Beta 2 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\