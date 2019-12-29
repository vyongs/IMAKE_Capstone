IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, ResetTime, centerX.f, centerY.f

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Creates the illusion of water ripples on a background image." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Move the X / Y axis." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Water ripples effect." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset axis to center." + #LF$ + #LF$ +
                  "[ L ] KEY   " + #TAB$ + ": Toggle with / without LUT."

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
    Case #CV_EVENT_LBUTTONDOWN
      ResetTime = #True
      centerX = x
      centerY = y
      keybd_event_(#VK_SPACE, 0, 0, 0)
  EndSelect
EndProcedure

Procedure BlendWaveAndImage(*sourceImage.CvMat, *tarOpenCVImage.CvMat, *waveMap.CvMat)
  rFactor.f = 1.33

  For i = 1 To *sourceImage\rows - 2
    For j = 1 To *sourceImage\cols - 2
      nValue = PeekA(@*waveMap\ptr\b + i * *waveMap\Step + j)
      xDiff.f = PeekA(@*waveMap\ptr\b + (i + 1) * *waveMap\Step + j) - nValue
      yDiff.f = PeekA(@*waveMap\ptr\b + i * *waveMap\Step + j + 1) - nValue
      nAlpha.f = ATan(xDiff)
      nBeta.f = ASin(Sin(nAlpha) / rFactor)
      xDisplace = Round(Tan(nAlpha - nBeta) * nValue, #PB_Round_Nearest)
      nAlpha = ATan(yDiff)
      nBeta = ASin(Sin(nAlpha) / rFactor)
      yDisplace = Round(Tan(nAlpha - nBeta) * nValue, #PB_Round_Nearest)
      dispNi = i + xDisplace
      dispNj = j + yDisplace

      If dispNi > *sourceImage\rows - 1 Or dispNi < 0 : dispNi = i : EndIf
      If dispNj > *sourceImage\cols - 1 Or dispNj < 0 : dispNj = j : EndIf

      IntensityB = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 0)
      IntensityG = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 1)
      IntensityR = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 2)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 0, IntensityB)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 1, IntensityG)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 2, IntensityR)
    Next
  Next
EndProcedure

Procedure BlendWaveAndImageLUT(*sourceImage.CvMat, *tarOpenCVImage.CvMat, *waveMap.CvMat)
  rFactor.f = 1.33 : Dim dispLUT.f(512) : nDispPoint = 512

  For i = 0 To nDispPoint - 1
    nDiff.f = i - 255
    nAlpha.f = ATan(nDiff)
    nBeta.f = ASin(Sin(nAlpha) / rFactor)
    dispLUT(i) =  Tan(nAlpha - nBeta)
  Next

  For i = 1 To *sourceImage\rows - 2
    For j = 1 To *sourceImage\cols - 2
      nValue = PeekA(@*waveMap\ptr\b + i * *waveMap\Step + j)
      xDiff = PeekA(@*waveMap\ptr\b + (i + 1) * *waveMap\Step + j) - nValue
      yDiff = PeekA(@*waveMap\ptr\b + i * *waveMap\Step + j + 1) - nValue
      xDisplace = Round(dispLUT(xDiff + 255) * nValue, #PB_Round_Nearest)
      yDisplace = Round(dispLUT(yDiff + 255) * nValue, #PB_Round_Nearest)
      dispNi = i + xDisplace
      dispNj = j + yDisplace

      If dispNi > *sourceImage\rows - 1 Or dispNi < 0 : dispNi = i : EndIf
      If dispNj > *sourceImage\cols - 1 Or dispNj < 0 : dispNj = j : EndIf

      IntensityB = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 0)
      IntensityG = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 1)
      IntensityR = PeekA(@*sourceImage\ptr\b + dispNi * *sourceImage\Step + dispNj * 3 + 2)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 0, IntensityB)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 1, IntensityG)
      PokeA(@*tarOpenCVImage\ptr\b + i * *tarOpenCVImage\Step + j * 3 + 2, IntensityR)
    Next
  Next
EndProcedure

Procedure.f WaveFunction(nRadius.f, nTime.f, maxImageSize)
  nLength.f = maxImageSize / 8 : twoPI.f = 2 * #PI : nCoefficient.f = 0.5
  ProcedureReturn Exp(-nTime * nCoefficient) * Cos(nTime * twoPI) * Cos(nRadius * twoPI / nLength)
