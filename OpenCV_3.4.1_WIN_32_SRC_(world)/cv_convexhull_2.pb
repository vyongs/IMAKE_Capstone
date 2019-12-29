IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the contour areas, finding the convex hull of point sets, and approximating polygonal curves " +
                  "with specified precision (experimental)." + #LF$ + #LF$ +
                  "For each point set:" + #LF$ +
                  "- degree of tilt" + #LF$ +
                  "- center of mass" + #LF$ +
                  "- convex outline"

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

    If *resize\nChannels = 1
      *gray.IplImage = cvCloneImage(*resize)
    Else
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
    EndIf
    cvThreshold(*gray, *gray, 64, 255, #CV_THRESH_BINARY)
    *storage.CvMemStorage = cvCreateMemStorage(0)
    cvClearMemStorage(*storage)
    *contours.CvSeq
    nContours = cvFindContours(*gray, *storage, @*contours, SizeOf(CvContour), #CV_RETR_LIST, #CV_CHAIN_APPROX_SIMPLE, 0, 0)

    If nContours
      *contour.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 3)
      cvSet(*contour, 25, 36, 0, 0, #Null)
      *hull.CvSeq
      *poly.CvContour
      *element.CvPoint
      Dim pts.CvPoint(4)
      Dim tmp.CvPoint(4)
      npts = ArraySize(pts())
      moments.CvMoments
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)

      For rtnCount = 0 To nContours - 1
        area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

        If area >= 35 And area <= 100000
          cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, 1, #CV_AA, 0, 0)
          *hull = cvConvexHull2(*contours, #Null, #CV_CLOCKWISE, #True)
          cvDrawContours(*contour, *hull, 0, 255, 255, 0, 0, 0, 255, 0, 0, 1, #CV_AA, 0, 0)
          *poly = cvApproxPoly(*hull, SizeOf(CvContour), *storage, #CV_POLY_APPROX_DP, 20, 1)

          For rtnPoint = 0 To *poly\total - 1
            *element = cvGetSeqElem(*poly, rtnPoint)

            If *poly\total = 4
              pts(rtnPoint)\x = *element\x
              pts(rtnPoint)\y = *element\y
            ElseIf *poly\total = 8
              Select rtnPoint
                Case 0
                  pts(0)\x = *element\x
                  pts(0)\y = *element\y
                Case 1
                  pts(1)\x = *element\x
                  pts(1)\y = *element\y
                  tmp(0)\x = *element\x
                  tmp(0)\y = *element\y
                Case 2
                  tmp(1)\x = *element\x
                  tmp(1)\y = *element\y
                Case 3
                Case 4
                  pts(2)\x = *element\x
                  pts(2)\y = *element\y
                Case 5
                  pts(3)\x = *element\x
                  pts(3)\y = *element\y
                  tmp(2)\x = *element\x
                  tmp(2)\y = *element\y
                Case 6
                  tmp(3)\x = *element\x
                  tmp(3)\y = *element\y
                Case 7
              EndSelect
            EndIf
          Next

          If *poly\total = 4
            If Sqr(Pow(pts(0)\x - pts(1)\x, 2) + Pow(pts(0)\y - pts(1)\y, 2)) > Sqr(Pow(pts(0)\x - pts(3)\x, 2) + Pow(pts(0)\y - pts(3)\y, 2))
              angle.d = ATan2(pts(0)\y - pts(1)\y, pts(0)\x - pts(1)\x) * -1
            Else
              angle.d = ATan2(pts(1)\y - pts(0)\y, pts(1)\x - pts(0)\x)
            EndIf
          ElseIf *poly\total = 8
            If Abs(tmp(0)\x - tmp(1)\x) + Abs(tmp(0)\y - tmp(1)\y) > Abs(pts(0)\x - pts(1)\x) + Abs(pts(0)\y - pts(1)\y)
              angle.d = ATan2(pts(0)\y - pts(1)\y, pts(0)\x - pts(1)\x) * -1
            Else
              angle.d = ATan2(pts(1)\y - pts(0)\y, pts(1)\x - pts(0)\x)
            EndIf
          EndIf
          cvMoments(*contours, @moments, 0)
          cx.d = moments\m10 / area
          cy.d = moments\m01 / area
          x = Round(cx, #PB_Round_Nearest)
          y = Round(cy, #PB_Round_Nearest)
          cvCircle(*contour, x, y, 2, 255, 200, 100, 0, 1, #CV_AA, #Null)
          hDc = GetDC_(window_handle)
          lpString.s = Str(Degree(angle))
          GetTextExtentPoint32_(hDc, lpString, Len(lpString), @lpSize)
          ReleaseDC_(window_handle, hDc)
          cvPutText(*contour, lpString, x - (lpSize + 5 + (Len(lpString) * 2)), y + 9, @font, 255, 200, 100, 0)
        EndIf
        *contours = *contours\h_next
      Next
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *contour
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *contour
          cvShowImage(#CV_WINDOW_NAME, *contour)
          keyPressed = cvWaitKey(0)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*contour)
    EndIf
    cvReleaseMemStorage(@*storage)
    cvReleaseImage(@*gray)
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

OpenCV("images/chip2.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\