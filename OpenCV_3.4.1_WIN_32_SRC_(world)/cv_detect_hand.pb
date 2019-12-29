IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, nHand

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Contour extraction and calculation is used to determine finger locations." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between views." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch between images."

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

Procedure GetConvexHull(*image.IplImage, *contours.CvSeq)
  *hull.CvSeq = cvConvexHull2(*contours, #Null, #CV_CLOCKWISE, #False)
  *pt0.CvPoint = cvGetSeqElem(*hull, *hull\total - 1) : *pt1.CvPoint

  For rtnCount = 0 To *hull\total - 1
    *pt1 = cvGetSeqElem(*hull, rtnCount)
    pt1 = PeekL(*pt0\x) : pt2 = PeekL(*pt0\x + 4)
    pt3 = PeekL(*pt1\x) : pt4 = PeekL(*pt1\x + 4)
    cvLine(*image, pt1, pt2, pt3, pt4, 0, 0, 0, 0, 2, #CV_AA, #Null)
    *pt0 = *pt1
  Next
EndProcedure

Procedure DetectFingers(*image.IplImage, *contours.CvSeq, centerX, centerY)
  *p0.CvPoint : *p1.CvPoint : *p2.CvPoint
  vector1.CvPoint : vector2.CvPoint
  minP0.CvPoint : minP1.CvPoint : minP2.CvPoint
  l1.CvPoint : l2.CvPoint : l3.CvPoint
  Dim finger.CvPoint(20) : Dim fLocation(20)

  For rtnCount = 0 To *contours\total - 1
    *p0 = cvGetSeqElem(*contours, (rtnCount + 40) % *contours\total)
    *p1 = cvGetSeqElem(*contours, rtnCount)
    *p2 = cvGetSeqElem(*contours,(rtnCount + 80) % *contours\total)
    vector1\x = *p0\x - *p1\x
    vector1\y = *p0\y - *p1\y
    vector2\x = *p0\x - *p2\x
    vector2\y = *p0\y - *p2\y
    dotProduct = vector1\x * vector2\x + vector1\y * vector2\y
    length1.f = Sqr(vector1\x * vector1\x + vector1\y * vector1\y)
    length2.f = Sqr(vector2\x * vector2\x + vector2\y * vector2\y)
    angle.f = Abs(dotProduct / (length1 * length2))

    If angle < 0.1
      If Not signal
        signal = #True
        minP0\x = *p0\x
        minP0\y = *p0\y
        minP1\x = *p1\x
        minP1\y = *p1\y
        minP2\x = *p2\x
        minP2\y = *p2\y
        minAngle.f = angle
      Else
        If angle <= minAngle
          minP0\x = *p0\x
          minP0\y = *p0\y
          minP1\x = *p1\x
          minP1\y = *p1\y
          minP2\x = *p2\x
          minP2\y = *p2\y
          minAngle.f = angle
        EndIf
      EndIf
    Else
      If signal
        signal = #False
        l1\x = minP0\x - centerX
        l1\y = minP0\y - centerY
        l2\x = minP1\x - centerX
        l2\y = minP1\y - centerY
        l3\x = minP2\x - centerX
        l3\y = minP2\y - centerY
        length0 = Sqr(l1\x * l1\x + l1\y * l1\y)
        length1 = Sqr(l2\x * l2\x + l2\y * l2\y)
        length2 = Sqr(l3\x * l3\x + l3\y * l3\y)

        If length0 > length1 And length0 > length2
          finger(count) = minP0
          fLocation(count) = rtnCount + 20
          count + 1
        EndIf
      EndIf
    EndIf
  Next

  For rtnCount = 0 To count - 1
    If rtnCount > 0
      If fLocation(rtnCount) - fLocation(rtnCount - 1) > 40
        If finger(rtnCount)\x > 10 And finger(rtnCount)\x < *image\width - 10 And finger(rtnCount)\y < *image\height - 15
          cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 6, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
          cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 10, 0, 255, 0, 0, 2, #CV_AA, #Null)
          fCount + 1
        EndIf
      EndIf
    Else
      If finger(rtnCount)\x > 10 And finger(rtnCount)\x < *image\width - 10 And finger(rtnCount)\y < *image\height - 15
        cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 6, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
        cvCircle(*image, finger(rtnCount)\x, finger(rtnCount)\y, 10, 0, 255, 0, 0, 2, #CV_AA, #Null)
        fCount + 1
      EndIf
    EndIf
  Next
  ProcedureReturn fCount
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

    If *resize\nChannels = 1
      *gray.IplImage = cvCloneImage(*resize)
    Else
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
    EndIf
    *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
    cvErode(*gray, *gray, *kernel, 3)
    cvDilate(*gray, *gray, *kernel, 2)
    cvReleaseStructuringElement(@*kernel)
    cvSmooth(*gray, *gray, #CV_GAUSSIAN, 21, 0, 0, 0)
    cvThreshold(*gray, *gray, 130, 255, #CV_THRESH_BINARY_INV | #CV_THRESH_OTSU)
    *storage.CvMemStorage = cvCreateMemStorage(0)
    cvClearMemStorage(*storage)
    *contours.CvSeq
    cvFindContours(*gray, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

    While *contours And *contours\total <= 650
      *contours = *contours\h_next
    Wend

    If *contours
      *contour.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 3) : cvSetZero(*contour)
      cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
      contourCenter.CvBox2D
      cvMinAreaRect2(@contourCenter, *contours, #Null)
      GetConvexHull(*resize, *contours)
      fCount = DetectFingers(*resize, *contours, contourCenter\center\x, contourCenter\center\y)
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
      cvPutText(*resize, "Fingers: " + Str(fCount), 10, 30, @font, 255, 0, 0, 0)
    EndIf
    BringWindowToTop(hWnd)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *resize
        Select view
          Case 0
            *param\Pointer1 = *resize
            cvShowImage(#CV_WINDOW_NAME, *resize)
          Case 1
            *param\Pointer1 = *gray
            cvShowImage(#CV_WINDOW_NAME, *gray)
          Case 2
            *param\Pointer1 = *contour
            cvShowImage(#CV_WINDOW_NAME, *contour)
        EndSelect
        keyPressed = cvWaitKey(0)

        If keyPressed = 32
          If *contour : view = (view + 1) % 3 : Else : view = (view + 1) % 2 : EndIf
        EndIf
      EndIf
    Until keyPressed = 13 Or keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseMemStorage(@*storage)
    cvReleaseImage(@*contour)
    cvReleaseImage(@*gray)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If keyPressed = 13
      exitCV = #False
      nHand = (nHand + 1) % 3
      OpenCV("images/hand" + Str(nHand + 1) + ".jpg")
    EndIf
  EndIf
EndProcedure

OpenCV("images/hand1.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\