IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, hWnd_floodfill, nFlags, nLoDiff, nUpDiff

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Demonstration of the FloodFill function, filling a connected component with a given color." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Maximal lower brightness difference between pixels." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Maximal upper brightness difference between pixels." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle connectivity." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset images." + #LF$ + #LF$ +
                  "[ F ] KEY   " + #TAB$ + ": Toggle Fixed / Floating."

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
      SendMessage_(hWnd_floodfill, #WM_CLOSE, 0, 0)
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
      cvThreshold(*param\Pointer2, *param\Pointer2, 1, 128, #CV_THRESH_BINARY)
      comp.CvConnectedComp
      cvFloodFill(*param\Pointer1, x, y, Random(255), Random(255), Random(255), 0, nLoDiff, nLoDiff, nLoDiff, 0, nUpDiff, nUpDiff, nUpDiff, 0, @comp, nFlags, *param\Pointer2)
      cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
      cvShowImage(#CV_WINDOW_NAME + " - Floodfill", *param\Pointer2)
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos) : EndProcedure
ProcedureC CvTrackbarCallback2(pos) : EndProcedure

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

    If *image\width * 2 >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48 + 42)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / (*image\width * 2)
      iHeight = dtHeight - (100 + 48 + 42)
      iRatio2.d = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight + 48 + 42)
      *resize1.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize1, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48 + 42)
      *resize1.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize1\width > 200 And *resize1\height > 200
      nLoDiff = 20 : nUpDiff = 20
      cvCreateTrackbar("loDiff", #CV_WINDOW_NAME, @nLoDiff, 255, @CvTrackbarCallback1())
      cvCreateTrackbar("upDiff", #CV_WINDOW_NAME, @nUpDiff, 255, @CvTrackbarCallback2())
      nFlags = 4 + (255 << 8) + #CV_FLOODFILL_FIXED_RANGE
      *reset.IplImage = cvCloneImage(*resize1)
      cvNamedWindow(#CV_WINDOW_NAME + " - Floodfill", #CV_WINDOW_AUTOSIZE)
      hWnd_floodfill = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Floodfill"))
      SendMessage_(hWnd_floodfill, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_floodfill, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_floodfill, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - Floodfill", *resize1\width, *resize1\height)
      cvMoveWindow(#CV_WINDOW_NAME + " - Floodfill", *resize1\width + 50, 20)
      *resize2.IplImage = cvCreateImage(*resize1\width + 2, *resize1\height + 2, #IPL_DEPTH_8U, 1)
      cvSetZero(*resize2)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize1
      *param\Pointer2 = *resize2
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize1
          cvShowImage(#CV_WINDOW_NAME, *resize1)
          cvShowImage(#CV_WINDOW_NAME + " - Floodfill", *resize2)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              cvCopy(*reset, *resize1, #Null)
              cvSetZero(*resize2)
            Case 32
              nConnect ! #True

              If nConnect
                nFlags + 4
              Else
                nFlags - 4
              EndIf
            Case 70, 102
              nFill ! #True

              If nFill
                nFlags - #CV_FLOODFILL_FIXED_RANGE
              Else
                nFlags + #CV_FLOODFILL_FIXED_RANGE
              EndIf
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      cvReleaseImage(@*resize2)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*resize1)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize1)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/thinning1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\