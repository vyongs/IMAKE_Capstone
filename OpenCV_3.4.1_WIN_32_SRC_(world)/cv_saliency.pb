IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "A fine-grained saliency algorithm is applied to an image: The distinct subjective perceptual quality which makes " +
                  "some objects stand out from their neighbors." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

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

Procedure ImageCopy(*srcArg.IplImage, *dstArg.IplImage)
  If *dstArg\nChannels = 1
    For y = 0 To *dstArg\height - 1
      For x = 0 To *dstArg\width - 1
        PokeA(@*dstArg\imageData\b + (y * *dstArg\widthStep) + x, PeekA(@*srcArg\imageData\b + (y * *srcArg\widthStep) + x))
      Next
    Next
  Else
    For y = 0 To *dstArg\height - 1
      For x = 0 To *dstArg\width - 1
        PokeA(@*dstArg\imageData\b + (y * *dstArg\widthStep) + x * 3 + 0, PeekA(@*srcArg\imageData\b + (y * *srcArg\widthStep) + x * 3 + 0))
        PokeA(@*dstArg\imageData\b + (y * *dstArg\widthStep) + x * 3 + 1, PeekA(@*srcArg\imageData\b + (y * *srcArg\widthStep) + x * 3 + 1))
        PokeA(@*dstArg\imageData\b + (y * *dstArg\widthStep) + x * 3 + 2, PeekA(@*srcArg\imageData\b + (y * *srcArg\widthStep) + x * 3 + 2))
      Next
    Next
  EndIf
EndProcedure

Procedure.f GetMean(*srcArg.IplImage, x, y, neighbourhood, centerVal)
  x1 = x - neighbourhood + 1
  y1 = y - neighbourhood + 1
  x2 = x + neighbourhood + 1
  y2 = y + neighbourhood + 1

  If x1 < 0 : x1 = 0 : ElseIf x1 > *srcArg\width - 1 : x1 = *srcArg\width - 1 : EndIf
  If x2 < 0 : x2 = 0 : ElseIf x2 > *srcArg\width - 1 : x2 = *srcArg\width - 1 : EndIf
  If y1 < 0 : y1 = 0 : ElseIf y1 > *srcArg\height - 1 : y1 = *srcArg\height - 1 : EndIf
  If y2 < 0 : y2 = 0 : ElseIf y2 > *srcArg\height - 1 : y2 = *srcArg\height - 1 : EndIf

  value.f = PeekL(@*srcArg\imageData\b + (*srcArg\widthStep * y2) + x2 * 4) + PeekL(@*srcArg\imageData\b + (*srcArg\widthStep * y1) + x1 * 4) - PeekL(@*srcArg\imageData\b + (*srcArg\widthStep * y2) + x1 * 4) - PeekL(@*srcArg\imageData\b + (*srcArg\widthStep * y1) + x2 * 4)
  value = (value - centerVal) / ((x2 - x1) * (y2 - y1) - 1)
  ProcedureReturn value
EndProcedure

Procedure GetIntensityScaled(*integralImage.IplImage, *gray.IplImage, *intensityScaledOn.IplImage, *intensityScaledOff.IplImage, neighborhood)
  cvSetZero(*intensityScaledOn)
  cvSetZero(*intensityScaledOff)

  For y = 0 To *gray\height - 1
    For x = 0 To *gray\width - 1
      value.f = GetMean(*integralImage, x, y, neighborhood, PeekA(@*gray\imageData\b + (*gray\widthStep * y) + x))
      meanOn.f = PeekA(@*gray\imageData\b + (*gray\widthStep * y) + x) - value
      meanOff.f = value - PeekA(@*gray\imageData\b + (*gray\widthStep * y) + x)

      If meanOn > 0
        PokeA(@*intensityScaledOn\imageData\b + (*intensityScaledOn\widthStep * y) + x, meanOn)
      Else
        PokeA(@*intensityScaledOn\imageData\b + (*intensityScaledOn\widthStep * y) + x, 0)
      EndIf

      If meanOff > 0
        PokeA(@*intensityScaledOff\imageData\b + (*intensityScaledOff\widthStep * y) + x, meanOff)
      Else
        PokeA(@*intensityScaledOff\imageData\b + (*intensityScaledOff\widthStep * y) + x, 0)
      EndIf
    Next
  Next
