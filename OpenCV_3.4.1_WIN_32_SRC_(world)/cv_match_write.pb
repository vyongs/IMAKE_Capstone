IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, *reset.CvContour, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Tries to match contours learned from one image file containing numbers against another, " +
                  "then duplicate the number sequence using text." + #LF$ + #LF$ +
                  "Double-Click the window to open the original image."

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
            xmlName.s = GetFilePart(FileName, #PB_FileSystem_NoExtension)
            attributes.ATTR_LIST
            attributes\attribute_name = "recursive"
            attributes\attribute_value = "1"
            attributes\terminated = #Null
            cvSave("objects/" + xmlName + "_contours.xml", *reset, "JHPJHP", #NULL$, @attributes, #Null)
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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("mspaint", "num_write.png", "images")
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
    *image1.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    cvResizeWindow(#CV_WINDOW_NAME, *image1\width, *image1\height)
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)
    *gray1.IplImage = cvCreateImage(*image1\width, *image1\height, #IPL_DEPTH_8U, 1)
    cvCvtColor(*image1, *gray1, #CV_BGR2GRAY, 1)
    cvSmooth(*gray1, *gray1, #CV_MEDIAN, 3, 0, 0, 0)
    cvAdaptiveThreshold(*gray1, *gray1, 255, #CV_ADAPTIVE_THRESH_GAUSSIAN_C, #CV_THRESH_BINARY_INV, 3, 0)
    cvEqualizeHist(*gray1, *gray1)
    *storage1.CvMemStorage = cvCreateMemStorage(0)
    cvClearMemStorage(*storage1)
    *contours1.CvContour
    nContours1 = cvFindContours(*gray1, *storage1, @*contours1, SizeOf(CvContour), #CV_RETR_LIST, #CV_CHAIN_APPROX_SIMPLE, 0, 0)

    If nContours1
      *image2.IplImage = cvLoadImage("images/num_train.png", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
      *gray2.IplImage = cvCreateImage(*image2\width, *image2\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*image2, *gray2, #CV_BGR2GRAY, 1)
      cvSmooth(*gray2, *gray2, #CV_MEDIAN, 3, 0, 0, 0)
      cvAdaptiveThreshold(*gray2, *gray2, 255, #CV_ADAPTIVE_THRESH_GAUSSIAN_C, #CV_THRESH_BINARY_INV, 3, 0)
      cvEqualizeHist(*gray2, *gray2)
      *storage2.CvMemStorage = cvCreateMemStorage(0)
      cvClearMemStorage(*storage2)
      *contours2.CvContour
      nContours2 = cvFindContours(*gray2, *storage2, @*contours2, SizeOf(CvContour), #CV_RETR_LIST, #CV_CHAIN_APPROX_SIMPLE, 0, 0)

      If nContours2
        font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 1, 1, #Null, 1, #CV_AA)
        *match.IplImage = cvCreateImage(*gray1\width, *gray1\height, #IPL_DEPTH_8U, 3)
        cvSet(*match, 255, 255, 255, 0, #Null)
        *reset = *contours2

        If OpenFile(0, "trained/numbers.txt")
          trained.s = ReadString(0)
          CloseFile(0)
        EndIf

        For rtnCount1 = 0 To nContours1 - 1
          area.d = cvContourArea(*contours1, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If *contours1\rect\height > 28 And *contours1\rect\width < 40 And area >= 50 And area <= 100000
            *contours2 = *reset

            For rtnCount2 = 0 To nContours2 - 1
              area.d = cvContourArea(*contours2, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

              If *contours2\rect\height > 28 And *contours2\rect\width < 40 And area >= 50 And area <= 100000
                match.d = cvMatchShapes(*contours1, *contours2, #CV_CONTOURS_MATCH_I3, 0)

                If match < 0.001
                  position = FindString(trained, "[" + Right("000" + Str(rtnCount2), 4) + "]")
                  cvPutText(*match, Chr(Val(Mid(trained, position + 6, 2))), *contours1\rect\x, *contours1\rect\y + *contours1\rect\height, @font, 255, 0, 0, 0)
                  Break
                EndIf
              EndIf
              *contours2 = *contours2\h_next
            Next
          EndIf
          *contours1 = *contours1\h_next
        Next
        *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
        *param\Pointer1 = *match
        *param\Value = window_handle
        cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

        Repeat
          If *match
            cvShowImage(#CV_WINDOW_NAME, *match)
            keyPressed = cvWaitKey(0)
          EndIf
        Until keyPressed = 27 Or exitCV
        FreeMemory(*param)
        cvReleaseImage(@*match)
      EndIf
    EndIf
    cvReleaseMemStorage(@*storage2)
    cvReleaseMemStorage(@*storage1)
    cvReleaseImage(@*gray2)
    cvReleaseImage(@*gray1)
    cvReleaseImage(@*image2)
    cvReleaseImage(@*image1)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/num_write.png")
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\