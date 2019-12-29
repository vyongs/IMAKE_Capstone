IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, hWnd_control, nVariance, nPulsation, nPhase, nPSI

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Gabor Filter: A linear filter used for edge detection." + #LF$ + #LF$ +
                  "CONTROLS    " + #TAB$ + ": Adjust settings." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset controls."

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
      SendMessage_(hWnd_control, #WM_CLOSE, 0, 0)
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
  keybd_event_(#VK_SPACE, 0, 0, 0)
EndProcedure

Procedure GaborFilter(*kernel.CvMat, *source32.IplImage, *gabor32.IplImage, nKernel)
  kernel_size = (nKernel - 1) / 2
  variance.f = nVariance / 10
  pulsation.f = nPulsation / 10
  phase.f = nPhase * #PI / 180
  PSI.f = nPSI * #PI / 180
  cvSetZero(*kernel)

  For y = -kernel_size To kernel_size
    For x = -kernel_size To kernel_size
      nValue.f = Exp(-((x * x) + (y * y)) / (2 * variance)) * Cos(pulsation * x * Cos(phase) + pulsation * y * Sin(phase) + PSI)
      cvSet2D(*kernel, y + kernel_size, x + kernel_size, nValue, nValue, nValue, 0)
    Next
  Next
  cvFilter2D(*source32, *gabor32, *kernel, -1, -1)
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

    If *image\width + 500 >= dtWidth - 100 Or *image\height >= dtHeight - 100
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / (*image\width + 500)
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

    If *resize\width > 200 And *resize\height > 200
      cvNamedWindow(#CV_WINDOW_NAME + " - Gabor Filter", #CV_WINDOW_AUTOSIZE)
      hWnd_control = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Gabor Filter"))
      SendMessage_(hWnd_control, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_control, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_control, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - Gabor Filter", 350, 180)
      cvMoveWindow(#CV_WINDOW_NAME + " - Gabor Filter", *resize\width + 50, 20)
      nKernel = 21 : nVariance = 8 : nPulsation = 10 : nPhase = 75 : nPSI = 85

      If Not nKernel % 2 : nKernel + 1 : EndIf

      cvCreateTrackbar("Variance", #CV_WINDOW_NAME + " - Gabor Filter", @nVariance, 100, @CvTrackbarCallback())
      cvCreateTrackbar("Pulsation", #CV_WINDOW_NAME + " - Gabor Filter", @nPulsation, 30, @CvTrackbarCallback())
      cvCreateTrackbar("Phase", #CV_WINDOW_NAME + " - Gabor Filter", @nPhase, 180, @CvTrackbarCallback())
      cvCreateTrackbar("PSI", #CV_WINDOW_NAME + " - Gabor Filter", @nPSI, 360, @CvTrackbarCallback())
      *source.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *source32.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
      *kernel.CvMat = cvCreateMat(nKernel, nKernel, CV_MAKETYPE(#CV_32F, 1))

      If *resize\nChannels = 3 : cvCvtColor(*resize, *source, #CV_BGR2GRAY, 1) : Else : *source = cvCloneImage(*resize) : EndIf

      cvConvertScale(*source, *source32, 1 / 255, 0)
      *gabor32.IplImage = cvCloneImage(*source32)
      *gabor.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      GaborFilter(*kernel, *source32, *gabor32, nKernel)
      cvConvertScale(*gabor32, *gabor, 255, 0)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *gabor
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *gabor
          cvShowImage(#CV_WINDOW_NAME, *gabor)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              cvSetTrackbarPos("Variance", #CV_WINDOW_NAME + " - Gabor Filter", 8)
              cvSetTrackbarPos("Pulsation", #CV_WINDOW_NAME + " - Gabor Filter", 10)
              cvSetTrackbarPos("Phase", #CV_WINDOW_NAME + " - Gabor Filter", 75)
              cvSetTrackbarPos("PSI", #CV_WINDOW_NAME + " - Gabor Filter", 85)
              GaborFilter(*kernel, *source32, *gabor32, nKernel)
              cvConvertScale(*gabor32, *gabor, 255, 0)
            Case 32
              GaborFilter(*kernel, *source32, *gabor32, nKernel)
              cvConvertScale(*gabor32, *gabor, 255, 0)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*gabor)
      cvReleaseImage(@*gabor32)
      cvReleaseMat(@*kernel)
      cvReleaseImage(@*source32)
      cvReleaseImage(@*source)
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

OpenCV("images/sketch1.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\