EndProcedure

Procedure MixScales(Array *intensityScaledOn.IplImage(1), *intensityOn.IplImage, Array *intensityScaledOff.IplImage(1), *intensityOff.IplImage, numScales)
  width = *intensityScaledOn(0)\width
  height = *intensityScaledOn(0)\height
	*mixedValuesOn.IplImage = cvCreateImage(width, height, #IPL_DEPTH_16U, 1)
	*mixedValuesOff.IplImage = cvCreateImage(width, height, #IPL_DEPTH_16U, 1)
	cvSetZero(*mixedValuesOn)
	cvSetZero(*mixedValuesOff)

	For i = 0 To numScales - 1
	  For y = 0 To height - 1
	    For x = 0 To width - 1
	      currValOn = PeekA(@*intensityScaledOn(i)\imageData\b + (*intensityScaledOn(i)\widthStep * y) + x)

			  If currValOn > maxValOn : maxValOn = currValOn : EndIf

			  currValOff = PeekA(@*intensityScaledOff(i)\imageData\b + (*intensityScaledOff(i)\widthStep * y) + x)

			  If currValOff > maxValOff : maxValOff = currValOff : EndIf

			  PokeA(@*mixedValuesOn\imageData\b + (*mixedValuesOn\widthStep * y) + x, currValOn)
			  PokeA(@*mixedValuesOff\imageData\b + (*mixedValuesOff\widthStep * y) + x, currValOff)
	    Next
	  Next
	Next

	For y = 0 To height - 1
	  For x = 0 To width - 1
	    currValOn = PeekA(@*mixedValuesOn\imageData\b + (*mixedValuesOn\widthStep * y) + x)
	    currValOff = PeekA(@*mixedValuesOff\imageData\b + (*mixedValuesOff\widthStep * y) + x)

	    If currValOn > maxValSumOn : maxValSumOn = currValOn : EndIf
		  If currValOff > maxValSumOff : maxValSumOff = currValOff : EndIf

	  Next
	Next

	For y = 0 To height - 1
	  For x = 0 To width - 1
	    PokeA(@*intensityOn\imageData\b + (*intensityOn\widthStep * y) + x, 255 * PeekA(@*mixedValuesOn\imageData\b + (*mixedValuesOn\widthStep * y) + x) / maxValSumOn)
			PokeA(@*intensityOff\imageData\b + (*intensityOff\widthStep * y) + x, 255 * PeekA(@*mixedValuesOff\imageData\b + (*mixedValuesOff\widthStep * y) + x) / maxValSumOff)
	  Next
	Next
	cvReleaseImage(@*mixedValuesOff)
	cvReleaseImage(@*mixedValuesOn)
EndProcedure

Procedure MixOnOff(*intensityOn.IplImage, *intensityOff.IplImage, *intensityArg.IplImage)
  width = *intensityOn\width
  height = *intensityOn\height
  *intensity.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)

  For y = 0 To height - 1
    For x = 0 To width - 1
      currValOn = PeekA(@*intensityOn\imageData\b + (*intensityOn\widthStep * y) + x)
      currValOff = PeekA(@*intensityOff\imageData\b + (*intensityOff\widthStep * y) + x)

		  If currValOff > maxValSumOff : maxValSumOff = currValOff : EndIf
		  If currValOn > maxValSumOn : maxValSumOn = currValOn : EndIf

    Next
  Next

  If maxValSumOn > maxValSumOff : maxVal = maxValSumOn : Else : maxVal = maxValSumOff : EndIf

  For y = 0 To height - 1
    For x = 0 To width - 1
      PokeA(@*intensity\imageData\b + (*intensity\widthStep * y) + x, 255 * (PeekA(@*intensityOn\imageData\b + (*intensityOn\widthStep * y) + x) + PeekA(@*intensityOff\imageData\b + (*intensityOff\widthStep * y) + x)) / maxVal)
    Next
  Next
  ImageCopy(*intensity, *intensityArg)
  cvReleaseImage(@*intensity)
EndProcedure

Procedure CalcIntensityChannel(*srcArg.IplImage, *dstArg.IplImage)
  numScales = 6
  Dim neighborhoods(6)
  neighborhoods(0) = 3 * 4
  neighborhoods(1) = 3 * 4 * 2
  neighborhoods(2) = 3 * 4 * 2 * 2
  neighborhoods(3) = 7 * 4
  neighborhoods(4) = 7 * 4 * 2
  neighborhoods(5) = 7 * 4 * 2 * 2
  *gray.IplImage = cvCreateImage(*srcArg\width, *srcArg\height, #IPL_DEPTH_8U, 1)
  *integralImage.IplImage = cvCreateImage(*gray\width + 1, *gray\height + 1, #IPL_DEPTH_32S, 1)
  *intensity.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 1)
  *intensityOn.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 1)
  *intensityOff.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 1)
  Dim *intensityScaledOn.IplImage(numScales)
  Dim *intensityScaledOff.IplImage(numScales)

	For i = 0 To numScales - 1
    *intensityScaledOn(i) = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 1)
		*intensityScaledOff(i) = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 1)
	Next

	If *srcArg\nChannels = 1 : ImageCopy(*srcArg, *gray) : Else : cvCvtColor(*srcArg, *gray, #CV_BGR2GRAY, 1) : EndIf

	cvSmooth(*gray, *gray, #CV_GAUSSIAN, 3, 3, 0, 0)
	cvSmooth(*gray, *gray, #CV_GAUSSIAN, 3, 3, 0, 0)
	cvIntegral(*gray, *integralImage, #Null, #Null)

	For i = 0 To numScales - 1
    neighborhood = neighborhoods(i)
    GetIntensityScaled(*integralImage, *gray, *intensityScaledOn(i), *intensityScaledOff(i), neighborhood)
  Next
  MixScales(*intensityScaledOn(), *intensityOn, *intensityScaledOff(), *intensityOff, numScales)
  MixOnOff(*intensityOn, *intensityOff, *intensity)
  ImageCopy(*intensity, *dstArg)

  For i = 0 To numScales - 1
    cvReleaseImage(@*intensityScaledOff(i))
  	cvReleaseImage(@*intensityScaledOn(i))
  Next
  cvReleaseImage(@*intensityOff)
  cvReleaseImage(@*intensityOn)
  cvReleaseImage(@*intensity)
  cvReleaseImage(@*integralImage)
  cvReleaseImage(@*gray)
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

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      *saliency.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      CalcIntensityChannel(*resize, *saliency)
      *color.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      cvCvtColor(*saliency, *color, #CV_GRAY2BGR, 1)
      *reset.IplImage = cvCloneImage(*color)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *color
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *color
          Select PIP
            Case 0
              cvSetImageROI(*color, 20, 20, iWidth, iHeight)
              cvAndS(*color, 0, 0, 0, 0, *color, #Null)
              cvAdd(*color, *PIP, *color, #Null)
              cvResetImageROI(*color)
              cvRectangleR(*color, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*color, *color\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*color, 0, 0, 0, 0, *color, #Null)
              cvAdd(*color, *PIP, *color, #Null)
              cvResetImageROI(*color)
              cvRectangleR(*color, *color\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *color)
          keyPressed = cvWaitKey(0)

          If keyPressed = 86 Or keyPressed = 118
            PIP = (PIP + 1) % 3
            cvReleaseImage(@*color)
            *color = cvCloneImage(*reset)
            *param\Pointer1 = *color
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*color)
      cvReleaseImage(@*saliency)
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

OpenCV("images/flower.png")
; IDE Options = PureBasic 5.31 (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\