IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Creates a text file to later match contours against two image files containing numbers." + #LF$ + #LF$ +
                  "ENTER       " + #TAB$ + ": Skip current number." + #LF$ + #LF$ +
                  "[ 0-9 ] KEY " + #TAB$ + ": Match number."

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
    cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)
    *gray.IplImage = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 1)
    cvCvtColor(*image, *gray, #CV_BGR2GRAY, 1)
    cvSmooth(*gray, *gray, #CV_MEDIAN, 3, 0, 0, 0)
    cvAdaptiveThreshold(*gray, *gray, 255, #CV_ADAPTIVE_THRESH_GAUSSIAN_C, #CV_THRESH_BINARY_INV, 3, 0)
    cvEqualizeHist(*gray, *gray)
    *storage.CvMemStorage = cvCreateMemStorage(0)
    cvClearMemStorage(*storage)
    *contours.CvContour
    nContours = cvFindContours(*gray, *storage, @*contours, SizeOf(CvContour), #CV_RETR_LIST, #CV_CHAIN_APPROX_SIMPLE, 0, 0)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *image
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    If nContours
      For rtnCount = 0 To nContours - 1
        area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

        If *contours\rect\height > 28 And *contours\rect\width < 40 And area >= 50 And area <= 100000
          cvRectangleR(*image, *contours\rect\x, *contours\rect\y, *contours\rect\width, *contours\rect\height, 0, 0, 255, 0, 1, #CV_AA, #Null)

          Repeat
            cvShowImage(#CV_WINDOW_NAME, *image)
            keyPressed = cvWaitKey(0)
          Until keyPressed = 13 Or keyPressed = 27 Or (keyPressed >= 48 And keyPressed <= 58) Or exitCV
          cvRectangleR(*image, *contours\rect\x, *contours\rect\y, *contours\rect\width, *contours\rect\height, 0, 255, 0, 0, 1, #CV_AA, #Null)

          If keyPressed >= 48 And keyPressed <= 58
            train.s + "[" + Right("000" + Str(rtnCount), 4) + "]" + Str(keyPressed)
          Else
            If keyPressed = 27 Or exitCV : Break : Else : train.s + "[" + Right("000" + Str(rtnCount), 4) + "]XX" : EndIf
          EndIf
        Else
          train.s + "[" + Right("000" + Str(rtnCount), 4) + "]XX"
        EndIf
        *contours = *contours\h_next
      Next

      If keyPressed <> 27 And exitCV = #False
        If OpenFile(0, "trained/numbers.txt")
          WriteString(0, train)
          CloseFile(0)
          MessageRequester("Training", "Trained file saved.")
        EndIf

        Repeat
          If *image
            cvShowImage(#CV_WINDOW_NAME, *image)
            keyPressed = cvWaitKey(0)
          EndIf
        Until keyPressed = 27 Or exitCV
      EndIf
      FreeMemory(*param)
    EndIf
    cvReleaseMemStorage(@*storage)
    cvReleaseImage(@*gray)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/num_train.png")
; IDE Options = PureBasic 5.30 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\