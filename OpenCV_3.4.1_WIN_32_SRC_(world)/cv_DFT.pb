IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, hWnd_dft

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Performs a discrete Fourier transform of a 1D floating-point array, displaying its power spectrum." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
      SendMessage_(hWnd_dft, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://www.thefouriertransform.com/")
  EndSelect
EndProcedure

Procedure CvShiftDFT(*source.IplImage, *destination.IplImage)
  q1stub.CvMat : q2stub.CvMat : q3stub.CvMat : q4stub.CvMat
  d1stub.CvMat : d2stub.CvMat : d3stub.CvMat : d4stub.CvMat
  cx = *source\width / 2
  cy = *source\height / 2
  *q1.CvMat = cvGetSubRect(*source, @q1stub, 0, 0, cx, cy)
  *q2.CvMat = cvGetSubRect(*source, @q2stub, cx, 0, cx, cy)
  *q3.CvMat = cvGetSubRect(*source, @q3stub, cx, cy, cx, cy)
  *q4.CvMat = cvGetSubRect(*source, @q4stub, 0, cy, cx, cy)
  *d1.CvMat = cvGetSubRect(*source, @d1stub, 0, 0, cx, cy)
  *d2.CvMat = cvGetSubRect(*source, @d2stub, cx, 0, cx, cy)
  *d3.CvMat = cvGetSubRect(*source, @d3stub, cx, cy, cx, cy)
  *d4.CvMat = cvGetSubRect(*source, @d4stub, 0, cy, cx, cy)

  If *source = *destination
    *temp.CvMat = cvCreateMat(cy, cx, cvGetElemType(*source))
    cvCopy(*q3, *temp, #Null)
    cvCopy(*q1, *q3, #Null)
    cvCopy(*temp, *q1, #Null)
    cvCopy(*q4, *temp, #Null)
    cvCopy(*q2, *q4, #Null)
    cvCopy(*temp, *q2, #Null)
  Else
    cvCopy(*q3, *d1, #Null)
    cvCopy(*q4, *d2, #Null)
    cvCopy(*q1, *d3, #Null)
    cvCopy(*q2, *d4, #Null)
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
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_GRAYSCALE)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image\width * 2 >= dtWidth - 100 Or *image\height >= dtHeight - 100
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / (*image\width * 2)
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
      cvNamedWindow(#CV_WINDOW_NAME + " - DFT", #CV_WINDOW_AUTOSIZE)
      hWnd_dft = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - DFT"))
      SendMessage_(hWnd_dft, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_dft, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_dft, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - DFT", *resize\width, *resize\height)
      cvMoveWindow(#CV_WINDOW_NAME + " - DFT", *resize\width + 50, 20)
      *real.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_64F, 1)
      *imaginary.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_64F, 1)
      *complex.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_64F, 2)
      cvConvertScale(*resize, *real, 1, 0)
      cvSetZero(*imaginary)
      cvMerge(*real, *imaginary, #Null, #Null, *complex)
      dft_height = cvGetOptimalDFTSize(*resize\height - 1)
      dft_width = cvGetOptimalDFTSize(*resize\width - 1)
      *dft.CvMat = cvCreateMat(dft_height, dft_width, CV_MAKETYPE(#CV_64F, 2))
      *fourier_real.IplImage = cvCreateImage(dft_width, dft_height, #IPL_DEPTH_64F, 1)
      *fourier_imaginary.IplImage = cvCreateImage(dft_width, dft_height, #IPL_DEPTH_64F, 1)
      temp.CvMat
      cvGetSubRect(*dft, @temp, 0, 0, *resize\width, *resize\height)
      cvCopy(*complex, @temp, #Null)

      If *dft\cols > *resize\width
        cvGetSubRect(*dft, @temp, *resize\width, 0, *dft\cols - *resize\width, *resize\height)
        cvSetZero(@temp)
      EndIf
      cvDFT(*dft, *dft, #CV_DXT_FORWARD, *complex\height)
      cvSplit(*dft, *fourier_real, *fourier_imaginary, #Null, #Null)
      cvPow(*fourier_real, *fourier_real, 2)
      cvPow(*fourier_imaginary, *fourier_imaginary, 2)
      cvAdd(*fourier_real, *fourier_imaginary, *fourier_real, #Null)
      cvPow(*fourier_real, *fourier_real, 0.5)
      cvAbs(*fourier_real, *fourier_real)
      cvLog(*fourier_real, *fourier_real)
      CvShiftDFT(*fourier_real, *fourier_real)
      cvMinMaxLoc(*fourier_real, @min_val.d, @max_val.d, #Null, #Null, #Null)
      cvConvertScale(*fourier_real, *fourier_real, 1 / (max_val - min_val), 1 * -min_val / (max_val - min_val))
      *convert.IplImage = cvCreateImage(*fourier_real\width, *fourier_real\height, #IPL_DEPTH_8U, 1)
      cvConvertScale(*fourier_real, *convert, 255, 0)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *convert
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *convert
          cvShowImage(#CV_WINDOW_NAME, *resize)
          cvShowImage(#CV_WINDOW_NAME + " - DFT", *convert)
          keyPressed = cvWaitKey(0)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*convert)
      cvReleaseImage(@*fourier_imaginary)
      cvReleaseImage(@*fourier_real)
      cvReleaseMat(@*dft)
      cvReleaseImage(@*complex)
      cvReleaseImage(@*imaginary)
      cvReleaseImage(@*real)
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
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\