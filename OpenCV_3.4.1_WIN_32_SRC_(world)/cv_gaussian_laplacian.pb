IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "A visual representation of a Gaussian and Laplacian Pyramid." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Gaussian / Laplacian."

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
    nLevel = 5 : Dim *Gaussian.IplImage(nLevel) : Dim *Laplacian.IplImage(nLevel - 1)
    *Gaussian(0) = cvCloneImage(*resize)
    *GaussianPyramid.IplImage = cvCloneImage(*resize)
    *LaplacianPyramid.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *resize\nChannels)

    For rtnCount = 1 To nLevel
      *Gaussian(rtnCount) = cvCreateImage(*Gaussian(rtnCount - 1)\width / 2, *Gaussian(rtnCount - 1)\height / 2, #IPL_DEPTH_8U, *resize\nChannels)
      cvPyrDown(*Gaussian(rtnCount - 1), *Gaussian(rtnCount), #CV_GAUSSIAN_5x5)
      cvSetImageROI(*GaussianPyramid, *GaussianPyramid\width - *Gaussian(rtnCount)\width, *GaussianPyramid\height - *Gaussian(rtnCount)\height, *Gaussian(rtnCount)\width, *Gaussian(0)\height)
      cvAndS(*GaussianPyramid, 0, 0, 0, 0, *GaussianPyramid, #Null)
      cvAdd(*GaussianPyramid, *Gaussian(rtnCount), *GaussianPyramid, #Null)
      cvResetImageROI(*GaussianPyramid)
      cvRectangleR(*GaussianPyramid, *GaussianPyramid\width - *Gaussian(rtnCount)\width, *GaussianPyramid\height - *Gaussian(rtnCount)\height, *Gaussian(rtnCount)\width, *Gaussian(0)\height, 0, 255, 255, 0, 1, #CV_AA, #Null)
      *Laplacian(rtnCount - 1) = cvCreateImage(*Gaussian(rtnCount - 1)\width, *Gaussian(rtnCount - 1)\height, #IPL_DEPTH_8U, *resize\nChannels)
      cvPyrUp(*Gaussian(rtnCount), *Laplacian(rtnCount - 1), #CV_GAUSSIAN_5x5)     
      cvSub(*Gaussian(rtnCount - 1), *Laplacian(rtnCount - 1), *Laplacian(rtnCount - 1), #Null)
      cvSetImageROI(*LaplacianPyramid, *LaplacianPyramid\width - *Laplacian(rtnCount - 1)\width, *LaplacianPyramid\height - *Laplacian(rtnCount - 1)\height, *Laplacian(rtnCount - 1)\width, *Laplacian(rtnCount - 1)\height)
      cvAndS(*LaplacianPyramid, 0, 0, 0, 0, *LaplacianPyramid, #Null)
      cvAdd(*LaplacianPyramid, *Laplacian(rtnCount - 1), *LaplacianPyramid, #Null)
      cvResetImageROI(*LaplacianPyramid)
      cvRectangleR(*LaplacianPyramid, *LaplacianPyramid\width - *Laplacian(rtnCount - 1)\width, *LaplacianPyramid\height - *Laplacian(rtnCount - 1)\height, *Laplacian(rtnCount - 1)\width, *Laplacian(rtnCount - 1)\height, 0, 255, 255, 0, 1, #CV_AA, #Null)
    Next

    For rtnCount = nLevel To 0 Step -1
      If rtnCount < nLevel : cvReleaseImage(@*Laplacian(rtnCount)) : EndIf

      cvReleaseImage(@*Gaussian(rtnCount))
    Next
    keyPressed = 32
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *GaussianPyramid
        If keyPressed = 32
          pyramid ! #True

          If pyramid
            cvShowImage(#CV_WINDOW_NAME, *GaussianPyramid)
            *param\Pointer1 = *GaussianPyramid
          Else
            cvShowImage(#CV_WINDOW_NAME, *LaplacianPyramid)
            *param\Pointer1 = *LaplacianPyramid
          EndIf
          keyPressed = cvWaitKey(0)
        EndIf
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*LaplacianPyramid)
    cvReleaseImage(@*GaussianPyramid)
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

OpenCV("images/smooth2.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\