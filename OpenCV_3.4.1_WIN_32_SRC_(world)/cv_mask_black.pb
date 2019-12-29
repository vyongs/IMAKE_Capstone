IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Create an image mask by replacing any non-black pixels with white." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Alternate method." + #LF$ + #LF$ +
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

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      *transparent.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 4))
      *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *color.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *reset.IplImage
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *color
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *color
          If mask
            cvSetZero(*mask)

            For y = 0 To *resize\height - 1
              For x = 0 To *resize\width - 1
                B = PeekA(@*resize\imageData\b + y * *resize\widthStep + x * 3 + 0)
                G = PeekA(@*resize\imageData\b + y * *resize\widthStep + x * 3 + 1)
                R = PeekA(@*resize\imageData\b + y * *resize\widthStep + x * 3 + 2)

                If B <> 0 And G <> 0 And R <> 0 : PokeA(@*mask\imageData\b + y * *mask\widthStep + x, 255) : EndIf

              Next
            Next
          Else
            cvCvtColor(*resize, *transparent, #CV_BGR2BGRA, 1)
            
            For y = 0 To *transparent\rows - 1
              For x = 0 To *transparent\cols - 1
                B = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 0)
                G = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 1)
                R = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 2)

                If B + G + R < 40 : PokeA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 3, 0) : EndIf

              Next
            Next
            cvSplit(*transparent, #Null, #Null, #Null, *mask)
          EndIf
          cvErode(*mask, *mask, *kernel, 1)
          cvDilate(*mask, *mask, *kernel, 1)
          cvSmooth(*mask, *mask, #CV_GAUSSIAN, 21, 0, 0, 0)
          cvThreshold(*mask, *mask, 130, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
          cvCvtColor(*mask, *color, #CV_GRAY2BGR, 1)
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
              mask ! #True
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*color)
              *color = cvCloneImage(*reset)
              *param\Pointer1 = *color
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseStructuringElement(@*kernel)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*color)
      cvReleaseImage(@*mask)
      cvReleasemat(@*transparent)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      If *resize\nChannels = 3
        MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      Else
        MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the channel requirements, please try another image.", #MB_ICONERROR)
      EndIf
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/flower.png")
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\