IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Apply a color posterize effect to an image." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust the threshold." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle flatten image."

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

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

Structure PixelColor
  b.a
  g.a
  r.a
EndStructure

Procedure PixelDraw(*src.IplImage, x, y, *color.PixelColor)
  PokeA(@*src\imageData\b + y * *src\widthStep + x * 3 + 0, *color\b)
  PokeA(@*src\imageData\b + y * *src\widthStep + x * 3 + 1, *color\g)
  PokeA(@*src\imageData\b + y * *src\widthStep + x * 3 + 2, *color\r)
EndProcedure

Procedure PixelSurvey(*src.IplImage, x, y)
  *color.PixelColor = AllocateMemory(SizeOf(PixelColor))
  *color\b = PeekA(@*src\imageData\b + (y * *src\widthStep) + x * 3 + 0)
  *color\g = PeekA(@*src\imageData\b + (y * *src\widthStep) + x * 3 + 1)
  *color\r = PeekA(@*src\imageData\b + (y * *src\widthStep) + x * 3 + 2)
  ProcedureReturn *color
EndProcedure

Procedure CompareColor(*color1.PixelColor, *color2.PixelColor)
  If *color1\r > *color2\r : nDiffR = *color1\r - *color2\r : Else : nDiffR = *color2\r - *color1\r : EndIf
  If *color1\g > *color2\g : nDiffG = *color1\g - *color2\g : Else : nDiffG = *color2\g - *color1\g : EndIf
  If *color1\b > *color2\b : nDiffB = *color1\b - *color2\b : Else : nDiffB = *color2\b - *color1\b : EndIf
	If nDiffR > nDiffG : nDiff = nDiffR : Else : nDiff = nDiffG : EndIf
	If nDiff < nDiffB : nDiff = nDiffB : EndIf

	FreeMemory(*color2)
	FreeMemory(*color1)
	ProcedureReturn nDiff
EndProcedure

Procedure DiffVertical(*src.IplImage, x, y)
  Define.PixelColor *color, *colorBelow

  If y < 0 Or y >= *src\height - 1 : ProcedureReturn 0 : EndIf

  *color = PixelSurvey(*src, x, y)
	*colorBelow = PixelSurvey(*src, x, y + 1)
	ProcedureReturn CompareColor(*color, *colorBelow)
EndProcedure

Procedure DiffHorizontal(*src.IplImage, x, y)
  Define.PixelColor *color, *colorRight

  If x < 0 Or x >= *src\width - 1 : ProcedureReturn 0 : EndIf

  *color = PixelSurvey(*src, x, y)
	*colorRight = PixelSurvey(*src, x + 1, y)
	ProcedureReturn CompareColor(*color, *colorRight)
EndProcedure

Procedure GetPointMode(*src.IplImage, x, y, nThreshold)
  nDiff = DiffHorizontal(*src, x, y)

  If nDiff > nThreshold
    nPointMode = 1

		For i = -2 To 3 - 1
		  If nDiff < DiffHorizontal(*src, x + i, y) : nPointMode = 0 : Break : EndIf
		Next
	EndIf
	nDiff = DiffVertical(*src, x, y)

  If nDiff > nThreshold
    nPointMode = 1

		For i = -2 To 3 - 1
		  If nDiff < DiffVertical(*src, x, y + i) : nPointMode = 0 : Break : EndIf
		Next
	EndIf
	ProcedureReturn nPointMode
EndProcedure

