IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Implementation of the Floyd-Steinberg dithering algorithm applied to a grayscale image." + #LF$ + #LF$ +
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
      *dither.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)

      For y = 0 To *resize\height - 1
        For x = 0 To *resize\width - 1
          oldPixel = PeekA(@*resize\imageData\b + y * *resize\widthStep + x)

          If oldPixel > 128 : newPixel = 255 : Else : newPixel = 0 : EndIf

          PokeA(@*dither\imageData\b + y * *dither\widthStep + x, newPixel)

          If y <> *resize\height - 1 And x <> 0 And x <> *resize\width - 1
            quantError = oldPixel - newPixel
            var1 = PeekA(@*resize\imageData\b + (y + 0) * *resize\widthStep + (x + 1)) + quantError * 7 / 16
            var2 = PeekA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x - 1)) + quantError * 3 / 16
            var3 = PeekA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x + 0)) + quantError * 5 / 16
            var4 = PeekA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x + 1)) + quantError * 1 / 16

            If var1 > 255 : var1 = 255 : EndIf : If var1 < 0 : var1 = 0 : EndIf
            If var2 > 255 : var2 = 255 : EndIf : If var2 < 0 : var2 = 0 : EndIf
            If var3 > 255 : var3 = 255 : EndIf : If var3 < 0 : var3 = 0 : EndIf
            If var4 > 255 : var4 = 255 : EndIf : If var4 < 0 : var4 = 0 : EndIf

            PokeA(@*resize\imageData\b + (y + 0) * *resize\widthStep + (x + 1), var1)
            PokeA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x - 1), var2)
            PokeA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x + 0), var3)
            PokeA(@*resize\imageData\b + (y + 1) * *resize\widthStep + (x + 1), var4)
          EndIf
        Next
      Next
      *reset.IplImage = cvCloneImage(*dither)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 1)
      cvResize(*image, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *dither
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *dither
          Select PIP
            Case 0
              cvSetImageROI(*dither, 20, 20, iWidth, iHeight)
              cvAndS(*dither, 0, 0, 0, 0, *dither, #Null)
              cvAdd(*dither, *PIP, *dither, #Null)
              cvResetImageROI(*dither)
              cvRectangleR(*dither, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*dither, *dither\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*dither, 0, 0, 0, 0, *dither, #Null)
              cvAdd(*dither, *PIP, *dither, #Null)
              cvResetImageROI(*dither)
              cvRectangleR(*dither, *dither\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *dither)
          keyPressed = cvWaitKey(0)

          If keyPressed = 86 Or keyPressed = 118
            PIP = (PIP + 1) % 3
            cvReleaseImage(@*dither)
            *dither = cvCloneImage(*reset)
            *param\Pointer1 = *dither
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*dither)
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

OpenCV("images/baboon.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\