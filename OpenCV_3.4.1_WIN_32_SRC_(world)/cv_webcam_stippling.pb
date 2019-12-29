IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Stippling is the creation of a pattern simulating varying degrees of shading by using small dots." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Stippling / Webcam." + #LF$ +
                  "ENTER       " + #TAB$ + ": Restart Stippling." + #LF$ + #LF$ +
                  "[ C ] KEY   " + #TAB$ + ": Toggle Color / Black dots."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
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

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
Until nCreate = 99 Or *capture

If *capture
  cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
  window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
  *window_name = cvGetWindowName(window_handle)
  lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

  If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
    MenuItem(10, "Exit")
  EndIf
  hWnd = GetParent_(window_handle)
  iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
  SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
  wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
  SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)

  If FrameWidth > 640
    nRatio.d = 640 / FrameWidth
    FrameWidth * nRatio : FrameHeight * nRatio
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH, FrameWidth)
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight)
  EndIf
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  *stipple.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)

  nbrParticles      = 5000
  medArea.f         = FrameWidth * FrameHeight / nbrParticles
  medRadius.f       = Sqr(medArea / #PI)
  minRadius.f       = medRadius
  maxRadius.f       = medRadius * medRadius
  kRadiusFactor.f   = 0.5
  damping.f         = 0.8
  minDistFactor.f   = 2.5
  kSpeed.f          = 3.0

  Dim particles.Particle(nbrParticles)

  For i = 0 To nbrParticles - 1
    particles(i)\x = Random(2147483647) / 2147483647 * FrameWidth
    particles(i)\y = Random(2147483647) / 2147483647 * FrameHeight
    particles(i)\rad = FrameWidth * kRadiusFactor / Sqr(nbrParticles)
    particles(i)\rad + Random(particles(i)\rad / 2)
  Next
  *image.IplImage : nStipple = #True : nColor = #True
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If nStipple
        cvSet(*stipple, 255, 255, 255, 0, #Null)

        For i = 0 To nbrParticles - 2
          px = particles(i)\x
          py = particles(i)\y

          If px >= 0 And px < FrameWidth And py >= 0 And py < FrameHeight
            particles(i)\b = PeekA(@*image\imageData\b + py * *image\widthStep + px * 3 + 0)

            If nColor
              particles(i)\g = PeekA(@*image\imageData\b + py * *image\widthStep + px * 3 + 1)
              particles(i)\r = PeekA(@*image\imageData\b + py * *image\widthStep + px * 3 + 2)
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
          dx = particles(i)\x - FrameWidth
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
          dy = particles(i)\y - FrameHeight
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

          If particles(i)\x > 0 And particles(i)\y > 0 And particles(i)\x < FrameWidth And particles(i)\y < FrameHeight
            If nColor
              cvCircle(*stipple, particles(i)\x, particles(i)\y, 3, particles(i)\b, particles(i)\g, particles(i)\r, 0, #CV_FILLED, #CV_AA, #Null)
            Else
              cvCircle(*stipple, particles(i)\x, particles(i)\y, 3, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
            EndIf
          EndIf
        Next
        cvShowImage(#CV_WINDOW_NAME, *stipple)
      Else
        cvShowImage(#CV_WINDOW_NAME, *image)
      EndIf
      keyPressed = cvWaitKey(1)

      Select keyPressed
        Case 13
          If nStipple
            For i = 0 To nbrParticles - 1
              particles(i)\x = Random(2147483647) / 2147483647 * FrameWidth
              particles(i)\y = Random(2147483647) / 2147483647 * FrameHeight
              particles(i)\rad = FrameWidth * kRadiusFactor / Sqr(nbrParticles)
              particles(i)\rad + Random(particles(i)\rad / 2)
              particles(i)\vx = 0
              particles(i)\vy = 0
            Next
          EndIf
        Case 32
          nStipple ! #True
        Case 67, 99
          If nStipple : nColor ! #True : EndIf
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*stipple)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\