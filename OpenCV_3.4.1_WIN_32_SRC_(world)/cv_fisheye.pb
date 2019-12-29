IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nDistortion.f, centerX.f, centerY.f

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Standard fisheye lens effect derived from mathematical equations." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust the distortion." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Move the X / Y axis." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset axis to center."

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
    Case #CV_EVENT_LBUTTONUP
      centerX = x
      centerY = y
      keybd_event_(#VK_Z, 0, 0, 0)
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback(pos)
  Select pos
    Case 0
      nDistortion = 0.0001
    Case 1
      nDistortion = 0.001
    Case 2
      nDistortion = 0.01
    Case 3
      nDistortion = 0.1
  EndSelect
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

Global thresh.f = 1

Procedure.f CalcShift(x1.f, x2.f, cx.f, dist.f)
  x3.f = x1 + (x2 - x1) * 0.5
  res1.f = x1 + ((x1 - cx) * dist * ((x1 - cx) * (x1 - cx)))
  res3.f = x3 + ((x3 - cx) * dist * ((x3 - cx) * (x3 - cx)))

  If res1 > -thresh And res1 < thresh : ProcedureReturn x1 : EndIf
  If res3 < 0 : ProcedureReturn CalcShift(x3, x2, cx, dist) : Else : ProcedureReturn CalcShift(x1, x3, cx, dist) : EndIf

EndProcedure

Global xScale.f, yScale.f, xShift.f, yShift.f

Procedure.f GetRadialX(x.f, y.f, cx.f, cy.f, dist.f)
  x * xScale + xShift
  y * yScale + yShift
  res.f = x + ((x - cx) * dist * ((x - cx) * (x - cx) + (y - cy) * (y - cy)))
  ProcedureReturn res
EndProcedure

Procedure.f GetRadialY(x.f, y.f, cx.f, cy.f, dist.f)
  x * xScale + xShift
  y * yScale + yShift
  res.f = y + ((y - cy) * dist * ((x - cx) * (x - cx) + (y - cy) * (y - cy)))
  ProcedureReturn res
EndProcedure

Procedure GetScalar(*image.IplImage, idx0.f, idx1.f, *res.CvScalar)
  If idx0 < 0 Or idx1 < 0 Or idx0 > *image\height-1 Or idx1 > *image\width - 1
    *res\val[0] = 0
    *res\val[1] = 0
    *res\val[2] = 0
    *res\val[3] = 0
  Else
    idx0_floor.f = cvFloor(idx0)
    idx0_ceil.f = cvCeil(idx0)
    idx1_floor.f = cvFloor(idx1)
    idx1_ceil.f = cvCeil(idx1)
    s1.CvScalar
    s2.CvScalar
    s3.CvScalar
    s4.CvScalar
    cvGet2D(@s1, *image, idx0_floor, idx1_floor)
    cvGet2D(@s2, *image, idx0_floor, idx1_ceil)
    cvGet2D(@s3, *image, idx0_ceil, idx1_ceil)
    cvGet2D(@s4, *image, idx0_ceil, idx1_floor)
    x.f = idx0 - idx0_floor
    y.f = idx1 - idx1_floor
    *res\val[0] = s1\val[0] * (1 - x) * (1 - y) + s2\val[0] * (1 - x) * y + s3\val[0] * x * y + s4\val[0] * x * (1 - y)
    *res\val[1] = s1\val[1] * (1 - x) * (1 - y) + s2\val[1] * (1 - x) * y + s3\val[1] * x * y + s4\val[1] * x * (1 - y)
    *res\val[2] = s1\val[2] * (1 - x) * (1 - y) + s2\val[2] * (1 - x) * y + s3\val[2] * x * y + s4\val[2] * x * (1 - y)
    *res\val[3] = s1\val[3] * (1 - x) * (1 - y) + s2\val[3] * (1 - x) * y + s3\val[3] * x * y + s4\val[3] * x * (1 - y)
  EndIf
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

    If *resize\width > 200 And *resize\height > 200
      nDistortion = 0.0001
      centerX = *resize\width / 2
      centerY = *resize\height / 2
      cvCreateTrackbar("Distortion", #CV_WINDOW_NAME, 0, 3, @CvTrackbarCallback())
      cvShowImage(#CV_WINDOW_NAME, *resize)
      cvWaitKey(500)
      *fisheye.IplImage = cvCreateImage(*resize\width, *resize\height, *resize\depth, *resize\nChannels)
      scalar.CvScalar
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *fisheye
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *fisheye
          xShift = CalcShift(0, centerX - 1, centerX, nDistortion)
          newCenterX.f = *resize\width - centerX
          xShift_2.f = CalcShift(0, newCenterX - 1, newCenterX, nDistortion)
          yShift = CalcShift(0, centerY - 1, centerY, nDistortion)
          newCenterY.f = *resize\height - centerY
          yShift_2.f = CalcShift(0, newCenterY - 1, newCenterY, nDistortion)
          xScale = (*resize\width - xShift - xShift_2) / *resize\width
          yScale = (*resize\height - yShift - yShift_2) / *resize\height

          For j = 0 To *fisheye\height - 1
            For i = 0 To *fisheye\width - 1
              x.f = GetRadialX(i, j, centerX, centerY, nDistortion)
              y.f = GetRadialY(i, j, centerX, centerY, nDistortion)
              GetScalar(*resize, y, x, @scalar)
              cvSet2D(*fisheye, j, i, scalar\val[0], scalar\val[1], scalar\val[2], scalar\val[3])
            Next
          Next
          cvShowImage(#CV_WINDOW_NAME, *fisheye)
          keyPressed = cvWaitKey(0)

          If keyPressed = 13
            centerX = *resize\width / 2
            centerY = *resize\height / 2
            cvShowImage(#CV_WINDOW_NAME, *resize)
            cvWaitKey(500)
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*fisheye)
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

OpenCV("images/lena.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\