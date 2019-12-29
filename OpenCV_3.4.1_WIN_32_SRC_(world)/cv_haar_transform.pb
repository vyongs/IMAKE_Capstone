IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Implements a Haar wavelet transform, decomposing then reconstructing the image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Show next stage."

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
    *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
    cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
    *gray32.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_32F, 1))
    cvSetZero(*gray32) : cvConvert(*gray, *gray32)
    *image1.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    *image2.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    *image3.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols / 2, CV_MAKETYPE(#CV_32F, 1))
    *image4.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols / 2, CV_MAKETYPE(#CV_32F, 1))
    *image5.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols / 2, CV_MAKETYPE(#CV_32F, 1))
    *image6.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols / 2, CV_MAKETYPE(#CV_32F, 1))

    For y = 0 To *gray32\rows - 1 Step 2
      For x = 0 To *gray32\cols - 1
        a.f = cvmGet(*gray32, y, x)
        b.f = cvmGet(*gray32, y + 1, x)
        c.f = (a + b) * 0.707
        d.f = (a - b) * 0.707
        cvmSet(*image1, y / 2, x, c)
        cvmSet(*image2, y / 2, x, d)
      Next
    Next

    For y = 0 To *gray32\rows / 2 - 1
      For x = 0 To *gray32\cols - 1 Step 2
        a = cvmGet(*image1, y, x)
        b = cvmGet(*image1, y, (x + 1))
        c = (a + b) * 0.707
        d = (a - b) * 0.707
        cvmSet(*image3, y, x / 2, c)
        cvmSet(*image4, y, x / 2, d)
      Next
    Next

    For y = 0 To *gray32\rows / 2 - 1
      For x = 0 To *gray32\cols - 1 Step 2
        a = cvmGet(*image2, y, x)
        b = cvmGet(*image2, y, (x + 1))
        c = (a + b) * 0.707
        d = (a - b) * 0.707
        cvmSet(*image5, y, x / 2, c)
        cvmSet(*image6, y, x / 2, d)
      Next
    Next
    *D.CvMat : temp.CvMat
    *decomposition.CvMat = cvCreateMat(*gray32\rows, *gray32\cols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*decomposition)
    *decomposition8.CvMat = cvCreateMat(*gray32\rows, *gray32\cols, CV_MAKETYPE(#CV_8U, 1))
    *D = cvGetSubRect(*decomposition, @temp, 0, 0, *gray32\cols / 2, *gray32\rows / 2)
    cvCopy(*image3, *D, #Null)
    *D = cvGetSubRect(*decomposition, @temp, 0, *gray32\rows / 2, *gray32\cols / 2, *gray32\rows / 2)
    cvCopy(*image4, *D, #Null)
    *D = cvGetSubRect(*decomposition, @temp, *gray32\cols / 2, 0, *gray32\cols / 2, *gray32\rows / 2)
    cvCopy(*image5, *D, #Null)
    *D = cvGetSubRect(*decomposition, @temp, *gray32\cols / 2, *gray32\rows / 2, *gray32\cols / 2, *gray32\rows / 2)
    cvCopy(*image6, *D, #Null)
    cvConvert(*decomposition, *decomposition8)
    *image11.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    *image12.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    *image13.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    *image14.CvMat = cvCreateMat(*gray32\rows / 2, *gray32\cols, CV_MAKETYPE(#CV_32F, 1))
    
    For y = 0 To *gray32\rows / 2 - 1
      For x = 0 To *gray32\cols / 2 - 1
        cvmSet(*image11, y, x * 2, cvmGet(*image3, y, x))
        cvmSet(*image12, y, x * 2, cvmGet(*image4, y, x))
        cvmSet(*image13, y, x * 2, cvmGet(*image5, y, x))
        cvmSet(*image14, y, x * 2, cvmGet(*image6, y, x))
      Next
    Next

    For y = 0 To *gray32\rows / 2 - 1
      For x = 0 To *gray32\cols - 1 Step 2
        a = cvmGet(*image11, y, x)
        b = cvmGet(*image12, y, x)
        c = (a + b) * 0.707
        cvmSet(*image11, y, x, c)
        d = (a - b) * 0.707
        cvmSet(*image11, y, x + 1, d)
        a = cvmGet(*image13, y, x)
        b = cvmGet(*image14, y, x)
        c = (a + b) * 0.707
        cvmSet(*image13, y, x, c)
        d = (a - b) * 0.707
        cvmSet(*image13, y, x + 1, d)
      Next
    Next
    *reconstruction.CvMat = cvCreateMat(*gray32\rows, *gray32\cols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*reconstruction)
    *reconstruction8.CvMat = cvCreateMat(*gray32\rows, *gray32\cols, CV_MAKETYPE(#CV_8U, 1))
    *temp.CvMat = cvCreateMat(*gray32\rows, *gray32\cols, CV_MAKETYPE(#CV_32F, 1)) : cvSetZero(*temp)

    For y = 0 To *gray32\rows / 2 - 1
      For x = 0 To *gray32\cols - 1
        cvmSet(*reconstruction, y * 2, x, cvmGet(*image11, y, x))
        cvmSet(*temp, y * 2, x, cvmGet(*image13, y, x))
      Next
    Next

    For y = 0 To *gray32\rows - 1 Step 2
      For x = 0 To *gray32\cols - 1
        a = cvmGet(*reconstruction, y, x)
        b = cvmGet(*temp, y, x)
        c = (a + b) * 0.707
        cvmSet(*reconstruction, y, x, c)
        d = (a - b) * 0.707
        cvmSet(*reconstruction, y + 1, x, d)
      Next
    Next
    cvConvert(*reconstruction, *reconstruction8)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *resize
        Select nStage
          Case 0
            cvShowImage(#CV_WINDOW_NAME, *resize)
            *param\Pointer1 = *resize
          Case 1
            cvShowImage(#CV_WINDOW_NAME, *decomposition8)
            *param\Pointer1 = *decomposition8
          Case 2
            cvShowImage(#CV_WINDOW_NAME, *reconstruction8)
            *param\Pointer1 = *reconstruction8
        EndSelect        
        keyPressed = cvWaitKey(0)

        If keyPressed = 32 : nStage = (nStage + 1) % 3 : EndIf

      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseMat(@*temp)
    cvReleaseMat(@*reconstruction8)
    cvReleaseMat(@*reconstruction)
    cvReleaseMat(@*image14)
    cvReleaseMat(@*image13)
    cvReleaseMat(@*image12)
    cvReleaseMat(@*image11)
    cvReleaseMat(@*decomposition8)
    cvReleaseMat(@*decomposition)
    cvReleaseMat(@*image6)
    cvReleaseMat(@*image5)
    cvReleaseMat(@*image4)
    cvReleaseMat(@*image3)
    cvReleaseMat(@*image2)
    cvReleaseMat(@*image1)
    cvReleaseMat(@*gray32)
    cvReleaseImage(@*gray)
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

OpenCV("images/lena.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\