IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nThin

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "A five stage two-dimensional filter applied to a grayscale image producing a skeleton effect." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Show the next stage." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch to next image." + #LF$ + #LF$ +
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
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_GRAYSCALE)
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
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        cvShowImage(#CV_WINDOW_NAME, *resize)
        keyPressed = cvWaitKey(0)
      Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

      If keyPressed = 32
        Dim L0.f(25) : Dim L45.f(25) : Dim L90.f(25) : Dim L135.f(25)
        L0(0) = -1 : L0(1) = -1 : L0(2) = -1 : L0(3) = -1 : L0(4) = -1
        L0(5) = 0 : L0(6) = 0 : L0(7) = 0 : L0(8) = 0 : L0(9) = 0
        L0(10) = 2 : L0(11) = 2 : L0(12) = 2 : L0(13) = 2 : L0(14) = 2
        L0(15) = 0 : L0(16) = 0 : L0(17) = 0 : L0(18) = 0 : L0(19) = 0
        L0(20) = -1 : L0(21) = -1 : L0(22) = -1 : L0(23) = -1 : L0(24) = -1
        L45(0) = 0 : L45(1) = -1 : L45(2) = -1 : L45(3) = 0 : L45(4) = 2
        L45(5) = -1 : L45(6) = -1 : L45(7) = 0 : L45(8) = 2 : L45(9) = 0
        L45(10) = -1 : L45(11) = 0 : L45(12) = 2 : L45(13) = 0 : L45(14) = -1
        L45(15) = 0 : L45(16) = 2 : L45(17) = 0 : L45(18) = -1 : L45(19) = -1
        L45(20) = 2 : L45(21) = 0 : L45(22) = -1 : L45(23) = -1 : L45(24) = 0
        L90(0) = -1 : L90(1) = 0 : L90(2) = 2 : L90(3) = 0 : L90(4) = -1
        L90(5) = -1 : L90(6) = 0 : L90(7) = 2 : L90(8) = 0 : L90(9) = -1
        L90(10) = -1 : L90(11) = 0 : L90(12) = 2 : L90(13) = 0 : L90(14) = -1
        L90(15) = -1 : L90(16) = 0 : L90(17) = 2 : L90(18) = 0 : L90(19) = -1
        L90(20) = -1 : L90(21) = 0 : L90(22) = 2 : L90(23) = 0 : L90(24) = -1
        L135(0) = 2 : L135(1) = 0 : L135(2) = -1 : L135(3) = -1 : L135(4) = 0
        L135(5) = 0 : L135(6) = 2 : L135(7) = 0 : L135(8) = -1 : L135(9) = -1
        L135(10) = -1 : L135(11) = 0 : L135(12) = 2 : L135(13) = 0 : L135(14) = -1
        L135(15) = -1 : L135(16) = -1 : L135(17) = 0 : L135(18) = 2 : L135(19) = 0
        L135(20) = 0 : L135(21) = -1 : L135(22) = -1 : L135(23) = 0 : L135(24) = 2
        *distance.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *S00.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *S45.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *S90.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *S135.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *output.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
        *thin.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
        kernel00.CvMat : kernel45.CvMat : kernel90.CvMat : kernel135.CvMat
        cvInitMatHeader(@kernel00, 5, 5, CV_MAKETYPE(#CV_32F, 1), @L0(), #CV_AUTOSTEP)
        cvInitMatHeader(@kernel45, 5, 5, CV_MAKETYPE(#CV_32F, 1), @L45(), #CV_AUTOSTEP)
        cvInitMatHeader(@kernel90, 5, 5, CV_MAKETYPE(#CV_32F, 1), @L90(), #CV_AUTOSTEP)
        cvInitMatHeader(@kernel135, 5, 5, CV_MAKETYPE(#CV_32F, 1), @L135(), #CV_AUTOSTEP)
        cvDistTransform(*resize, *distance, #CV_DIST_L2, 5, #Null, #Null, #CV_DIST_LABEL_CCOMP)
        cvFilter2D(*distance, *S00, @kernel00, -1, -1)
        cvFilter2D(*distance, *S45, @kernel45, -1, -1)
        cvFilter2D(*distance, *S90, @kernel90, -1, -1)
        cvFilter2D(*distance, *S135, @kernel135, -1, -1)

        For y = 0 To *thin\height - 1
          For x = 0 To *thin\width - 1
            SMax.f = PeekF(@CV_IMAGE_ELEM(*S00, y, x * 4))
            S45.f = PeekF(@CV_IMAGE_ELEM(*S45, y, x * 4))
            CV_MAX(SMax, S45)
            S90.f = PeekF(@CV_IMAGE_ELEM(*S90, y, x * 4))
            S135.f = PeekF(@CV_IMAGE_ELEM(*S135, y, x * 4))
            CV_MAX(S90, S135)
            CV_MAX(SMax, S90)

            If SMax < 0 : SMax = 0 : EndIf

            PokeF(@CV_IMAGE_ELEM(*output, y, x * 4), SMax)
          Next
        Next
        cvThreshold(*output, *output, 11, 255, #CV_THRESH_BINARY)
        *color.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
        *reset.IplImage
        iRatio.d = 150 / *resize\width
        iWidth = *resize\width * iRatio
        iHeight = *resize\height * iRatio
        *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
        *temp.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
        cvCvtColor(*resize, *temp, #CV_GRAY2BGR, 1)
        cvResize(*temp, *PIP, #CV_INTER_AREA)
        BringWindowToTop(hWnd)
        *param\Pointer1 = *color

        Repeat
          If *color
            Select thin
              Case 0
                cvConvertScaleAbs(*S00, *thin, 255, 0)
              Case 1
                cvConvertScaleAbs(*S45, *thin, 255, 0)
              Case 2
                cvConvertScaleAbs(*S90, *thin, 255, 0)
              Case 3
                cvConvertScaleAbs(*S135, *thin, 255, 0)
              Case 4                
                cvConvertScaleAbs(*output, *thin, 255, 0)
            EndSelect
            cvCvtColor(*thin, *color, #CV_GRAY2BGR, 1)
            cvReleaseImage(@*reset)
            *reset = cvCloneImage(*color)

            Select PIP
              Case 0
                cvSetImageROI(*color, 20, 20, iWidth, iHeight)
                cvAndS(*color, 0, 0, 0, 0, *color, #Null)
                cvAdd(*color, *PIP, *color, #Null)
                cvResetImageROI(*color)
                cvRectangleR(*color, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
              Case 1
                cvSetImageROI(*color, *color\width - (150 + 20), 20, iWidth, iHeight)
                cvAndS(*color, 0, 0, 0, 0, *color, #Null)
                cvAdd(*color, *PIP, *color, #Null)
                cvResetImageROI(*color)
                cvRectangleR(*color, *color\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            EndSelect
            cvShowImage(#CV_WINDOW_NAME, *color)
            keyPressed = cvWaitKey(0)

            Select keyPressed
              Case 32
                thin = (thin + 1) % 5
              Case 86, 118
                PIP = (PIP + 1) % 3
                cvReleaseImage(@*color)
                *color = cvCloneImage(*reset)
                *param\Pointer1 = *color
            EndSelect
          EndIf
        Until keyPressed = 13 Or keyPressed = 27 Or exitCV
        FreeMemory(*param)
        cvReleaseImage(@*thin)
        cvReleaseImage(@*output)
        cvReleaseImage(@*S135)
        cvReleaseImage(@*S90)
        cvReleaseImage(@*S45)
        cvReleaseImage(@*S45)
        cvReleaseImage(@*S00)
        cvReleaseImage(@*distance)
        cvReleaseImage(@*temp)
        cvReleaseImage(@*PIP)
        cvReleaseImage(@*reset)
        cvReleaseImage(@*color)
      EndIf
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If keyPressed = 13
        exitCV = #False
        nThin = (nThin + 1) % 2
        OpenCV("images/thinning" + Str(nThin + 1) + ".jpg")
      ElseIf openCV
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

OpenCV("images/thinning1.jpg")
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\