EndProcedure

Procedure.f MakeWaveMap(*image.CvMat)
  simulPeriod.f = 3.5 : Static nTime.f = 0 : nTimeStep.f = 0.20 : poolDepth.f = 20

  If ResetTime : nTime = 0 : ResetTime = #False : EndIf
  If *image\cols > *image\rows : maxImageSize = *image\cols : Else : maxImageSize = *image\rows : EndIf

  For i = 0 To *image\rows - 1
    For j = 0 To *image\cols - 1
      nRadius.f = Sqr((i - centerY) * (i - centerY) + (j - centerX) * (j - centerX))
      z.f = (1 + WaveFunction(nRadius, nTime, maxImageSize)) * poolDepth
      PokeA(@*image\ptr\b + i * *image\Step + j, z)
    Next
  Next
  nTime + nTimeStep
  nTime * Bool(nTime < simulPeriod)
  ProcedureReturn nTime
EndProcedure

Procedure.f MakeWaveMapLUT(*image.CvMat)
  simulPeriod.f = 4 : Static nTime.f = 0 : nTimeStep.f = 0.15 : poolDepth.f = 30

  If ResetTime : nTime = 0 : ResetTime = #False : EndIf
  If *image\cols > *image\rows : nLUT = *image\cols : Else : nLUT = *image\rows : EndIf

  maxImageSize = nLUT
  Dim waveFuncLUT.f(nLUT)

  For i = 0 To nLUT - 1
    nRadius.f = i
    waveFuncLUT(i) = WaveFunction(nRadius, nTime, maxImageSize)
  Next

  For i = 0 To *image\rows - 1
    For j = 0 To *image\cols - 1
      nRadius = Sqr((i - centerY) * (i - centerY) + (j - centerX) * (j - centerX))
      iRad = Round(nRadius, #PB_Round_Nearest)
      nWF.f = waveFuncLUT(iRad % nLUT) + (waveFuncLUT((iRad + 1) % nLUT) - waveFuncLUT(iRad % nLUT)) * (nRadius - iRad)
      PokeA(@*image\ptr\b + i * *image\Step + j, (1 + nWF) * poolDepth)
    Next
  Next
  nTime + nTimeStep
  nTime * Bool(nTime < simulPeriod)
  ProcedureReturn nTime
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
    temp.CvMat : *source.CvMat = cvGetMat(*resize, @temp, #Null, 0)
    *target.CvMat = cvCloneMat(*source)
    *waveMap.CvMat = cvCreateMat(*source\rows, *source\cols, CV_MAKETYPE(#CV_8U, 1))
    cvSetZero(*waveMap) : centerX = *source\cols / 2 : centerY = *source\rows / 2
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *target
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *target
        If keyPressed = 13
          nNoLUT = #False : ResetTime = #True
          centerX = *source\cols / 2 : centerY = *source\rows / 2
          nTime.f = MakeWaveMapLUT(*waveMap)
          BlendWaveAndImageLUT(*source, *target, *waveMap)
          sndPlaySound_("sounds/droplet.wav" + Chr(0), #SND_NODEFAULT + #SND_ASYNC + #SND_FILENAME)
          cvShowImage(#CV_WINDOW_NAME, *target)
          keyPressed = cvWaitKey(10)
        ElseIf keyPressed = 32 Or keyPressed = 76 Or keyPressed = 108 Or nTime > 0
          Select keyPressed
            Case 32 : ResetTime = #True
            Case 76, 108 : nNoLUT ! #True
          EndSelect

          If nNoLUT
            nTime = MakeWaveMap(*waveMap)
            BlendWaveAndImage(*source, *target, *waveMap)
          Else
            nTime = MakeWaveMapLUT(*waveMap)
            BlendWaveAndImageLUT(*source, *target, *waveMap)
          EndIf

          Select keyPressed
            Case 32, 76, 108 : sndPlaySound_("sounds/droplet.wav" + Chr(0), #SND_NODEFAULT + #SND_ASYNC + #SND_FILENAME)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *target)
          keyPressed = cvWaitKey(100)
        Else
          cvShowImage(#CV_WINDOW_NAME, *source)
          keyPressed = cvWaitKey(0)
        EndIf
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseMat(@*waveMap)
    cvReleaseMat(@*target)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If openCV
      openCV = #False
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/enhance2.jpg")
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\