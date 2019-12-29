IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nRadius, nPower, centerX.f, centerY.f

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Applies the Vignette effect, the process by which there is loss in clarity towards the corners and sides of an image." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust the Radius." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust the Power." + #LF$ +
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
      keybd_event_(#VK_SPACE, 0, 0, 0)
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos)
  keybd_event_(#VK_SPACE, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_SPACE, 0, 0, 0)
EndProcedure

Procedure.d GetDistance(x1, y1, x2, y2)
  ProcedureReturn Sqr(Pow(x1 - x2, 2) + Pow(y1 - y2, 2))
EndProcedure

Procedure.d GetMaxDistanceFromCorners(nWidth, nHeight, nX, nY)
  Dim corners.CvPoint(4)
  corners(0)\x = 0
  corners(0)\y = 0
  corners(1)\x = nWidth
  corners(1)\y = 0
  corners(2)\x = 0
  corners(2)\y = nHeight
  corners(3)\x = nWidth
  corners(3)\y = nHeight

  For rtnCount = 0 To 4 - 1
    nDistance.d = GetDistance(corners(i)\x, corners(i)\y, nX, nY)

    If maxDistance.d < nDistance : maxDistance = nDistance : EndIf

  Next
  ProcedureReturn maxDistance
EndProcedure

Procedure GenerateGradient(*mask.CvMat)
  maxImageRad.d = ((11 - (nRadius + 5)) / 10) * GetMaxDistanceFromCorners(*mask\cols, *mask\rows, *mask\cols / 2, *mask\rows / 2)
  cvSet(*mask, 1, 1, 1, 1, #Null)

  For i = 0 To *mask\rows - 1
    For j = 0 To *mask\cols - 1
      nTemp.d = GetDistance(centerX, centerY, j, i) / maxImageRad
      nTemp * ((nPower + 5) / 10)
      nTemp_s.d = Pow(Cos(nTemp), 4)
      PokeD(@*mask\db\d + i * *mask\Step + j * 8, nTemp_s)
    Next
  Next
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

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      centerX = *resize\width / 2 : centerY = *resize\height / 2
      cvCreateTrackbar("Radius", #CV_WINDOW_NAME, @nRadius, 2, @CvTrackbarCallback1())
      cvCreateTrackbar("Power", #CV_WINDOW_NAME, @nPower, 2, @CvTrackbarCallback2())
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
      cvShowImage(#CV_WINDOW_NAME, *resize)
      cvWaitKey(500)
      *mask.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_64F, 1))
      *lab.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 3))
      *vignette.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 3))
      *param\Pointer1 = *vignette

      Repeat
        If *vignette
          cvCvtColor(*resize, *lab, #CV_BGR2Lab, 1)
          GenerateGradient(*mask)

          For i = 0 To *lab\rows - 1
            For j = 0 To *lab\cols - 1
              PokeA(@*lab\ptr\b + i * *lab\Step + j * 3, PeekA(@*lab\ptr\b + i * *lab\Step + j * 3) * PeekD(@*mask\db\d + i * *mask\Step + j * 8))       
            Next
          Next
          cvCvtColor(*lab, *vignette, #CV_Lab2BGR, 1)
          cvShowImage(#CV_WINDOW_NAME, *vignette)
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
      cvReleaseMat(@*vignette)
      cvReleaseMat(@*lab)
      cvReleaseMat(@*mask)
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

OpenCV("images/style1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\