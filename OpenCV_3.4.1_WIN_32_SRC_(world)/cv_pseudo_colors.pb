IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Augment an image with a set of predetermined colors." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Change colormap." + #LF$ + #LF$ +
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

Procedure EvaluatePixel(*image.IplImage, *colormap.IplImage, *pseudo.IplImage)
  *B.IplImage = cvCreateImage(*colormap\width, *colormap\height, *colormap\depth, 1)
  *G.IplImage = cvCloneImage(*B)
  *R.IplImage = cvCloneImage(*B)
  cvSplit(*colormap, *B, *G, *R, #Null)
  scalar1.CvScalar
  scalar2.CvScalar
  scalar3.CvScalar

  For x = 0 To *image\width - 1
    For y = 0 To *image\height - 1
      color = PeekA(@*image\imageData\b + *image\widthStep * y + x) / 8 * 15
      cvGet2D(@scalar1, *B, color, 1)
      cvGet2D(@scalar2, *G, color, 1)
      cvGet2D(@scalar3, *R, color, 1)
      PokeA(@*pseudo\imageData\b + *pseudo\widthStep * y + x * 3 + 0, scalar1\val[0])
      PokeA(@*pseudo\imageData\b + *pseudo\widthStep * y + x * 3 + 1, scalar2\val[0])
      PokeA(@*pseudo\imageData\b + *pseudo\widthStep * y + x * 3 + 2, scalar3\val[0])
    Next
  Next
  cvReleaseImage(@*R)
  cvReleaseImage(@*G)
  cvReleaseImage(@*B)
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
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
      *pseudo.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *reset.IplImage = cvCloneImage(*pseudo)
      iRatio.d = 150 / *gray\width
      iWidth = *gray\width * iRatio
      iHeight = *gray\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *pseudo
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *pseudo
          *colormap.IplImage = cvLoadImage("images/colormap" + Str(nHeat + 1) + ".jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
          EvaluatePixel(*gray, *colormap, *pseudo)

          Select PIP
            Case 0
              cvSetImageROI(*pseudo, 20, 20, iWidth, iHeight)
              cvAndS(*pseudo, 0, 0, 0, 0, *pseudo, #Null)
              cvAdd(*pseudo, *PIP, *pseudo, #Null)
              cvResetImageROI(*pseudo)

              Select nHeat
                Case 0
                  cvRectangleR(*pseudo, 19, 19, iWidth + 2, iHeight + 2, 0, 0, 255, 0, 1, #CV_AA, #Null)
                Case 1
                  cvRectangleR(*pseudo, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 0, 0, 1, #CV_AA, #Null)
                Case 2
                  cvRectangleR(*pseudo, 19, 19, iWidth + 2, iHeight + 2, 255, 0, 0, 0, 1, #CV_AA, #Null)
              EndSelect
            Case 1
              cvSetImageROI(*pseudo, *pseudo\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*pseudo, 0, 0, 0, 0, *pseudo, #Null)
              cvAdd(*pseudo, *PIP, *pseudo, #Null)
              cvResetImageROI(*pseudo)

              Select nHeat
                Case 0
                  cvRectangleR(*pseudo, *pseudo\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 0, 255, 0, 1, #CV_AA, #Null)
                Case 1
                  cvRectangleR(*pseudo, *pseudo\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 0, 0, 1, #CV_AA, #Null)
                Case 2
                  cvRectangleR(*pseudo, *pseudo\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 255, 0, 0, 0, 1, #CV_AA, #Null)
              EndSelect
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *pseudo)
          cvReleaseImage(@*colormap)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              nHeat = (nHeat + 1) % 3
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*pseudo)
              *pseudo = cvCloneImage(*reset)
              *param\Pointer1 = *pseudo
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*pseudo)
      cvReleaseImage(@*gray)
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

OpenCV("images/moon.jpg")
; IDE Options = PureBasic 5.30 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\