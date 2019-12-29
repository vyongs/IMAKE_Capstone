IncludeFile "includes/cv_functions.pbi"
IncludeFile "includes/pb_tesseract.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Speed sign OCR (Optical Character Recognition)."

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

Procedure CvMouseCallback(event, x, y, flags, *param.CvUserData)
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

    If *resize\nChannels = 3
      *dst0.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *dst1.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *dst2.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *diff.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *dst2mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvSet(*mask, 0, 0, 0, 0, #Null)
      cvSplit(*resize, *dst0, *dst1, *dst2, #Null)
      cvAbsDiff(*dst1, *dst2, *diff)
      comp.CvConnectedComp
      cvFloodFill(*diff, 2, 2, 255, 0, 0, 0, 30, 30, 30, 0, 30, 30, 30, 0, @comp, 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE, #Null)
      cvThreshold(*diff, *diff, 60, 255, #CV_THRESH_BINARY_INV)
      *storage.CvMemStorage = cvCreateMemStorage(0)
      cvClearMemStorage(*storage)
      *contours.CvContour
      nContours = cvFindContours(*diff, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_SIMPLE, 0, 0)

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If area >= 300 And area <= 30000
            perim.d = cvArcLength(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 1)
            ratio.d = perim * perim / (4 * #PI * area)

            If ratio > 1.0 And ratio < 1.2
              cvEllipse(*mask, *contours\rect\x + (*contours\rect\width / 2), *contours\rect\y + (*contours\rect\height / 2), *contours\rect\width / 2 - (*contours\rect\width / 16), *contours\rect\height / 2 - (*contours\rect\height / 16), 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
            EndIf
          EndIf
          *contours = *contours\h_next
        Next
      EndIf
      cvCopy(*dst2, *dst2mask, *mask)
      *tesseract.IplImage = cvCloneImage(*dst2mask)
      cvFloodFill(*tesseract, 2, 2, 255, 0, 0, 0, 20, 20, 20, 0, 20, 20, 20, 0, @comp, 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE, #Null)
      cvFloodFill(*dst2mask, 2, 2, 255, 0, 0, 0, 20, 20, 20, 0, 20, 20, 20, 0, @comp, 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE, #Null)
      cvThreshold(*dst2mask, *dst2mask, 150, 255, #CV_THRESH_BINARY_INV)
      cvClearMemStorage(*storage)
      nContours = cvFindContours(*dst2mask, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)
      rect.CvRect

      For rtnCount = 0 To nContours - 1
        area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

        If area >= 5
          cvBoundingRect(@rect, *contours, 0)
          cvRectangleR(*resize, rect\x - 1, rect\y - 1, rect\width + 1, rect\height + 1, 255, 0, 0, 0, 2, #CV_AA, #Null)

          If  xMin = 0 : xMin = *contours\rect\x : Else : CV_MIN(xMin, *contours\rect\x) : EndIf
          If  yMin = 0 : yMin = *contours\rect\y : Else : CV_MIN(yMin, *contours\rect\y) : EndIf
          If  xMax = 0 : xMax = *contours\rect\x + *contours\rect\width  : Else : CV_MAX(xMax, *contours\rect\x + *contours\rect\width) : EndIf
          If  yMax = 0 : yMax = *contours\rect\y + *contours\rect\height : Else : CV_MAX(yMax, *contours\rect\y + *contours\rect\height) : EndIf

          colorFF.a = PeekA(@CV_IMAGE_ELEM(*tesseract, *contours\rect\y - 1, *contours\rect\x - 1))
          cvFloodFill(*tesseract, 2, 2, colorFF, 0, 0, 0, 30, 30, 30, 0, 30, 30, 30, 0, @comp, 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE, #Null)
        EndIf
        *contours = *contours\h_next
      Next
      *imgtoOCR.IplImage = cvCreateImage(xMax - xMin + 20, yMax - yMin + 20, #IPL_DEPTH_8U, *tesseract\nChannels)
      cvSetImageROI(*tesseract, xMin - 10, yMin - 10, xMax - xMin + 20, yMax - yMin + 20)
      cvCopy(*tesseract, *imgtoOCR, #Null)
      cvResetImageROI(*tesseract)
      cvThreshold(*imgtoOCR, *imgtoOCR, 60, 255, #CV_THRESH_OTSU)
      hAPI = TesseractInit(#PSM_AUTO, #OEM_TESSERACT_ONLY, #PB_Compiler_FilePath + "binaries/tesseract/tessdata", "eng", #PB_Compiler_FilePath + "binaries/tesseract/tessdata/whitelist.cfg")

      If hAPI
        textOCR.s = OpenCVImage2TextOCR(hAPI, *imgtoOCR)
        font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_DUPLEX  | #CV_FONT_ITALIC, 1.0, 1.3, #Null, 1, #CV_AA)
        cvCircle(*resize, 48, 48, 20, 255, 255, 255, 0, 45, #CV_AA, 0)
        cvCircle(*resize, 48, 48, 39, 45, 45, 255, 0, 3, #CV_AA, 0)

        If Len(textOCR) > 2 : cvPutText(*resize, textOCR, 12, 60, @font, 0, 0, 0, 0) : Else : cvPutText(*resize, textOCR, 25, 60, @font, 0, 0, 0, 0) : EndIf

      EndIf
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          cvShowImage(#CV_WINDOW_NAME, *resize)
          keyPressed = cvWaitKey(0)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*dst2)
      cvReleaseImage(@*dst1)
      cvReleaseImage(@*dst0)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvReleaseImage(@*diff)
      cvReleaseImage(@*diffcopy)
      cvReleaseImage(@*mask)
      cvReleaseImage(@*dst2mask)
      cvReleaseImage(@*tesseract)
      cvReleaseImage(@*imgtoOCR)
      cvDestroyWindow(#CV_WINDOW_NAME)

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the channel requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyWindow(#CV_WINDOW_NAME)
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/speed_sign.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\