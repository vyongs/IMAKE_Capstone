IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Stippling is the creation of a pattern simulating varying degrees of shading by using small dots." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Start / Stop Stippling." + #LF$ +
                  "ENTER       " + #TAB$ + ": Restart Stippling." + #LF$ + #LF$ +
                  "[ C ] KEY   " + #TAB$ + ": Toggle Color / Black dots." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Toggle static dot size."

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

Procedure.f MapRange(value.f, istart.f, istop.f, ostart.f, ostop.f)
  ProcedureReturn ostart + (ostop - ostart) * ((value - istart) / (istop - istart))
EndProcedure

Structure Particle
  x.f
  y.f
  b.a
  g.a
  r.a
  rad.f
  wt.f
  fx.f
  fy.f
  vx.f
  vy.f
EndStructure

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
    nWidth = *resize\width : nHeight = *resize\height : nChannels = *resize\nChannels
    *stipple.IplImage = cvCreateImage(nWidth, nHeight, #IPL_DEPTH_8U, nChannels)

    nbrParticles      = 8000
    medArea.f         = nWidth * nHeight / nbrParticles
    medRadius.f       = Sqr(medArea / #PI)
    minRadius.f       = medRadius
    maxRadius.f       = medRadius * medRadius
    kRadiusFactor.f   = 0.5
    damping.f         = 0.8
    minDistFactor.f   = 2.5
    kSpeed.f          = 3.0

    Dim particles.Particle(nbrParticles)

    For i = 0 To nbrParticles - 1
      particles(i)\x = Random(2147483647) / 2147483647 * nWidth
      particles(i)\y = Random(2147483647) / 2147483647 * nHeight
      particles(i)\rad = nWidth * kRadiusFactor / Sqr(nbrParticles)
      particles(i)\rad + Random(particles(i)\rad / 2)
    Next
    nStipple = #True : nColor = #True : nSize = #True
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *stipple
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *stipple
        If nStipple
          cvSet(*stipple, 255, 255, 255, 0, #Null)

          For i = 0 To nbrParticles - 2
            px = particles(i)\x
            py = particles(i)\y

            If px >= 0 And px < nWidth And py >= 0 And py < nHeight
              particles(i)\b = PeekA(@*resize\imageData\b + py * *resize\widthStep + px * nChannels + 0)

              If nColor
                particles(i)\g = PeekA(@*resize\imageData\b + py * *resize\widthStep + px * nChannels + 1)
                particles(i)\r = PeekA(@*resize\imageData\b + py * *resize\widthStep + px * nChannels + 2)
              EndIf
              particles(i)\rad = MapRange(particles(i)\b, 0, 255, minRadius, maxRadius)
            EndIf

            For j = i + 1 To nbrParticles - 1
              If Abs(particles(j)\x - particles(i)\x) <= particles(i)\rad * minDistFactor And
                 Abs(particles(j)\y - particles(i)\y) <= particles(i)\rad * minDistFactor
                dx.d = particles(i)\x - particles(j)\x
                dy.d = particles(i)\y - particles(j)\y
                maxDist.d = particles(i)\rad + particles(j)\rad
                distance.d = Sqr(dx * dx + dy * dy)
                diff.d = maxDist - distance

                If diff > 0
                  scle.d = diff / maxDist
                  scle * scle
                  particles(i)\wt + scle
                  particles(j)\wt + scle
                  scle * kSpeed / distance
                  particles(i)\fx + dx * scle
                  particles(i)\fy + dy * scle
                  particles(j)\fx - dx * scle
                  particles(j)\fy - dy * scle
                EndIf
              EndIf
            Next
            maxDist = particles(i)\rad
            distance = particles(i)\x
            dx = particles(i)\x
            dy = 0
            diff = maxDist - distance

            If diff > 0
            	scle = diff / maxDist
            	scle * scle
            	particles(i)\wt + scle
            	scle * kSpeed / distance
              particles(i)\fx + dx * scle
            EndIf
            dx = particles(i)\x - nWidth
            dy = 0
            distance = -dx
            diff = maxDist - distance

            If diff > 0
            	scle = diff / maxDist
            	scle * scle
            	particles(i)\wt + scle
            	scle * kSpeed / distance
              particles(i)\fx + dx * scle
            EndIf
            distance = particles(i)\y
            dy = particles(i)\y
            dx = 0
            diff = maxDist - distance

            If diff > 0
            	scle = diff / maxDist
            	scle * scle
            	particles(i)\wt + scle
            	scle * kSpeed / distance
              particles(i)\fy + dy * scle
            EndIf
            dy = particles(i)\y - nHeight
            dx = 0
            distance = -dy
            diff = maxDist - distance

            If diff > 0
            	scle = diff / maxDist
            	scle * scle
            	particles(i)\wt + scle
            	scle * kSpeed / distance
              particles(i)\fy + dy * scle
            EndIf

            If particles(i)\wt > 0
              particles(i)\vx + particles(i)\fx / particles(i)\wt
              particles(i)\vy + particles(i)\fy / particles(i)\wt
            EndIf
            particles(i)\x + particles(i)\vx
            particles(i)\y + particles(i)\vy
            particles(i)\wt = 0
            particles(i)\fx = 0
            particles(i)\fy = 0
            particles(i)\vx * damping
            particles(i)\vy * damping

            If particles(i)\x > 3 And particles(i)\y > 3 And particles(i)\x < nWidth - 3 And particles(i)\y < nHeight - 3
              If nSize
                Select #True
                  Case Bool(particles(i)\b < 32) : dotSize = 3
                  Case Bool(particles(i)\b < 128) : dotSize = 2
                  Default : dotSize = 1
                EndSelect
              Else
                dotSize = 2
              EndIf

              If nColor
                cvCircle(*stipple, particles(i)\x, particles(i)\y, dotSize, particles(i)\b, particles(i)\g, particles(i)\r, 0, #CV_FILLED, #CV_AA, #Null)
              Else
                cvCircle(*stipple, particles(i)\x, particles(i)\y, dotSize, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
              EndIf
            EndIf
          Next
          cvShowImage(#CV_WINDOW_NAME, *stipple)
          keyPressed = cvWaitKey(1)
        Else
          cvShowImage(#CV_WINDOW_NAME, *stipple)
          keyPressed = cvWaitKey(0)
        EndIf

        Select keyPressed
          Case 13
            nStipple = #True

            For i = 0 To nbrParticles - 1
              particles(i)\x = Random(2147483647) / 2147483647 * nWidth
              particles(i)\y = Random(2147483647) / 2147483647 * nHeight
              particles(i)\rad = nWidth * kRadiusFactor / Sqr(nbrParticles)
              particles(i)\rad + Random(particles(i)\rad / 2)
              particles(i)\vx = 0
              particles(i)\vy = 0
            Next
          Case 32
            nStipple ! #True

            If Not nStipple : cvRectangleR(*stipple, 0, 0, nWidth, nHeight, 0, 100, 0, 0, 20, #CV_AA, #Null) : EndIf

          Case 67, 99
            nStipple = #True
            nColor ! #True
          Case 83, 115
            nStipple = #True
            nSize ! #True
        EndSelect
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*stipple)
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

OpenCV("images/weight4.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\