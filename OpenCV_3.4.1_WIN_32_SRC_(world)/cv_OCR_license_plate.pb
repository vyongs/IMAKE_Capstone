IncludeFile "includes/cv_functions.pbi"
IncludeFile "includes/pb_tesseract.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "License plate OCR (Optical Character Recognition)."

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
      *resize1.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize1, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
      *resize1.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize1\nChannels = 1
      *gray1.IplImage = cvCloneImage(*resize1)
    Else
      *gray1.IplImage = cvCreateImage(*resize1\width, *resize1\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize1, *gray1, #CV_BGR2GRAY, 1)
    EndIf
    cvSmooth(*gray1, *gray1, #CV_BLUR, 5, 0, 0, 0)
    *sobel.IplImage = cvCreateImage(*resize1\width, *resize1\height, #IPL_DEPTH_8U, 1)
    cvSobel(*gray1, *sobel, 1, 0, 3)
    *threshold1.IplImage = cvCloneImage(*sobel)
    cvThreshold(*sobel, *threshold1, 0, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)
    *temp.IplImage = cvCloneImage(*threshold1)
    *kernel.IplConvKernel = cvCreateStructuringElementEx(17, 5, 0, 0, #CV_SHAPE_RECT, 0)
    cvMorphologyEx(*threshold1, *threshold1, *temp, *kernel, #CV_MOP_CLOSE, 1)
    cvReleaseStructuringElement(@*kernel)
    *storage.CvMemStorage = cvCreateMemStorage(0)
    cvClearMemStorage(*storage)
    *contours.CvSeq
    nContours = cvFindContours(*threshold1, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)
    *contour.IplImage = cvCreateImage(*gray1\width, *gray1\height, #IPL_DEPTH_8U, 3)
    cvSet(*contour, 5, 5, 5, 0, #Null)
    box.CvBox2D
    Dim pt.CvPoint2D32f(4)
    Dim boxes.CvBox2D(0)
    minHeight.f = 28
    maxHeight.f = 55
    minAspect.f = 0.18
    maxAspect.f = 45 / 77 * 2 * 0.35

    For rtnCount = 0 To nContours - 1
      area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

      If area >= 1000 And area <= 7000
        cvMinAreaRect2(@box, *contours, #Null)

        If Abs(box\angle) < 45
          cAspect.d = box\size\height / box\size\width
          bHeight.d = box\size\height
        Else
          cAspect.d = box\size\width / box\size\height
          bHeight.d = box\size\width
        EndIf
        bArea.d = box\size\width * box\size\height
        percPixels.d = area / bArea

        If cAspect > minAspect And cAspect < maxAspect And percPixels < 0.8 And bHeight >= minHeight And bHeight < maxHeight
          cvBoxPoints(box\center\x, box\center\y, box\size\width, box\size\height, box\angle, pt())

          For pCount = 0 To 4 - 1
            cvLine(*contour, pt(pCount)\x, pt(pCount)\y, pt((pCount + 1) % 4)\x, pt((pCount + 1) % 4)\y, 0, 255, 255, 0, 2, #CV_AA, #Null)
          Next
          cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
          nCount + 1
          boxes(nCount - 1) = box
          ReDim boxes(nCount)
        EndIf
      EndIf
      *contours = *contours\h_next
    Next
    *clone.IplImage = cvCloneImage(*resize1)
    *mask.IplImage = cvCreateImage(*resize1\width + 2, *resize1\height + 2, #IPL_DEPTH_8U, 1)
    seed.cvPoint
    comp.CvConnectedComp
    *seq.CvSeq
    points.CvPoint
    minRect.CvBox2D
    *mat.CvMat
    *rotated.IplImage
    rect_size.CvSize2D32f
    *crop.IplImage
    *resize2.IplImage
    *gray2.IplImage
    *threshold2.IplImage
    rect.CvRect

    For nBox = 0 To nCount - 1
      cvCircle(*clone, boxes(nBox)\center\x, boxes(nBox)\center\y, 2, 0, 255, 0, 0, 2, #CV_AA, #Null)

      If boxes(nBox)\size\width > boxes(nBox)\size\height
        minSize.f = boxes(nBox)\size\height
        maxSize.f = boxes(nBox)\size\width
      Else
        minSize.f = boxes(nBox)\size\width
        maxSize.f = boxes(nBox)\size\height
      EndIf
      minSize = minSize - minSize * 0.5
      maxSize = maxSize - maxSize * 0.5
      cvSet(*mask, 0, 0, 0, 0, #Null)

      For rtnCount = 1 To 10
        seed\x = boxes(nBox)\center\x + Random(maxSize) - maxSize / 2
        seed\y = boxes(nBox)\center\y + Random(minSize) - minSize / 2
        cvCircle(*clone, seed\x, seed\y, 1, 0, 255, 255, 0, 1, #CV_AA, #Null)
        cvFloodFill(*resize1, seed\x, seed\y, 255, 0, 0, 0, 30, 30, 30, 0, 30, 30, 30, 0, @comp, 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE | #CV_FLOODFILL_MASK_ONLY, *mask)
      Next
      #CV_SEQ_ELTYPE_POINT = CV_MAKETYPE(#CV_32S, 2)
      *seq = cvCreateSeq(#CV_SEQ_ELTYPE_POINT, SizeOf(CvSeq), SizeOf(CvPoint), *storage)

      For y = 0 To *mask\height - 1
        *pt = *mask\imageData + y * *mask\widthstep

        For x = 0 To *mask\width - 1
          *ptr = *pt + x

          If PeekA(*ptr) = 255
            points\x = x
            points\y = y
            cvSeqPush(*seq, @points)
          EndIf
        Next
      Next
      cvMinAreaRect2(@minRect, *seq, #Null)

      If Abs(minRect\angle) < 45
        cAspect.d = minRect\size\height / minRect\size\width
        bHeight.d = minRect\size\height
      Else
        cAspect.d = minRect\size\width / minRect\size\height
        bHeight.d = minRect\size\width
      EndIf
      bArea.d = minRect\size\width * minRect\size\height
      percPixels.d = area / bArea

      If cAspect > minAspect And cAspect < maxAspect And bHeight >= minHeight And bHeight < maxHeight
        cvBoxPoints(minRect\center\x, minRect\center\y, minRect\size\width, minRect\size\height, minRect\angle, pt())

        For pCount = 0 To 4 - 1
          cvLine(*resize1, pt(pCount)\x, pt(pCount)\y, pt((pCount + 1) % 4)\x, pt((pCount + 1) % 4)\y, 0, 255, 255, 0, 2, #CV_AA, #Null)
        Next
        test.f = minRect\size\width / minRect\size\height
        angle.f = minRect\angle

        If test < 1 : angle = 90 + minRect\angle : EndIf

        *mat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1))
        cv2DRotationMatrix(minRect\center\x, minRect\center\y, angle, 1, *mat)
        *rotated = cvCloneImage(*resize1)
        cvWarpAffine(*resize1, *rotated, *mat, #CV_INTER_CUBIC, 0, 255, 0, 0)
        rect_size\width = minRect\size\width
        rect_size\height = minRect\size\height

        If test < 1
          temp.f = rect_size\width
          rect_size\width = rect_size\height
          rect_size\height = temp
        EndIf
        *crop = cvCreateImage(rect_size\width, rect_size\height, #IPL_DEPTH_8U, *rotated\nChannels)
        cvGetRectSubPix(*rotated, *crop, minRect\center\x, minRect\center\y)
        *resize2 = cvCreateImage(144, 33, #IPL_DEPTH_8U, *crop\nChannels)
        cvResize(*crop, *resize2, #CV_INTER_CUBIC)
        hAPI = TesseractInit(#PSM_AUTO, #OEM_TESSERACT_ONLY, #PB_Compiler_FilePath + "binaries/tesseract/tessdata", "eng", #PB_Compiler_FilePath + "binaries/tesseract/tessdata/whitelist.cfg")

        If hAPI
          textOCR.s = OpenCVImage2TextOCR(hAPI, *crop)
          cvRectangleR(*resize1, 10, 10, 150, 38, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
          cvRectangleR(*resize1, 12, 12, 146, 34, 255, 255, 255, 0, 1, #CV_AA, #Null)
          font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_DUPLEX | #CV_FONT_ITALIC, 1, 0.7, #Null, 1, #CV_AA)
          cvPutText(*resize1, textOCR, 34, 38, @font, 255, 255, 255, 0)
        EndIf
        *gray2 = cvCreateImage(*resize2\width, *resize2\height, #IPL_DEPTH_8U, 1)
        cvCvtColor(*resize2, *gray2, #CV_BGR2GRAY, 1)
        cvSmooth(*gray2, *gray2, #CV_BLUR, 3, 0, 0, 0)
        cvEqualizeHist(*gray2, *gray2)
        *threshold2 = cvCreateImage(*resize2\width, *resize2\height, #IPL_DEPTH_8U, 1)
        cvThreshold(*gray2, *threshold2, 60, 255, #CV_THRESH_BINARY_INV)
        cvClearMemStorage(*storage)
        nContours = cvFindContours(*threshold2, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

        For rtnCount = 0 To nContours - 1
          cvBoundingRect(@rect, *contours, 0)
          cvRectangleR(*resize2, rect\x - 1, rect\y - 1, rect\width + 2, rect\height + 2, 0, 0, 255, 0, 1, #CV_AA, #Null)
          *contours = *contours\h_next
        Next
        cvSetImageROI(*resize1, boxes(nBox)\center\x - 50, boxes(nBox)\center\y - 65, 144, 33)
        cvAndS(*resize1, 0, 0, 0, 0, *resize1, #Null)
        cvAdd(*resize1, *resize2, *resize1, #Null)
        cvResetImageROI(*resize1)
      EndIf
    Next
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *resize1
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *resize1
        cvShowImage(#CV_WINDOW_NAME, *resize1)
        keyPressed = cvWaitKey(0)
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseMemStorage(@*storage)
    cvReleaseImage(@*threshold2)
    cvReleaseImage(@*gray2)
    cvReleaseImage(@*resize2)
    cvReleaseImage(@*crop)
    cvReleaseImage(@*rotated)
    cvReleaseMat(@*mat)
    cvReleaseImage(@*mask)
    cvReleaseImage(@*clone)
    cvReleaseImage(@*contour)
    cvReleaseImage(@*temp)
    cvReleaseImage(@*threshold1)
    cvReleaseImage(@*sobel)
    cvReleaseImage(@*gray1)
    cvReleaseImage(@*resize1)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If openCV
      openCV = #False
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/license_plate.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\