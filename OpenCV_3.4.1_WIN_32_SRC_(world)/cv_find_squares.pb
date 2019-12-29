IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Find squares in an image."

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

Procedure.d GetAngle(*pt1.CvPoint, *pt2.CvPoint, *pt0.CvPoint)
  dx1.d = *pt1\x - *pt0\x
  dy1.d = *pt1\y - *pt0\y
  dx2.d = *pt2\x - *pt0\x
  dy2.d = *pt2\y - *pt0\y
  ProcedureReturn (dx1 * dx2 + dy1 * dy2) / Sqr((dx1 * dx1 + dy1 * dy1) * (dx2 * dx2 + dy2 * dy2) + 0.0000000001)
EndProcedure

Procedure FindSquares(*image.IplImage, *storage.CvMemStorage)
  nCount = 11
  width = *image\width & -2
  height = *image\height & -2
  *ROI.IplImage = cvCloneImage(*image)
  *pyr.IplImage = cvCreateImage(width / 2, height / 2, #IPL_DEPTH_8U, 3)
  *gray.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *canny.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *contours.CvSeq
  *poly.CvSeq
  *squares.CvSeq = cvCreateSeq(0, SizeOf(CvSeq), SizeOf(CvPoint), *storage)
  cvSetImageROI(*ROI, 0, 0, width, height)
  cvPyrDown(*ROI, *pyr, #CV_GAUSSIAN_5x5)
  cvPyrUp(*pyr, *ROI, #CV_GAUSSIAN_5x5)

  For rtnCount = 0 To 3 - 1
    cvSetImageCOI(*ROI, rtnCount + 1)
    cvCopy(*ROI, *gray, #Null)

    For level = 0 To nCount - 1
      If level = 0
        cvCanny(*gray, *canny, 0, 200, 5, #False)
        cvDilate(*canny, *canny, *kernel, 1)
      Else
        cvThreshold(*gray, *canny, (level + 1) * 255 / nCount, 255, #CV_THRESH_BINARY)
      EndIf
      cvFindContours(*canny, *storage, @*contours, SizeOf(CvContour), #CV_RETR_LIST, #CV_CHAIN_APPROX_SIMPLE, 0, 0)

      While *contours
        *poly = cvApproxPoly(*contours, SizeOf(CvContour), *storage, #CV_POLY_APPROX_DP, cvContourPerimeter(*contours) * 0.02, #False)

        If *poly\total = 4 And cvContourArea(*poly, 0, #CV_WHOLE_SEQ_END_INDEX, 0) > 1000 And cvCheckContourConvexity(*poly)
          maxCosine.d = 0

          For index = 0 To 5 - 1
            If index >= 2
              cosine.d = Abs(GetAngle(cvGetSeqElem(*poly, index), cvGetSeqElem(*poly, index - 2), cvGetSeqElem(*poly, index - 1)))
              CV_MAX(maxCosine, cosine)
            EndIf
          Next

          If maxCosine < 0.3
            For index = 0 To 4 - 1
              cvSeqPush(*squares, cvGetSeqElem(*poly, index))
            Next
          EndIf
        EndIf
        *contours = *contours\h_next
      Wend
    Next
  Next
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*canny)
  cvReleaseImage(@*gray)
  cvReleaseImage(@*pyr)
  cvReleaseImage(@*ROI)
  ProcedureReturn *squares
EndProcedure

Procedure DrawSquares(*image.IplImage, *squares.CvSeq)
  reader.CvSeqReader
  cvStartReadSeq(*squares, @reader, 0)
  Dim pts.CvPoint(4)
  npts = 4

  For rtnCount = 0 To *squares\total - 1 Step 4
    CV_READ_SEQ_ELEM(pts(0), SizeOf(CvPoint), reader)
    CV_READ_SEQ_ELEM(pts(1), SizeOf(CvPoint), reader)
    CV_READ_SEQ_ELEM(pts(2), SizeOf(CvPoint), reader)
    CV_READ_SEQ_ELEM(pts(3), SizeOf(CvPoint), reader)
    cvPolyLine(*image, pts(), @npts, 1, #True, 0, 255, 0, 0, 3, #CV_AA, #Null)
  Next
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

    If *resize\nChannels = 3
      *reset.IplImage = cvCloneImage(*resize)
      *storage.CvMemStorage = cvCreateMemStorage(0)
      cvClearMemStorage(*storage)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          DrawSquares(*resize, FindSquares(*resize, *storage))
          cvShowImage(#CV_WINDOW_NAME, *resize)
          keyPressed = cvWaitKey(0)
          cvReleaseImage(@*resize)
          *resize.IplImage = cvCloneImage(*reset)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*resset)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
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

OpenCV("images/shapes.png")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\