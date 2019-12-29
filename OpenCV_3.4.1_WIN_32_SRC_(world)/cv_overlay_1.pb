IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, Dim dstPoint.CvPoint2D32f(0), nColor, nR, nG, nB

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Apply a perspective transform calculated from four pairs of points to an image, overlayed onto another image." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Add 4 X / Y points." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Execute overlay." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the image." + #LF$ + #LF$ +
                  "[ C ] KEY   " + #TAB$ + ": Select a color overlay."

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
    Case #CV_EVENT_LBUTTONDOWN
      If ArraySize(dstPoint()) < 4
        arrSize = ArraySize(dstPoint()) + 1
        ReDim dstPoint.CvPoint2D32f(arrSize)
        dstPoint(arrSize - 1)\x = x
        dstPoint(arrSize - 1)\y = y
        cvCircle(*param\Pointer2, x, y, 3, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer2)
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
    *image.IplImage = cvLoadImage("images/overlay1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
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
    *logo.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)

    If *logo\nChannels = 3
      Dim srcPoint.CvPoint2D32f(4)
      srcPoint(0)\x = 0
      srcPoint(0)\y = 0
      srcPoint(1)\x = *resize\width
      srcPoint(1)\y = 0
      srcPoint(2)\x = 0
      srcPoint(2)\y = *resize\height
      srcPoint(3)\x = *resize\width
      srcPoint(3)\y = *resize\height
      iRatio1.d = *resize\width / *logo\width
      iRatio2.d = *resize\height / *logo\height

      If iRatio1 < iRatio2
        *temp.IplImage = cvCreateImage(*logo\width * iRatio1, *logo\height * iRatio1, #IPL_DEPTH_8U, 3)
      Else
        *temp.IplImage = cvCreateImage(*logo\width * iRatio2, *logo\height * iRatio2, #IPL_DEPTH_8U, 3)
      EndIf
      *transform.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3) : cvSetZero(*transform)

      If *logo\width * *logo\height < *temp\width * *temp\height
        cvResize(*logo, *temp, #CV_INTER_CUBIC)
      Else
        cvResize(*logo, *temp, #CV_INTER_AREA)
      EndIf

      If iRatio1 < iRatio2
        cvSetImageROI(*transform, 0, *transform\height / 2 - *temp\height / 2, *temp\width, *temp\height)
      Else
        cvSetImageROI(*transform, *transform\width / 2 - *temp\width / 2, 0, *temp\width, *temp\height)
      EndIf

      If Not nColor : cvOr(*transform, *temp, *transform, #Null) : EndIf

      cvResetImageROI(*transform)
      cvReleaseImage(@*temp)
      cvReleaseImage(@*logo)

      If nColor
        cvSet(*transform, nB, nG, nR, 0, #Null)
      Else
        For i = 0 To *transform\height - 1
          For j = 0 To *transform\width - 1
            B = PeekA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 0)
            G = PeekA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 1)
            R = PeekA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 2)

            If B = 0 And G = 0 And R = 0
              PokeA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 0, 1)
              PokeA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 1, 1)
              PokeA(@*transform\imageData\b + (i * *transform\widthStep) + j * 3 + 2, 1)
            EndIf
          Next
        Next
      EndIf
      *reset.IplImage = cvCloneImage(*transform)
      *mark.IplImage = cvCloneImage(*resize)
      *warp.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
      *mask.IplImage = cvCreateImage(*transform\width, *transform\height, #IPL_DEPTH_8U, 1)
      *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_ELLIPSE, #Null)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Pointer2 = *mark
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        cvShowImage(#CV_WINDOW_NAME, *mark)
        keyPressed = cvWaitKey(0)
      Until keyPressed = 13 Or keyPressed = 27 Or (keyPressed = 32 And ArraySize(dstPoint()) = 4) Or keyPressed = 67 Or keyPressed = 99 Or exitCV

      If keyPressed = 32
        Dim tmpX(4)
        Dim tmpPoint.CvPoint2D32f(4)
        opacity.d = 0.6
        Dim pts.CvPoint(4)
        npts = 4

        Repeat
          If *resize
            If keyPressed = 32
              CopyArray(dstPoint(), tmpPoint())
              tmpX(1) = tmpPoint(0)\x
              tmpX(2) = tmpPoint(1)\x
              tmpX(3) = tmpPoint(2)\x
              tmpX(4) = tmpPoint(3)\x
              SortArray(tmpX(), #PB_Sort_Ascending)

              For rtnCount = 0 To 4 - 1
                If tmpPoint(rtnCount)\x = tmpX(1) : dstPoint(0) = tmpPoint(rtnCount) : EndIf
                If tmpPoint(rtnCount)\x = tmpX(2) : dstPoint(2) = tmpPoint(rtnCount) : EndIf
                If tmpPoint(rtnCount)\x = tmpX(3) : dstPoint(1) = tmpPoint(rtnCount) : EndIf
                If tmpPoint(rtnCount)\x = tmpX(4) : dstPoint(3) = tmpPoint(rtnCount) : EndIf
              Next
              CopyArray(dstPoint(), tmpPoint())

              Select #True
                Case Bool(dstPoint(0)\y > dstPoint(1)\y And dstPoint(2)\y < dstPoint(3)\y And dstPoint(0)\y > dstPoint(3)\y)
                  dstPoint(0) = tmpPoint(2)
                  dstPoint(1) = tmpPoint(1)
                  dstPoint(2) = tmpPoint(0)
                  dstPoint(3) = tmpPoint(3)
                Case Bool(dstPoint(0)\y < dstPoint(1)\y And dstPoint(2)\y < dstPoint(3)\y)
                  dstPoint(0) = tmpPoint(3)
                  dstPoint(1) = tmpPoint(2)
                  dstPoint(2) = tmpPoint(1)
                  dstPoint(3) = tmpPoint(0)
                  cvFlip(*transform, #Null, 1)
                Case Bool(dstPoint(0)\y < dstPoint(1)\y)
                  dstPoint(0) = tmpPoint(3)
                  dstPoint(1) = tmpPoint(0)
                  dstPoint(2) = tmpPoint(1)
                  dstPoint(3) = tmpPoint(2)
                  cvFlip(*transform, #Null, 1)
              EndSelect
              cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *warp)
              cvWarpPerspective(*transform, *transform, *warp, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)
              cvCvtColor(*transform, *mask, #CV_BGR2GRAY, 1)
              cvDilate(*mask, *mask, *kernel, 3)
              cvErode(*mask, *mask, *kernel, 2)
              cvThreshold(*mask, *mask, 0, 255, #CV_THRESH_BINARY)

              If nColor
                *select.IplImage = cvCloneImage(*resize)
                cvCopy(*transform, *resize, *mask)
                cvAddWeighted(*resize, opacity, *select, 1 - opacity, 0, *resize)
                cvReleaseImage(@*select)
              Else
                cvCopy(*transform, *resize, *mask)
              EndIf
              pts(0)\x = dstPoint(0)\x
              pts(0)\y = dstPoint(0)\y
              pts(1)\x = dstPoint(1)\x
              pts(1)\y = dstPoint(1)\y
              pts(2)\x = dstPoint(3)\x
              pts(2)\y = dstPoint(3)\y
              pts(3)\x = dstPoint(2)\x
              pts(3)\y = dstPoint(2)\y
              cvPolyLine(*resize, pts(), @npts, 1, #True, 0, 0, 0, 0, 15, #CV_AA, #Null)
              cvReleaseImage(@*transform)
              cvReleaseImage(@*mark)
              *transform = cvCloneImage(*reset)
              *mark = cvCloneImage(*resize)
              *param\Pointer2 = *mark
              Dim dstPoint.CvPoint2D32f(0)
            EndIf
            cvShowImage(#CV_WINDOW_NAME, *resize)
            keyPressed = cvWaitKey(0)
          EndIf
        Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 67 Or keyPressed = 99 Or exitCV
      EndIf

      If keyPressed = 67 Or keyPressed = 99 : nColor = 1 : EndIf

      FreeMemory(*param)
      cvReleaseStructuringElement(@*kernel)
      cvReleaseImage(@*mask)
      cvReleaseMat(@*warp)
      cvReleaseImage(@*mark)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*transform)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If keyPressed = 13 Or keyPressed = 67 Or keyPressed = 99
        exitCV = #False
        Dim dstPoint.CvPoint2D32f(0)

        If keyPressed = 67 Or keyPressed = 99
          getColor = ColorRequester()

          If getColor >= 0
            If getColor = 0
              nR = 1
              nG = 1
              nB = 1
            Else
              nR = Red(getColor)
              nG = Green(getColor)
              nB = Blue(getColor)
            EndIf
          Else
            nColor = 0
          EndIf
        EndIf
        OpenCV(ImageFile)
      ElseIf openCV
        openCV = #False
        exitCV = #False
        Dim dstPoint.CvPoint2D32f(0)
        nColor = 0
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the channel requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/overlay2.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\