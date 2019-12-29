IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Encode / Decode a 4 channel image where the black areas have been converted to transparency." + #LF$ + #LF$ +
                  "Opening an encoded image will automatically be decoded." + #LF$ + #LF$ +
                  "Hold down the SHIFT key while opening the context menu to save the image normally, otherwise it will be saved encoded as a single-row matrix."

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
      If flags = #CV_EVENT_RBUTTONDOWN | #CV_EVENT_FLAG_SHIFTKEY
        *save = *param\Pointer1
      Else
        *save = *param\Pointer2
      EndIf
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

    If *image\height = 1
      temp1.CvMat : *temp1.CvMat = cvGetMat(*image, @temp1, #Null, 0)
      *temp2.IplImage = cvDecodeImage(*temp1, #CV_LOAD_IMAGE_UNCHANGED)
      *resize.IplImage = cvCreateImage(*temp2\width, *temp2\height, #IPL_DEPTH_8U, 3)

      If *temp2\nChannels = 3 : cvCopy(*temp2, *resize, #Null) : Else : cvCvtColor(*temp2, *resize, #CV_BGRA2BGR, 1) : EndIf

    Else
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
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\nChannels = 3
      *transparent.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 4))
      cvCvtColor(*resize, *transparent, #CV_BGR2BGRA, 1)

      For y = 0 To *transparent\rows - 1
        For x = 0 To *transparent\cols - 1
          B = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 0)
          G = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 1)
          R = PeekA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 2)

          If B + G + R < 10 : PokeA(@*transparent\ptr\b + y * *transparent\Step + x * 4 + 3, 0) : EndIf

        Next
      Next
      temp2.IplImage
      params.CvSaveData
      params\paramId = #CV_IMWRITE_PNG_COMPRESSION
      params\paramValue = 3
      *encode.CvMat = cvEncodeImage(".png", *transparent, @params)
      *decode.CvMat = cvDecodeImage(*encode, #CV_LOAD_IMAGE_UNCHANGED)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = cvGetImage(*decode, @temp2)
      *param\Pointer2 = cvGetImage(*encode, @temp2)
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *decode
          cvShowImage(#CV_WINDOW_NAME, *decode)
          keyPressed = cvWaitKey(0)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseMat(@*transparent)
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

OpenCV("images/flower.png")
; IDE Options = PureBasic 5.31 Beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\