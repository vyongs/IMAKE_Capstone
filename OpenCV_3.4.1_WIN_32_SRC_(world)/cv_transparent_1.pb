IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, *resize.IplImage, hWnd_watershed, *watershed2.IplImage, *transparent.IplImage, outLine

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using the watershed algorithm, an object can be extracted and saved to a transparent PNG file." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Mark objects on the image." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Run the Watershed algorithm." + #LF$ +
                  "DOUBLE-CLICK" + #TAB$ + ": Extract objects." + #LF$ +
                  "ENTER       " + #TAB$ + ": Restore the original image."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          openCV = #True
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
        Case 2
          FileName.s = SaveCVImage(#True, 3)

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
      SendMessage_(hWnd_watershed, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Static pt1.CvPoint

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save.IplImage = *transparent
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      pt1\x = x
      pt1\y = y
    Case #CV_EVENT_LBUTTONUP
      pt1\x = -1
      pt1\y = -1
    Case #CV_EVENT_MOUSEMOVE
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        If pt1\x > 0 Or pt1\y > 0
          pt2.CvPoint : pt2\x = x : pt2\y = y

          If outLine
            cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 255, 0, 0, 0, 4, #CV_AA, #Null)
            cvLine(*param\Pointer2, pt1\x, pt1\y, pt2\x, pt2\y, 255, 0, 0, 0, 4, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
          Else
            cvLine(*transparent, pt1\x, pt1\y, pt2\x, pt2\y, 0, 0, 0, 0, 20, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *transparent)
          EndIf
          pt1 = pt2
        EndIf
      EndIf
    Case #CV_EVENT_LBUTTONDBLCLK
      B = PeekA(@*watershed2\imageData\b + y * *watershed2\widthStep + x * 3 + 0)
      G = PeekA(@*watershed2\imageData\b + y * *watershed2\widthStep + x * 3 + 1)
      R = PeekA(@*watershed2\imageData\b + y * *watershed2\widthStep + x * 3 + 2)

      If B + G + R > 0
        *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
        *extract.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 4)
        *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
        cvSetZero(*mask)
        cvCvtColor(*resize, *extract, #CV_BGR2BGRA, 1)
        scalar.CvScalar

        For xx = 0 To *watershed2\width - 1
          For yy = 0 To *watershed2\height - 1
            cvGet2D(@scalar, *watershed2, yy, xx)

            If scalar\val[0] = B And scalar\val[1] = G And scalar\val[2] = R : cvSet2D(*mask, yy, xx, 255, 255, 255, 0) : EndIf

          Next
        Next
        cvErode(*mask, *mask, *kernel, 1)
        cvDilate(*mask, *mask, *kernel, 1)
        cvSmooth(*mask, *mask, #CV_GAUSSIAN, 21, 0, 0, 0)
        cvThreshold(*mask, *mask, 130, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
        cvCopy(*extract, *transparent, *mask)
        cvShowImage(#CV_WINDOW_NAME, *transparent)
        cvReleaseStructuringElement(@*kernel)
        cvReleaseImage(@*extract)
        cvReleaseImage(@*mask)
        outLine = #False
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
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image\width >= dtWidth / 2 - 100 Or *image\height >= dtHeight - 100
      iWidth = dtWidth / 2 - 100
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
      *resize = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
      *resize = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      cvNamedWindow(#CV_WINDOW_NAME + " - Watershed", #CV_WINDOW_AUTOSIZE)
      hWnd_watershed = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Watershed"))
      SendMessage_(hWnd_watershed, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_watershed, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_watershed, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - Watershed", *resize\width, *resize\height)
      cvMoveWindow(#CV_WINDOW_NAME + " - Watershed", *resize\width + 50, 20)
      *clone.IplImage = cvCloneImage(*resize)
      *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *markers.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32S, 1)
      *watershed1.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *watershed2 = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *transparent = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 4)
      *gray.IplImage = cvCloneImage(*resize)
      cvCvtColor(*clone, *mask, #CV_BGR2GRAY, 1)
      cvCvtColor(*mask, *gray, #CV_GRAY2BGR, 1)
      cvCopy(*gray, *watershed1, #Null)
      cvSetZero(*watershed2)
      cvSetZero(*mask)
      *storage.CvMemStorage = cvCreateMemStorage(0)
      *contours.CvSeq
      *color.CvMat
      *ptr.BYTE
      *dst.BYTE
      outLine = #True
      rng = cvRNG(Random(2147483647))
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *clone
      *param\Pointer2 = *mask
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *clone
          cvShowImage(#CV_WINDOW_NAME, *clone)
          cvShowImage(#CV_WINDOW_NAME + " - Watershed", *watershed1)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              outLine = #True
              cvCopy(*resize, *clone, #Null)
              cvCopy(*gray, *watershed1, #Null)
              cvSetZero(*watershed2)
              cvSetZero(*transparent)
              cvSetZero(*mask)
            Case 32
              outLine = #True
              cvSetZero(*transparent)
              cvClearMemStorage(*storage)
              cvFindContours(*mask, *storage, @*contours, SizeOf(CvContour), #CV_RETR_CCOMP, #CV_CHAIN_APPROX_SIMPLE, 0, 0)
              cvSetZero(*markers)
              comp_count = 0

              While *contours > 0
                cvDrawContours(*markers, *contours, comp_count + 1, comp_count + 1, comp_count + 1, comp_count + 1, comp_count + 1, comp_count + 1, comp_count + 1, comp_count + 1, 0, #CV_FILLED, #CV_AA, 0, 0)
                *contours = *contours\h_next
                comp_count + 1
              Wend

              If comp_count = 0 : Continue : EndIf

              *color = cvCreateMat(1, comp_count, CV_MAKETYPE(#CV_8U, 3))

              For i = 0 To comp_count - 1
                *ptr = @*color\ptr\b + i * 3
                PokeA(@*ptr\b, UnsignedLong(cvRandInt(rng)) % 180 + 50)
                PokeA(@*ptr\b + 2, UnsignedLong(cvRandInt(rng)) % 180 + 50)
                PokeA(@*ptr\b + 3, UnsignedLong(cvRandInt(rng)) % 180 + 50)
              Next
              cvWatershed(*resize, *markers)

              For i = 0 To *markers\height - 1
                For j = 0 To *markers\width - 1
                  idx = PeekA(@CV_IMAGE_ELEM(*markers, i, j * 4))
                  *dst = @CV_IMAGE_ELEM(*watershed1, i, j * 3)

                  If idx = -1
                    PokeA(@*dst\b, 255)
                    PokeA(@*dst\b + 1, 255)
                    PokeA(@*dst\b + 2, 255)
                  ElseIf idx <= 0 Or idx > comp_count
                    PokeA(@*dst\b, 0)
                    PokeA(@*dst\b + 1, 0)
                    PokeA(@*dst\b + 2, 0)
                  Else
                    *ptr = @*color\ptr\b + (idx - 1) * 3
                    PokeA(@*dst\b, PeekA(@*ptr\b))
                    PokeA(@*dst\b + 1, PeekA(@*ptr\b + 1))
                    PokeA(@*dst\b + 2, PeekA(@*ptr\b + 2))
                  EndIf
                Next
              Next
              cvCopy(*watershed1, *watershed2, #Null)
              cvAddWeighted(*watershed1, 0.6, *gray, 0.6, 0, *watershed1)
              cvReleaseMat(@*color)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*contour)
      cvReleaseMemStorage(@*storage)
      cvReleaseImage(@*gray)
      cvReleaseImage(@*transparent)
      cvReleaseImage(@*watershed2)
      cvReleaseImage(@*watershed1)
      cvReleaseImage(@*markers)
      cvReleaseImage(@*mask)
      cvReleaseImage(@*clone)
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

OpenCV("images/lena.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\