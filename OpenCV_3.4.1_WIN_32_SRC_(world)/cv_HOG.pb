IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nCellSize, nBlockSize

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Histogram of Oriented Gradients (HOG) is used to detect objects." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Set cell size." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Set block size." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://lear.inrialpes.fr/people/triggs/pubs/Dalal-cvpr05.pdf")
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos)
  nCellSize = pos + 8
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  nBlockSize = pos + 1
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

Procedure SetHOG(*resize.IplImage)
  nMin = 255 : nMax = 0

  For y = 0 To *resize\height - 1
    For x = 0 To *resize\width - 1
      nNum = PeekA(@*resize\imageData\b + y * *resize\widthStep + x)

      If nNum < nMin : nMin = nNum : EndIf
      If nNum > nMax : nMax = nNum : EndIf

    Next
  Next
  *numImage.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_64F, 1)) : cvSetZero(*numImage)

  For y = 0 To *resize\height - 1
    For x = 0 To *resize\width - 1
      nNum = PeekA(@*resize\imageData\b + y * *resize\widthStep + x)
      PokeD(@*numImage\db\d + y * *numImage\Step + x * 8, nNum * (nMax - nMin) / 255)
    Next
  Next
  *gradientMagnitude.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_64F, 1)) : cvSetZero(*gradientMagnitude)
  *gradientOrientation.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_64F, 1)) : cvSetZero(*gradientOrientation)

  For y = 0 To *numImage\rows - 1
    For x = 0 To *numImage\cols - 1
      x1 = 0 : x2 = 0

      If x = 0
        x1 = x
        x2 = x + 1
      ElseIf x = *numImage\cols - 1
        x1 = x - 1
        x2 = x
      Else
        x1 = x - 1
        x2 = x + 1
      EndIf
      y1 = 0 : y2 = 0

      If y = 0
        y1 = y
        y2 = y + 1
      ElseIf y = *numImage\rows - 1
        y1 = y - 1
        y2 = y
      Else
        y1 = y - 1
        y2 = y + 1
      EndIf
      fx.d = PeekD(@*numImage\db\d + y * *numImage\Step + x2 * 8) - PeekD(@*numImage\db\d + y * *numImage\Step + x1 * 8)
      fy.d = PeekD(@*numImage\db\d + y2 * *numImage\Step + x * 8) - PeekD(@*numImage\db\d + y1 * *numImage\Step + x * 8)
      PokeD(@*gradientMagnitude\db\d + y * *gradientMagnitude\Step + x * 8, Sqr(fx * fx + fy * fy))

      If fx = 0
        PokeD(@*gradientOrientation\db\d + y * *gradientOrientation\Step + x * 8, #PI / 2)
      Else
        nVal1.d = ATan(fy / fx)
        PokeD(@*gradientOrientation\db\d + y * *gradientOrientation\Step + x * 8, nVal1)

        If nVal1 < 0
          nVal2.d = PeekD(@*gradientOrientation\db\d + y * *gradientOrientation\Step + x * 8)
          PokeD(@*gradientOrientation\db\d + y * *gradientOrientation\Step + x * 8, nVal2 + #PI)
        EndIf
      EndIf
    Next
  Next
  Dim CELL_SIZE(1) : Dim BLOCK_SIZE(1)
  CELL_SIZE(0) = nCellSize : CELL_SIZE(1) = nCellSize : BLOCK_SIZE(0) = nBlockSize : BLOCK_SIZE(1) = nBlockSize : GRADIENT_SIZE = 9
  Dim histogram1.d(*numImage\rows / CELL_SIZE(1), *numImage\cols / CELL_SIZE(0), GRADIENT_SIZE)

  For i = 0 To *numImage\rows / CELL_SIZE(1) - 1
    For j = 0 To *numImage\cols / CELL_SIZE(0) - 1
      For k = 0 To GRADIENT_SIZE - 1
        histogram1(i, j, k) = 0
      Next
    Next
  Next

  For i = 0 To *numImage\rows / CELL_SIZE(1) - 1
    For j = 0 To *numImage\cols / CELL_SIZE(0) - 1
      For k = 0 To CELL_SIZE(1) - 1
        For l = 0 To CELL_SIZE(0) - 1
          y = i * CELL_SIZE(1) + k
          x = j * CELL_SIZE(0) + l
          m = PeekD(@*gradientOrientation\db\d + y * *gradientOrientation\Step + x * 8) * 180 / #PI / (180 / GRADIENT_SIZE)
          histogram1(i, j, m) + PeekD(@*gradientMagnitude\db\d + y * *gradientMagnitude\Step + x * 8)
        Next
      Next
    Next
  Next
  *blockSum.CvMat = cvCreateMat(*numImage\rows / CELL_SIZE(1) - (BLOCK_SIZE(1) - 2), *numImage\cols / CELL_SIZE(0) - (BLOCK_SIZE(0) - 1), CV_MAKETYPE(#CV_64F, 1)) : cvSetZero(*blockSum)

  For i = 0 To *numImage\rows / CELL_SIZE(1) - (BLOCK_SIZE(1) - 1)
    For j = 0 To *numImage\cols / CELL_SIZE(0) - (BLOCK_SIZE(0) - 1)
      For k = 0 To BLOCK_SIZE(1) - 1
        For l = 0 To BLOCK_SIZE(0) - 1
          For m = 0 To GRADIENT_SIZE - 1
            nSum.d = PeekD(@*blockSum\db\d + i * *blockSum\Step + j * 8)
            PokeD(@*blockSum\db\d + i * *blockSum\Step + j * 8, nSum + Pow(histogram1(i + k, j + l, m), 2))
          Next
        Next
      Next
    Next
  Next
  Dim histogram2.d(*numImage\rows / CELL_SIZE(1), *numImage\cols / CELL_SIZE(0), GRADIENT_SIZE)
  CopyArray(histogram1(), histogram2())

  For i = 0 To *numImage\rows / CELL_SIZE(1) - (BLOCK_SIZE(1) - 1)
    For j = 0 To *numImage\cols / CELL_SIZE(0) - (BLOCK_SIZE(0) - 1)
      For k = 0 To BLOCK_SIZE(1) - 1
        For l = 0 To BLOCK_SIZE(0) - 1
          For m = 0 To GRADIENT_SIZE - 1
            nSum = PeekD(@*blockSum\db\d + i * *blockSum\Step + j * 8)
            histogram1(i + k, j + l, m) = histogram2(i + k, j + l, m) / Sqr(nSum + 1)
          Next
        Next
      Next
    Next
  Next
  *color.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
  cvCvtColor(*resize, *color, #CV_GRAY2BGR, 1)

  For i = 0 To *numImage\rows / CELL_SIZE(1) - 1
    cvLine(*color, 0, i * CELL_SIZE(1), *numImage\cols, i * CELL_SIZE(1), 25, 51, 0, 0, 1, #CV_AA, #Null)
  Next

  For i = 0 To *numImage\cols / CELL_SIZE(0) - 1
    cvLine(*color, i * CELL_SIZE(0), 0, i * CELL_SIZE(0), *numImage\rows, 25, 51, 0, 0, 1, #CV_AA, #Null)
  Next

  For i = 0 To *numImage\rows / CELL_SIZE(1) - 1
    For j = 0 To *numImage\cols / CELL_SIZE(0) - 1
      For k = 0 To GRADIENT_SIZE - 1
        If histogram1(i, j, k) > 0.2
          sy = i * CELL_SIZE(1) + 8 * Sin(#PI * ((180 / GRADIENT_SIZE) * k + 90) / 180) + CELL_SIZE(1) / 2
          sx = j * CELL_SIZE(0) + 8 * Cos(#PI * ((180 / GRADIENT_SIZE) * k + 90) / 180) + CELL_SIZE(0) / 2
          dy = i * CELL_SIZE(1) - 8 * Sin(#PI * ((180 / GRADIENT_SIZE) * k + 90) / 180) + CELL_SIZE(1) / 2
          dx = j * CELL_SIZE(0) - 8 * Cos(#PI * ((180 / GRADIENT_SIZE) * k + 90) / 180) + CELL_SIZE(0) / 2
          cvLine(*color, sx, sy, dx, dy, 0, 255, 255, 0, 1, #CV_AA, #Null)
        EndIf
      Next
    Next
  Next
  cvReleaseMat(@*blockSum)
  cvReleaseMat(@*gradientOrientation)
  cvReleaseMat(@*gradientMagnitude)
  cvReleaseMat(@*numImage)
  ProcedureReturn *color
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
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_GRAYSCALE)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48 + 42)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *image\width
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
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48 + 42)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200
      nCellSize = 8 : nBlockSize = 1
      cvCreateTrackbar("Cell Size", #CV_WINDOW_NAME, @nCellSize, 24, @CvTrackbarCallback1())
      cvCreateTrackbar("Block Size", #CV_WINDOW_NAME, @nBlockSize, 4, @CvTrackbarCallback2())
      nCellSize = 16 : nBlockSize = 2
      *color.IplImage = SetHOG(*resize) : Delay(100)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *color
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *color
          cvShowImage(#CV_WINDOW_NAME, *color)
          keyPressed = cvWaitKey(0)

          If keyPressed = 13
            cvReleaseImage(@*color)
            *color = SetHOG(*resize)
            *param\Pointer1 = *color
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*color)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/starrynight.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\