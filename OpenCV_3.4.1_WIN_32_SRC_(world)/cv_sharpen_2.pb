IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Add various edge filters to an image giving it different sharpened effects (sharpen / excessive / realistic)." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Change sharpen filter." + #LF$ + #LF$ +
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
      Dim kernel1.d(9)
      kernel1(0) = -1 : kernel1(1) = -1 : kernel1(2) = -1
      kernel1(3) = -1 : kernel1(4) = 9 : kernel1(5) = -1
      kernel1(6) = -1 : kernel1(7) = -1 : kernel1(8) = -1
      *kernel1.CvMat = cvCreateMatHeader(3, 3, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel1, @kernel1(), 0)
      Dim kernel2.d(9)
      kernel2(0) = 1 : kernel2(1) = 1 : kernel2(2) = 1
      kernel2(3) = 1 : kernel2(4) = -7 : kernel2(5) = 1
      kernel2(6) = 1 : kernel2(7) = 1 : kernel2(8) = 1
      *kernel2.CvMat = cvCreateMatHeader(3, 3, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel2, @kernel2(), 0)
      Dim kernel3.d(25)
      kernel3(0) = -1 / 8 : kernel3(1) = -1 / 8 : kernel3(2) = -1 / 8 : kernel3(3) = -1 / 8 : kernel3(4) = -1 / 8
      kernel3(5) = -1 / 8 : kernel3(6) = 2 / 8 : kernel3(7) = 2 / 8 : kernel3(8) = 2 / 8 : kernel3(9) = -1 / 8
      kernel3(10) = -1 / 8 : kernel3(11) = 2 / 8 : kernel3(12) = 8 / 8 : kernel3(13) = 2 / 8 : kernel3(14) = -1 / 8
      kernel3(15) = -1 / 8 : kernel3(16) = 2 / 8 : kernel3(17) = 2 / 8 : kernel3(18) = 2 / 8 : kernel3(19) = -1 / 8
      kernel3(20) = -1 / 8 : kernel3(21) = -1 / 8 : kernel3(22) = -1 / 8 : kernel3(23) = -1 / 8 : kernel3(24) = -1 / 8
      *kernel3.CvMat = cvCreateMatHeader(5, 5, CV_MAKETYPE(#CV_64F, 1))
      cvSetData(*kernel3, @kernel3(), 0)
      *sharpen.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *resize\nChannels)
      cvFilter2D(*resize, *sharpen, *kernel1, -1, -1)
      *reset.IplImage = cvCloneImage(*sharpen)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *resize\nChannels)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *sharpen
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *sharpen
          Select PIP
            Case 0
              cvSetImageROI(*sharpen, 20, 20, iWidth, iHeight)
              cvAndS(*sharpen, 0, 0, 0, 0, *sharpen, #Null)
              cvAdd(*sharpen, *PIP, *sharpen, #Null)
              cvResetImageROI(*sharpen)
              cvRectangleR(*sharpen, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*sharpen, *sharpen\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*sharpen, 0, 0, 0, 0, *sharpen, #Null)
              cvAdd(*sharpen, *PIP, *sharpen, #Null)
              cvResetImageROI(*sharpen)
              cvRectangleR(*sharpen, *sharpen\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *sharpen)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              sharpen = (sharpen + 1) % 3

              Select sharpen
                Case 0
                  cvFilter2D(*resize, *sharpen, *kernel1, -1, -1)
                Case 1
                  cvFilter2D(*resize, *sharpen, *kernel2, -1, -1)
                Case 2
                  cvFilter2D(*resize, *sharpen, *kernel3, -1, -1)
              EndSelect
              cvReleaseImage(@*reset)
              *reset = cvCloneImage(*sharpen)
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*sharpen)
              *sharpen = cvCloneImage(*reset)
              *param\Pointer1 = *sharpen
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*sharpen)
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

OpenCV("images/weight3.jpg")
; IDE Options = PureBasic 5.60 Beta 2 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\