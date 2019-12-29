IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Simulates zooming a section of a resized image by loading the Region Of Interest (ROI) " +
                  "for a given rectangle from the original image." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Click an area of the resized image to zoom the ROI." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Resets the displayed image back to the resized image."

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
    Case #CV_EVENT_LBUTTONDOWN
      If *param\Message = #Null$
        *param\Message = "zoom"
        *roi.IplImage = cvCloneImage(*param\Pointer1)

        For rtnCount = 1 To 201 Step 50
          cvSmooth(*param\Pointer1, *roi, #CV_MEDIAN, rtnCount, 0, 0, 0)
          cvShowImage(#CV_WINDOW_NAME, *roi)
          cvWaitKey(1)
        Next
        ratio.d = *param\Pointer2\width / *roi\width
        roiX = x * ratio - (*roi\width / 2)
        roiY = y * ratio - (*roi\height / 2)
        rectX = (*roi\width / 2) - 100
        rectY = (*roi\height / 2) - 50

        If roiX < 0 : roiX = 0 : rectX = x * ratio - 100 : EndIf
        If roiY < 0 : roiY = 0 : rectY = y * ratio - 50 : EndIf
        If rectX < 5 : rectX = 5 : EndIf
        If rectY < 5 : rectY = 5 : EndIf

        If roiX + *roi\width > *param\Pointer2\width
          roiX = *param\Pointer2\width - *roi\width
          rectX = *param\Pointer1\width - 100 - ((*param\Pointer1\width * ratio) - (x * ratio))

          If rectX + 205 > *param\Pointer1\width : rectX = *param\Pointer1\width - 205 : EndIf

        EndIf

        If roiY + *roi\height > *param\Pointer2\height
          roiY = *param\Pointer2\height - *roi\height
          rectY = *param\Pointer1\height - 50 - ((*param\Pointer1\height * ratio) - (y * ratio))

          If rectY + 105 > *param\Pointer1\height : rectY = *param\Pointer1\height - 105 : EndIf

        EndIf
        cvSetImageROI(*param\Pointer2, roiX, roiY, *roi\width, *roi\height)
        cvCopy(*param\Pointer2, *roi, #Null)
        cvResetImageROI(*param\Pointer2)

        For rtnCount = 201 To 1 Step - 50
          cvSmooth(*roi, *param\Pointer1, #CV_MEDIAN, rtnCount, 0, 0, 0)
          cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
          cvWaitKey(1)
        Next
        *overlay.IplImage = cvCloneImage(*param\Pointer1)
        cvRectangle(*param\Pointer1, rectX, rectY, rectX + 200, rectY + 100, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
        opacity.d = 0.6
        cvAddWeighted(*overlay, opacity, *param\Pointer1, 1 - opacity, 0, *param\Pointer1)
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
        cvReleaseImage(@*overlay)
        cvReleaseImage(@*roi)
      EndIf
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
    *reset.IplImage = cvCloneImage(*resize)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = cvCloneImage(*resize)
    *param\Pointer2 = *image
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *param\Pointer1
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
        keyPressed = cvWaitKey(0)

        If keyPressed = 32 And *param\Message = "zoom"
          For rtnCount = 1 To 201 Step 50
            cvSmooth(*param\Pointer1, *param\Pointer1, #CV_MEDIAN, rtnCount, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
            cvWaitKey(1)
          Next
          *reset.IplImage = cvCloneImage(*resize)
          *param\Message = #Null$

          For rtnCount = 201 To 1 Step - 50
            cvSmooth(*reset, *param\Pointer1, #CV_MEDIAN, rtnCount, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
            cvWaitKey(1)
          Next
          cvReleaseImage(@*reset)
        EndIf
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/map.jpg")
; IDE Options = PureBasic 5.30 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\