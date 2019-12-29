IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Apply a painted effect to an image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle painted image." + #LF$ + #LF$ +
                  "[ D ] KEY   " + #TAB$ + ": Delete Color Pallet." + #LF$ +
                  "[ L ] KEY   " + #TAB$ + ": Load Color Pallet." + #LF$ +
                  "[ R ] KEY   " + #TAB$ + ": Reset Color Pallet." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Save Color Pallet."

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

Structure PixelColor
  b.a
  g.a
  r.a
EndStructure

Structure ColorPallet
	count.i
	threshold.i
	color.PixelColor[512]
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

	ProcedureReturn nDiff
EndProcedure

Procedure DiffPixel(*src.IplImage, x, y)
  Define.PixelColor *color, *colorRight, *colorBelow

  If x < 0 Or x >= *src\width - 1 Or y < 0 Or y >= *src\height - 1: ProcedureReturn 0 : EndIf

  *color = PixelSurvey(*src, x, y)
  *colorRight = PixelSurvey(*src, x + 1, y)
  *colorBelow = PixelSurvey(*src, x, y + 1)
  nDiffH = CompareColor(*color, *colorRight)
  nDiffV = CompareColor(*color, *colorBelow)

  If nDiffH > nDiffV : ProcedureReturn nDiffH : Else : ProcedureReturn nDiffV : EndIf

EndProcedure

Procedure GetPointMode(*src.IplImage, x, y, nValue1, nValue2)
  nDiff1 = DiffPixel(*src, x, y)
	nDiff2 = DiffPixel(*src, x + 1, y + 1)

	If nDiff1 < nValue1 : nPointMode = 0 : ElseIf nDiff1 > nValue2 : nPointMode = 1 : Else : nPointMode = 2 : EndIf

	ProcedureReturn nPointMode
EndProcedure

Procedure LoadPallet(*pallet.ColorPallet, PalletFile.s)
  If LoadJSON(0, PalletFile)
    ExtractJSONStructure(JSONValue(0), *pallet, ColorPallet)
    FreeJSON(0)
  EndIf
EndProcedure

Procedure SavePallet(*pallet.ColorPallet, PalletFile.s)
  If CreateJSON(0)
    InsertJSONStructure(JSONValue(0), *pallet, ColorPallet)
    SaveJSON(0, PalletFile)
    FreeJSON(0)
  EndIf
EndProcedure

Procedure ScanPallet(*pallet.ColorPallet, *color.PixelColor)
  For i = 0 To *pallet\count - 1
    nDiff = CompareColor(*color, *pallet\color[i])

    If nDiff < *pallet\threshold : PalletValue = #True : Break : EndIf

  Next

  If PalletValue : ProcedureReturn *pallet\color[i] : Else : ProcedureReturn *color : EndIf

EndProcedure

Procedure AddPallet(*pallet.ColorPallet, *color.PixelColor)
  nCount = *pallet\count

  If nCount < 512
		For i = 0 To nCount - 1
		  nDiff = CompareColor(*color, *pallet\color[i])

		  If nDiff < *pallet\threshold : AlreadyAdded = #True : Break : EndIf

		Next

		If Not AlreadyAdded
  		*pallet\color[nCount]\b = *color\b
		  *pallet\color[nCount]\g = *color\g
		  *pallet\color[nCount]\r = *color\r
  		*pallet\count + 1
  	EndIf
	EndIf
EndProcedure

Procedure MakePallet(*src.IplImage, *pallet.ColorPallet)
  *color.PixelColor

  For y = 0 To *src\height - 1
		For x = 0 To *src\width - 1
			*color = PixelSurvey(*src, x, y)
			AddPallet(*pallet, *color)
		Next
	Next
EndProcedure

Procedure Color2Gray(*color.PixelColor)
  ProcedureReturn *color\r * 0.299 + *color\g * 0.587 + *color\b * 0.114
EndProcedure

Procedure PaintImage(*src.IplImage, *dst.IplImage, *pallet.ColorPallet, nValue1, nValue2, nValue3)
  Define.PixelColor *black, *color
  *black = AllocateMemory(SizeOf(PixelColor))
  *black\b = 64 : *black\g = 64 : *black\r = 64

  For y = 0 To *src\height - 1
    For x = 0 To *src\width - 1
      *color = PixelSurvey(*src, x, y)
      nMode = GetPointMode(*src, x, y, nValue1, nValue2)

      If nMode = 1 Or Color2Gray(*color) < nValue3 : PixelDraw(*dst, x, y, *black) : Else : PixelDraw(*dst, x, y, ScanPallet(*pallet, *color)) : EndIf

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
      *smooth.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *painted.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *pallet.ColorPallet = AllocateMemory(SizeOf(ColorPallet))
      cvSmooth(*resize, *smooth, #CV_BILATERAL, 12, 12, 96, 128)
      PalletFile.s = #PB_Compiler_FilePath + "binaries\other\" + GetFilePart(ImageFile, #PB_FileSystem_NoExtension) + ".pallet"

      If FileSize(PalletFile) > 0
        LoadPallet(*pallet, PalletFile)
      Else
        *pallet\threshold = 12
        MakePallet(*smooth, *pallet)
      EndIf
      nValue1 = 8 : nValue2 = 12 : nValue3 = 96
      PaintImage(*smooth, *painted, *pallet, nValue1, nValue2, nValue3)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *painted
          If nOriginal
            cvShowImage(#CV_WINDOW_NAME, *resize)
            *param\Pointer1 = *resize
          Else
            cvShowImage(#CV_WINDOW_NAME, *painted)
            *param\Pointer1 = *painted
          EndIf
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              nOriginal ! #True
            Case 68, 100
              If FileSize(PalletFile) > 0
                nMessage = MessageRequester(#CV_WINDOW_NAME, "Delete saved Color Pallet file for this image?", #PB_MessageRequester_YesNo | #MB_ICONQUESTION)

                If nMessage = #PB_MessageRequester_Yes : DeleteFile(PalletFile) : EndIf

              EndIf
            Case 76, 108
              Filename.s = OpenFileRequester("Load Color Pallet", PalletFile, "Color Pallet (*.pallet)|*.pallet", 0)

              If FileSize(Filename) > 0
                LoadPallet(*pallet, Filename)
                PaintImage(*smooth, *painted, *pallet, nValue1, nValue2, nValue3)
              EndIf
            Case 82, 114
              ClearStructure(*pallet, ColorPallet)
              *pallet\threshold = 12
              MakePallet(*smooth, *pallet)
              PaintImage(*smooth, *painted, *pallet, nValue1, nValue2, nValue3)
            Case 83, 115
              SavePallet(*pallet, PalletFile)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      FreeMemory(*pallet)
      cvReleaseImage(@*painted)
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
      MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the channel requirements, please try another image.", #MB_ICONERROR)
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
; Folding = --
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\