IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Steganography is the practice of concealing a file, message, image, or video within another file, message, image, or video." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view." + #LF$ + #LF$ +
                  "OPEN        " + #TAB$ + ": Choose an image to hide." + #LF$ +
                  "SAVE        " + #TAB$ + ": Includes the hidden image." + #LF$ + #LF$ +
                  "If needed the hidden image will be resized to fit the main image." + #LF$ + #LF$ +
                  "PIP not included in the saved image."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          openCV = #True
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
        Case 2
          FileName.s = SaveCVImage(#True, 3)

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

Procedure HideImage(*encode.CvMat, *main.IplImage)
  Define.a nByte
  nCols = *encode\cols

  For i = 7 - 1 To 0 Step -1
    PokeA(@*main\imageData\b + nPosition, REPLACE_BIT(PeekA(@*main\imageData\b + nPosition), 0, EXTRACT_BIT(74, i)))
    nPosition + 1
  Next

  For i = 7 - 1 To 0 Step -1
    PokeA(@*main\imageData\b + nPosition, REPLACE_BIT(PeekA(@*main\imageData\b + nPosition), 0, EXTRACT_BIT(72, i)))
    nPosition + 1
  Next

  For i = 7 - 1 To 0 Step -1
    PokeA(@*main\imageData\b + nPosition, REPLACE_BIT(PeekA(@*main\imageData\b + nPosition), 0, EXTRACT_BIT(80, i)))
    nPosition + 1
  Next

  For i = 24 - 1 To 0 Step -1
    PokeA(@*main\imageData\b + nPosition, REPLACE_BIT(PeekA(@*main\imageData\b + nPosition), 0, EXTRACT_BIT(nCols, i)))
    nPosition + 1
  Next

  For i = 0 To nCols
    nByte = PeekA(@*encode\ptr\b + i)

    For j = 8 - 1 To 0 Step -1
      PokeA(@*main\imageData\b + nPosition, REPLACE_BIT(PeekA(@*main\imageData\b + nPosition), 0, EXTRACT_BIT(nByte, j)))
      nPosition + 1
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
    *main.IplImage = cvLoadImage("images/seams1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    nSize1 = *image\width * *image\height * 3
    nSize2 = *main\width * *main\height * 3 / 8 - 45

    If nSize1 > nSize2
      nValue.d = 1

      Repeat
        nValue - 0.01
        nWidth = *image\width * nValue
        nHeight = *image\height * nValue
        nSize1 = nWidth * nHeight * 3
      Until nSize1 < nSize2
      *steganography.IplImage = cvCreateImage(nWidth, nHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *steganography, #CV_INTER_AREA)
    Else
      *steganography.IplImage = cvCloneImage(*image)
    EndIf

    If *image\nChannels = 3
      params.CvSaveData
      params\paramId = #CV_IMWRITE_PNG_COMPRESSION
      params\paramValue = 3
      *encode.CvMat = cvEncodeImage(".png", *steganography, @params)
      HideImage(*encode, *main)
    EndIf
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *main\width >= dtWidth - 100 Or *main\height >= dtHeight - 100
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *main\width
      iHeight = dtHeight - 100
      iRatio2.d = iHeight / *main\height

      If iRatio1 < iRatio2
        iWidth = *main\width * iRatio1
        iHeight = *main\height * iRatio1
      Else
        iWidth = *main\width * iRatio2
        iHeight = *main\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *main\nChannels)
      cvResize(*main, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *main\width, *main\height)
      *resize.IplImage = cvCloneImage(*main)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *steganography\nChannels = 3
      *reset.IplImage = cvCloneImage(*resize)
      iRatio.d = 150 / *steganography\width
      iWidth = *steganography\width * iRatio
      iHeight = *steganography\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      cvResize(*steganography, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *main
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          Select PIP
            Case 0
              cvSetImageROI(*resize, 20, 20, iWidth, iHeight)
              cvAndS(*resize, 0, 0, 0, 0, *resize, #Null)
              cvAdd(*resize, *PIP, *resize, #Null)
              cvResetImageROI(*resize)
              cvRectangleR(*resize, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*resize, *resize\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*resize, 0, 0, 0, 0, *resize, #Null)
              cvAdd(*resize, *PIP, *resize, #Null)
              cvResetImageROI(*resize)
              cvRectangleR(*resize, *resize\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *resize)
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
      cvReleaseImage(@*reset)
      cvReleaseImage(@*resize)
      cvReleaseMat(@*encode)
      cvReleaseImage(@*steganography)
      cvReleaseImage(@*main)
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
      cvReleaseMat(@*encode)
      cvReleaseImage(@*steganography)
      cvReleaseImage(@*main)
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