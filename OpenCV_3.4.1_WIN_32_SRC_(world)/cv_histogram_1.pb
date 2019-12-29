IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates a histogram for the Red, Green, and Blue channels of an image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between an opaque and translucent histogram." + #LF$ + #LF$ +
                  "[ B ] KEY   " + #TAB$ + ": Black / White background." + #LF$ +
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
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    FrameWidth = 640
    FrameHeight = 480
    cvResizeWindow(#CV_WINDOW_NAME, FrameWidth, FrameHeight)
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)
    
    If *resize\nChannels = 1
      *temp.IplImage = cvCloneImage(*resize)
      *resize.IplImage = cvCreateImage(*temp\width, *temp\height, #IPL_DEPTH_8U, 3)
      cvCvtColor(*temp, *resize, #CV_GRAY2BGR, 1)
      cvReleaseImage(@*temp)
    EndIf
    *hist.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
    cvSet(*hist, 255, 255, 255, 0, #Null)
    bins = 256
    Dim range.f(2) : range(0) = 0 : range(1) = 256
    *ranges.FLOAT : PokeL(@*ranges, @range())
    *hist_red.CvHistogram = cvCreateHist(1, @bins, #CV_HIST_ARRAY, @*ranges, #True)
    *hist_green.CvHistogram = cvCreateHist(1, @bins, #CV_HIST_ARRAY, @*ranges, #True)
    *hist_blue.CvHistogram = cvCreateHist(1, @bins, #CV_HIST_ARRAY, @*ranges, #True)
    *channel.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
    cvSetImageCOI(*resize, 3)
    cvCopy(*resize, *channel, #Null)
    cvResetImageROI(*resize)
    cvCalcHist(@*channel, *hist_red, #False, #Null)
    cvSetImageCOI(*resize, 2)
    cvCopy(*resize, *channel, #Null)
    cvResetImageROI(*resize)
    cvCalcHist(@*channel, *hist_green, #False, #Null)
    cvSetImageCOI(*resize, 1)
    cvCopy(*resize, *channel, #Null)
    cvResetImageROI(*resize)
    cvCalcHist(@*channel, *hist_blue, #False, #Null)
    cvGetMinMaxHistValue(*hist_red, #Null, @max_value.f, #Null, #Null)
    cvGetMinMaxHistValue(*hist_green, #Null, @max_test.f, #Null, #Null)

    If max_test > max_value : max_value = max_test : EndIf

    cvGetMinMaxHistValue(*hist_blue, #Null, @max_test, #Null, #Null)

    If max_test > max_value : max_value = max_test : EndIf

    cvConvertScale(*hist_red\bins, *hist_red\bins, *hist\height / max_value, 0)
    cvConvertScale(*hist_green\bins, *hist_green\bins, *hist\height / max_value, 0)
    cvConvertScale(*hist_blue\bins, *hist_blue\bins, *hist\height / max_value, 0)
    scale.f = *hist\width / bins

    If *resize\width > 150
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *preview.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *resize\nChannels)
      cvResize(*resize, *preview, #CV_INTER_AREA)
    Else
      *preview = cvCloneImage(*resize)
    EndIf
    offset = 5
    *border.IplImage = cvCreateImage(*preview\width + offset - 1, *preview\height + offset - 1, #IPL_DEPTH_8U, *preview\nChannels)
    cvCopyMakeBorder(*preview, *border, (offset - 1) / 2, (offset - 1) / 2, #IPL_BORDER_CONSTANT, 0, 255, 255, 0)
    *overlay.IplImage
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *hist
    *param\Message = ImageFile
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *hist
        If background : cvSetZero(*hist) : Else : cvSet(*hist, 255, 255, 255, 255, #Null) : EndIf

        If transparent
          For rtnCount = 0 To bins - 1
            x1 = rtnCount * scale
            y1 = *hist\height
            x2 = (rtnCount + 1) * scale
            y2 = *hist\height - Round(cvGetReal1D(*hist_red\bins, rtnCount), #PB_Round_Nearest)
            cvRectangle(*hist, x1, y1, x2, y2, 0, 0, 255, 0, #CV_FILLED, 8, #Null)
          Next
          cvReleaseImage(@*overlay)
          *overlay = cvCloneImage(*hist)

          For rtnCount = 0 To bins - 1
            x1 = rtnCount * scale
            y1 = *hist\height
            x2 = (rtnCount + 1) * scale
            y2 = *hist\height - Round(cvGetReal1D(*hist_green\bins, rtnCount), #PB_Round_Nearest)
            cvRectangle(*hist, x1, y1, x2, y2, 0, 255, 0, 0, #CV_FILLED, 8, #Null)
          Next
          opacity.d = 0.4
          cvAddWeighted(*overlay, opacity, *hist, 1 - opacity, 0, *hist)
          cvReleaseImage(@*overlay)
          *overlay = cvCloneImage(*hist)

          For rtnCount = 0 To bins - 1
            x1 = rtnCount * scale
            y1 = *hist\height
            x2 = (rtnCount + 1) * scale
            y2 = *hist\height - Round(cvGetReal1D(*hist_blue\bins, rtnCount), #PB_Round_Nearest)
            cvRectangle(*hist, x1, y1, x2, y2, 255, 0, 0, 0, #CV_FILLED, 8, #Null)
          Next
          opacity = 0.4
          cvAddWeighted(*overlay, opacity, *hist, 1 - opacity, 0, *hist)
        Else
          For rtnCount = 0 To bins - 1
            x1 = rtnCount * scale
            y1 = *hist\height
            x2 = (rtnCount + 1) * scale
            y2_r = *hist\height - Round(cvGetReal1D(*hist_red\bins, rtnCount), #PB_Round_Nearest)
            y2_g = *hist\height - Round(cvGetReal1D(*hist_green\bins, rtnCount), #PB_Round_Nearest)
            y2_b = *hist\height - Round(cvGetReal1D(*hist_blue\bins, rtnCount), #PB_Round_Nearest)
            cvRectangle(*hist, x1, y1, x2, y2_r, 0, 0, 255, 0, #CV_FILLED, 8, #Null)
            cvRectangle(*hist, x1, y1, x2, y2_g, 0, 255, 0, 0, #CV_FILLED, 8, #Null)
            cvRectangle(*hist, x1, y1, x2, y2_b, 255, 0, 0, 0, #CV_FILLED, 8, #Null)
          Next
        EndIf

        Select PIP
          Case 0
            cvSetImageROI(*hist, 20, 20, *border\width, *border\height)
            cvAndS(*hist, 0, 0, 0, 0, *hist, #Null)
            cvAdd(*hist, *border, *hist, #Null)
            cvResetImageROI(*hist)
          Case 1
            cvSetImageROI(*hist, *hist\width - (150 + 20), 20, *border\width, *border\height)
            cvAndS(*hist, 0, 0, 0, 0, *hist, #Null)
            cvAdd(*hist, *border, *hist, #Null)
            cvResetImageROI(*hist)
        EndSelect
        cvShowImage(#CV_WINDOW_NAME, *hist)
        keyPressed = cvWaitKey(0)

        Select keyPressed
          Case 32
            transparent ! #True
          Case 66, 98
            background ! #True
          Case 86, 118
            PIP = (PIP + 1) % 3
        EndSelect
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseHist(@*hist_blue)
    cvReleaseHist(@*hist_green)
    cvReleaseHist(@*hist_red)
    cvReleaseImage(@*overlay)
    cvReleaseImage(@*hist)
    cvReleaseImage(@*border)
    cvReleaseImage(@*preview)
    cvReleaseImage(@*channel)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If openCV
      openCV = #False
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/building.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\