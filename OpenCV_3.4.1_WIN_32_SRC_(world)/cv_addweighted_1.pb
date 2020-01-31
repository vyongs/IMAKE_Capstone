IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Alpha blend multiple images to simulate face morphing."

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
    *overlay1.IplImage = cvLoadImage("images/weight2.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    *overlay2.IplImage = cvLoadImage("images/weight3.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    *overlay3.IplImage = cvLoadImage("images/weight4.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    *blend.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *blend
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *blend        
        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*overlay1, alpha, *resize, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next

        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*overlay2, alpha, *overlay1, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next

        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*overlay3, alpha, *overlay2, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next

        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*overlay2, alpha, *overlay3, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next

        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*overlay1, alpha, *overlay2, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next

        For rtnCount = 0 To 100 - 1
          alpha.d = rtnCount / 100
          beta.d = 1 - alpha
          cvAddWeighted(*resize, alpha, *overlay1, beta, 0, *blend)
          cvShowImage(#CV_WINDOW_NAME, *blend)
          keyPressed = cvWaitKey(25)

          If keyPressed = 27 Or exitCV : Break 2 : EndIf

        Next
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*blend)
    cvReleaseImage(@*overlay3)
    cvReleaseImage(@*overlay2)
    cvReleaseImage(@*overlay1)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/weight1.jpg")
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\