Procedure PosterizeImage(*src.IplImage, *hsv.IplImage, *dst.IplImage, nThreshold, Array arrTile(2))
  Define.PixelColor *black, *color
  *black = AllocateMemory(SizeOf(PixelColor))
  *black\b = 0 : *black\g = 0 : *black\r = 0

  For y = 0 To *src\height - 1
    For x = 0 To *src\width - 1
      *color = PixelSurvey(*hsv, x, y)
      nMode = GetPointMode(*src, x, y, nThreshold)

      If nMode = 1
        PixelDraw(*dst, x, y, *black)
      Else
        nValue = *color\r / 24
				*color\r = 255
				*color\b / 8 * 8

				If arrTile(nValue, (y % 4) * 4 + x % 4) : PixelDraw(*dst, x, y, *color) : Else : PixelDraw(*dst, x, y, *black) : EndIf

      EndIf
    Next
  Next
  FreeMemory(*color)
  FreeMemory(*black)
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

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *image\width
      iHeight = dtHeight - (100 + 48)
      iRatio2.d = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight + 48)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      nThreshold = 1
      cvCreateTrackbar("Threshold", #CV_WINDOW_NAME, @nThreshold, 5, @CvTrackbarCallback())
      Dim arrTile(11, 16) : arrTile(1, 9) = 1 : arrTile(2, 3) = 1 : arrTile(2, 9) = 1
      arrTile(3, 0) = 1 : arrTile(3, 5) = 1 : arrTile(3, 10) = 1 : arrTile(3, 15) = 1
      arrTile(4, 0) = 1 : arrTile(4, 2) = 1 : arrTile(4, 5) = 1 : arrTile(4, 8) = 1 : arrTile(4, 10) = 1 : arrTile(4, 15) = 1
      arrTile(5, 0) = 1 : arrTile(5, 2) = 1 : arrTile(5, 5) = 1 : arrTile(5, 7) = 1
      arrTile(5, 8) = 1 : arrTile(5, 10) = 1 : arrTile(5, 13) = 1 : arrTile(5, 15) = 1
      arrTile(6, 0) = 1 : arrTile(6, 1) = 1 : arrTile(6, 2) = 1 : arrTile(6, 5) = 1 : arrTile(6, 7) = 1
      arrTile(6, 8) = 1 : arrTile(6, 10) = 1 : arrTile(6, 11) = 1 : arrTile(6, 13) = 1 : arrTile(6, 15) = 1
      arrTile(7, 0) = 1 : arrTile(7, 1) = 1 : arrTile(7, 2) = 1 : arrTile(7, 4) = 1 : arrTile(7, 5) = 1 : arrTile(7, 7) = 1
      arrTile(7, 8) = 1 : arrTile(7, 10) = 1 : arrTile(7, 11) = 1 : arrTile(7, 13) = 1 : arrTile(7, 14) = 1 : arrTile(7, 15) = 1
      arrTile(8, 0) = 1 : arrTile(8, 1) = 1 : arrTile(8, 2) = 1 : arrTile(8, 4) = 1 : arrTile(8, 5) = 1 : arrTile(8, 7) = 1
      arrTile(8, 8) = 1 : arrTile(8, 10) = 1 : arrTile(8, 11) = 1 : arrTile(8, 13) = 1 : arrTile(8, 14) = 1 : arrTile(8, 15) = 1
      arrTile(9, 0) = 1 : arrTile(9, 1) = 1 : arrTile(9, 2) = 1 : arrTile(9, 3) = 1 : arrTile(9, 4) = 1
      arrTile(9, 5) = 1 : arrTile(9, 7) = 1 : arrTile(9, 8) = 1 : arrTile(9, 9) = 1 : arrTile(9, 10) = 1
      arrTile(9, 11) = 1 : arrTile(9, 12) = 1 : arrTile(9, 13) = 1 : arrTile(9, 14) = 1 : arrTile(9, 15) = 1
      arrTile(10, 0) = 1 : arrTile(10, 1) = 1 : arrTile(10, 2) = 1 : arrTile(10, 3) = 1 : arrTile(10, 4) = 1
      arrTile(10, 5) = 1 : arrTile(10, 6) = 1 : arrTile(10, 7) = 1 : arrTile(10, 8) = 1 : arrTile(10, 9) = 1
      arrTile(10, 10) = 1 : arrTile(10, 11) = 1 : arrTile(10, 12) = 1 : arrTile(10, 13) = 1 : arrTile(10, 14) = 1 : arrTile(10, 15) = 1
      *smooth.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *hsv.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *posterize.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *flatten.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *posterize
          If nThreshold
            Select nThreshold
              Case 1 : nValue = 40
              Case 2 : nValue = 10
              Case 3 : nValue = 6
              Case 4 : nValue = 4
              Case 5 : nValue = 3
            EndSelect
            cvSmooth(*resize, *smooth, #CV_BILATERAL, 12, 12, 96, 128)
            cvCvtColor(*resize, *hsv, #CV_BGR2HSV, 1)
            PosterizeImage(*smooth, *hsv, *posterize, nValue, arrTile())
            cvCvtColor(*posterize, *posterize, #CV_HSV2BGR, 1)

            If nFlatten
              cvSmooth(*posterize, *flatten, #CV_GAUSSIAN, 5, 5, 0, 0)
              cvShowImage(#CV_WINDOW_NAME, *flatten)
              *param\Pointer1 = *flatten
            Else
              cvShowImage(#CV_WINDOW_NAME, *posterize)
              *param\Pointer1 = *posterize
            EndIf
          Else
            cvShowImage(#CV_WINDOW_NAME, *resize)
            *param\Pointer1 = *resize
          EndIf
          keyPressed = cvWaitKey(0)

          If keyPressed = 32 : nFlatten ! #True : EndIf

        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*flatten)
      cvReleaseImage(@*posterize)
      cvReleaseImage(@*hsv)
      cvReleaseImage(@*smooth)
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

OpenCV("images/weight1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\