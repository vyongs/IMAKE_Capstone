IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, centerX.f, centerY.f

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Blurs an image towards a selected point." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Move the X / Y axis." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset axis to center." + #LF$ + #LF$ +
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
    Case #CV_EVENT_LBUTTONUP
      If x < 40 : centerX = 40 : ElseIf x > *param\Pointer1\width - 40 : centerX = *param\Pointer1\width - 40 : Else : centerX = x : EndIf
      If y < 40 : centerY = 40 : ElseIf y > *param\Pointer1\height - 40 : centerY = *param\Pointer1\height - 40 : Else : centerY = y : EndIf

      keybd_event_(#VK_Z, 0, 0, 0)
  EndSelect
EndProcedure

Procedure RadialBlur(*blur.IplImage)
  nRows = *blur\height : nCols = *blur\width
  nBlur.f = 0.00002 : nRadius.f = 0 : nIterations = 50
  *growMapX.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*growMapX)
  *growMapY.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*growMapY)
  *shrinkMapX.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*shrinkMapX)
  *shrinkMapY.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*shrinkMapY)

  For y = 0 To nRows - 1
    For x = 0 To nCols - 1
      nRadius = nBlur * Sqr((centerX - x) * (centerX - x) + (centerY - y) * (centerY - y))
      PokeF(@*growMapX\fl\f + y * *growMapX\Step + x * 4, x + (x - centerX) * nRadius)
      PokeF(@*growMapY\fl\f + y * *growMapY\Step + x * 4, y + (y - centerY) * nRadius)
      PokeF(@*shrinkMapX\fl\f + y * *shrinkMapX\Step + x * 4, x - (x - centerX) * nRadius)
      PokeF(@*shrinkMapY\fl\f + y * *shrinkMapY\Step + x * 4, y - (y - centerY) * nRadius)
    Next
  Next
  *temp1.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_8U, *blur\nChannels))
  *temp2.CvMat = cvCreateMat(nRows, nCols, CV_MAKETYPE(#CV_8U, *blur\nChannels))

  For rtnCount = 0 To nIterations - 1
    cvRemap(*blur, *temp1, *growMapX, *growMapY, #CV_INTER_LINEAR, 0, 0, 0, 0)
    cvRemap(*blur, *temp2, *shrinkMapX, *shrinkMapY, #CV_INTER_LINEAR, 0, 0, 0, 0)
    cvAddWeighted(*temp1, 0.5, *temp2, 0.5, 0, *blur)
  Next
  cvReleaseMat(@*temp2)
  cvReleaseMat(@*temp1)
  cvReleaseMat(@*shrinkMapY)
  cvReleaseMat(@*shrinkMapX)
  cvReleaseMat(@*growMapY)
  cvReleaseMat(@*growMapX)
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
      *blur.IplImage = cvCloneImage(*resize)
      centerX = *blur\width / 2 : centerY = *blur\height / 2
      RadialBlur(*blur)
      *reset.IplImage = cvCloneImage(*blur)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *resize\nChannels)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *blur
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *blur
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
          cvShowImage(#CV_WINDOW_NAME, *blur)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              centerX = *blur\width / 2 : centerY = *blur\height / 2
              cvReleaseImage(@*blur)
              *blur = cvCloneImage(*resize)
              RadialBlur(*blur)
              *param\Pointer1 = *blur
              cvReleaseImage(@*reset)
              *reset = cvCloneImage(*blur)
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*blur)
              *blur = cvCloneImage(*reset)
              *param\Pointer1 = *blur
            Case 90, 122
              cvReleaseImage(@*blur)
              *blur = cvCloneImage(*resize)
              RadialBlur(*blur)
              *param\Pointer1 = *blur
              cvReleaseImage(@*reset)
              *reset = cvCloneImage(*blur)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*blur)
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
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\