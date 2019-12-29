IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Each particle tries to find an optimum placement by pushing itself away from its neighbors." + #LF$ + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset Repulsion Field."

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

Structure Particle
  x.f
  y.f
  size.a
  b.a
  g.a
  r.a
  radius.f
  wt.f
  fx.f
  fy.f
  vx.f
  vy.f
EndStructure

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
nWidth = 1000 : nHeight = 600
*image.IplImage = cvCreateImage(nWidth, nHeight, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, nWidth, nHeight)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)

nbrParticles      = 500
kRadiusFactor.f   = 0.5
damping.f         = 0.8
minDistFactor.f   = 2.0
kSpeed.f          = 3.0

Dim particles.Particle(nbrParticles)

For i = 0 To nbrParticles - 1
  particles(i)\x = Random(nWidth / 2 + 50, nWidth / 2 - 50)
  particles(i)\y = Random(nHeight / 2 + 25, nHeight / 2 - 25)
  particles(i)\size = Random(15, 3)
  particles(i)\b = Random(255)
  particles(i)\g = Random(255)
  particles(i)\r = Random(255)
  particles(i)\radius = nWidth * kRadiusFactor / Sqr(nbrParticles)
  particles(i)\radius + Random(particles(i)\radius / 2)
Next
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)
cvSet(*image, 255, 255, 255, 0, #Null) : cvShowImage(#CV_WINDOW_NAME, *image) : cvWaitKey(500)

Repeat
  If *image
    cvSet(*image, 255, 255, 255, 0, #Null)

    For i = 0 To nbrParticles - 2
      For j = i + 1 To nbrParticles - 1
        If Abs(particles(j)\x - particles(i)\x) <= particles(i)\radius * minDistFactor And
           Abs(particles(j)\y - particles(i)\y) <= particles(i)\radius * minDistFactor
          dx.d = particles(i)\x - particles(j)\x
          dy.d = particles(i)\y - particles(j)\y
          maxDist.d = particles(i)\radius + particles(j)\radius
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
      maxDist = particles(i)\radius
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

      If particles(i)\x < nWidth And particles(i)\y < nHeight
        cvCircle(*image, particles(i)\x, particles(i)\y, particles(i)\size, particles(i)\b, particles(i)\g, particles(i)\r, 0, #CV_FILLED, #CV_AA, #Null)
      EndIf
    Next
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(1)

    Select keyPressed
      Case 13
        For i = 0 To nbrParticles - 1
          particles(i)\x = Random(nWidth / 2 + 100, nWidth / 2 - 100)
          particles(i)\y = Random(nHeight / 2 + 50, nHeight / 2 - 50)
          particles(i)\size = Random(15, 3)
          particles(i)\b = Random(255)
          particles(i)\g = Random(255)
          particles(i)\r = Random(255)
          particles(i)\radius = nWidth * kRadiusFactor / Sqr(nbrParticles)
          particles(i)\radius + Random(particles(i)\radius / 2)
          particles(i)\vx = 0
          particles(i)\vy = 0
        Next
    EndSelect
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\