IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Local Binary Pattern: An efficient texture operator thresholding the neighborhood of each pixel." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view."

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

Procedure CalculateLBP(*image.IplImage, *lbp.IplImage)
  For i = 1 To *image\height - 2
    For j = 1 To *image\width - 2
      center = PeekA(@CV_IMAGE_ELEM(*image, i, j))
      neighborhood = Bool(PeekA(@CV_IMAGE_ELEM(*image, i, j - 1)) > center) << 0
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i + 1, j - 1)) > center) << 1
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i + 1, j)) > center) << 2
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i + 1, j + 1)) > center) << 3
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i, j + 1)) > center) << 4
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i - 1, j + 1)) > center) << 5
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i - 1, j)) > center) << 6
      neighborhood + Bool(PeekA(@CV_IMAGE_ELEM(*image, i - 1, j - 1)) > center) << 7
      PokeA(@*lbp\imageData\b + i * *lbp\widthStep + j, neighborhood)
    Next
  Next
EndProcedure

Procedure CalculateLBP_Other1(*image.IplImage, *lbp.IplImage)
  Dim neighborhood(8)

  For i = 1 To *image\height - 2
    For j = 1 To *image\width - 2
      neighborhood(0) = PeekA(@CV_IMAGE_ELEM(*image, i, j - 1))
      neighborhood(1) = PeekA(@CV_IMAGE_ELEM(*image, i + 1, j - 1))
      neighborhood(2) = PeekA(@CV_IMAGE_ELEM(*image, i + 1, j))
      neighborhood(3) = PeekA(@CV_IMAGE_ELEM(*image, i + 1, j + 1))
      neighborhood(4) = PeekA(@CV_IMAGE_ELEM(*image, i, j + 1))
      neighborhood(5) = PeekA(@CV_IMAGE_ELEM(*image, i - 1, j + 1))
      neighborhood(6) = PeekA(@CV_IMAGE_ELEM(*image, i - 1, j))
      neighborhood(7) = PeekA(@CV_IMAGE_ELEM(*image, i - 1, j - 1))
      center = PeekA(@CV_IMAGE_ELEM(*image, i, j)) : lbp = 0

      For k = 0 To ArraySize(neighborhood()) - 1
        lbp + Bool(neighborhood(k) > center) << k
      Next
      PokeA(@*lbp\imageData\b + i * *lbp\widthStep + j, lbp)
    Next
  Next
EndProcedure

Procedure CalculateLBP_Other2(*image.IplImage, *lbp.IplImage)
  Dim lbpMask(8, 2)
  lbpMask(0, 0) = 0 : lbpMask(0, 1) = -1 : lbpMask(1, 0) = 1 : lbpMask(1, 1) = -1
  lbpMask(2, 0) = 1 : lbpMask(2, 1) = 0 : lbpMask(3, 0) = 1 : lbpMask(3, 1) = 1
  lbpMask(4, 0) = 0 : lbpMask(4, 1) = 1 : lbpMask(5, 0) = -1 : lbpMask(5, 1) = 1
  lbpMask(6, 0) = -1 : lbpMask(6, 1) = 0 : lbpMask(7, 0) = -1 : lbpMask(7, 1) = -1

  For i = 1 To *image\height - 2
    For j = 1 To *image\width - 2
      center = PeekA(@*image\imageData\b + i * *image\widthStep + j) : lbp = 0

      For k = 0 To ArraySize(lbpMask()) - 1
        neighborhood = PeekA(@*image\imageData\b + (i * *image\widthStep + lbpMask(k, 1)) + (j + lbpMask(k, 0)))

        If neighborhood > center : lbp + 1 << k : EndIf

      Next
      PokeA(@*lbp\imageData\b + i * *lbp\widthStep + j, lbp)
    Next
  Next
EndProcedure

Procedure CalculateLBP_Other3(*image.IplImage, *lbp.IplImage)
  Dim neighborhood(8)
  scalar.CvScalar

  For i = 1 To *image\height - 2
    For j = 1 To *image\width - 2
      If PeekA(@CV_IMAGE_ELEM(*image, i, j - 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(0) = 1 : Else : neighborhood(0) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i + 1, j - 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(1) = 1 : Else : neighborhood(1) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i + 1, j)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(2) = 1 : Else : neighborhood(2) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i + 1, j + 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(3) = 1 : Else : neighborhood(3) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i, j + 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(4) = 1 : Else : neighborhood(4) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i - 1, j + 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(5) = 1 : Else : neighborhood(5) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i - 1, j)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(6) = 1 : Else : neighborhood(6) = 0 : EndIf
      If PeekA(@CV_IMAGE_ELEM(*image, i - 1, j - 1)) > PeekA(@CV_IMAGE_ELEM(*image, i, j)) : neighborhood(7) = 1 : Else : neighborhood(7) = 0 : EndIf

      scalar\val[0] = neighborhood(0) * 1 + neighborhood(1) * 2 + neighborhood(2) * 4 + neighborhood(3) * 8 + neighborhood(4) * 16 +
                      neighborhood(5) * 32 + neighborhood(6) * 64 + neighborhood(7) * 128
      cvSet2D(*lbp, i, j, scalar\val[0], scalar\val[1], scalar\val[2], scalar\val[3])
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
    *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_GRAYSCALE)
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
   
    If *resize\width > 200 And *resize\height > 200
      *reset.IplImage = cvCloneImage(*resize)
      *lbp.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 1)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *lbp
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *lbp
          cvSetZero(*lbp)
          CalculateLBP(*resize, *lbp)

          Select PIP
            Case 0
              cvSetImageROI(*lbp, 20, 20, iWidth, iHeight)
              cvAndS(*lbp, 0, 0, 0, 0, *lbp, #Null)
              cvAdd(*lbp, *PIP, *lbp, #Null)
              cvResetImageROI(*lbp)
              cvRectangleR(*lbp, 19, 19, iWidth + 2, iHeight + 2, 255, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*lbp, *resize\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*lbp, 0, 0, 0, 0, *lbp, #Null)
              cvAdd(*lbp, *PIP, *lbp, #Null)
              cvResetImageROI(*lbp)
              cvRectangleR(*lbp, *lbp\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 255, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *lbp)
          keyPressed = cvWaitKey(0)

          If keyPressed = 86 Or keyPressed = 118
            PIP = (PIP + 1) % 3
            cvReleaseImage(@*resize)
            *resize = cvCloneImage(*reset)
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*lbp)
      cvReleaseImage(@*reset)
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

OpenCV("images/flower.png")
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\