IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, hWnd_spiderweb

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draw a Spider Web sketch from a color image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Start / Stop process."

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
      SendMessage_(hWnd_spiderweb, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x, y, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save.IplImage = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
  EndSelect
EndProcedure

#ACCURACY = 100

Procedure TestColor(*resize.IplImage, nTotal, nLocation)
  nB = PeekA(@*resize\imageData\b + nLocation + 0)
  nG = PeekA(@*resize\imageData\b + nLocation + 1)
  nR = PeekA(@*resize\imageData\b + nLocation + 2)
  nPercent.f = nTotal / (nB + nG + nR) * 100

  If nPercent >= #ACCURACY : ProcedureReturn #True : Else : ProcedureReturn #False : EndIf

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

    If *image\width >= dtWidth / 2 - 100 Or *image\height >= dtHeight - 100
      iWidth = dtWidth / 2 - 100
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

    If *resize\nChannels = 3
      cvNamedWindow(#CV_WINDOW_NAME + " - Spider Web", #CV_WINDOW_AUTOSIZE)
      hWnd_spiderweb = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Spider Web"))
      SendMessage_(hWnd_spiderweb, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_spiderweb, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_spiderweb, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - Spider Web", *resize\width, *resize\height)
      cvMoveWindow(#CV_WINDOW_NAME + " - Spider Web", *resize\width + 50, 20)
      nDistance.f = 100
      nSpeed = 10000
      NewPixel = #True
      #MAX_TRIES = 1000
      #TESTS = 10
      *spiderweb.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *resize\nChannels)
      cvSet(*spiderweb, 255, 255, 255, 0, #Null)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *spiderweb
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          If Not nStop
            If nDistance > 25 : nDistance - 0.1 : EndIf
            If nSpeed < 20000 : nSpeed + 1 : EndIf

            For rtnCount = 0 To nSpeed - 1
              If NewPixel Or nTries > #MAX_TRIES
                NewPixel = #False : nTries = 0
                nLocation = Random(*resize\width - 1) * 3 + Random(*resize\height - 1) * *resize\widthStep
                x1 = nLocation % *resize\widthStep / 3
                y1 = nLocation / *resize\widthStep
                nB = PeekA(@*resize\imageData\b + nLocation + 0)
                nG = PeekA(@*resize\imageData\b + nLocation + 1)
                nR = PeekA(@*resize\imageData\b + nLocation + 2)
                nTotal = nB + nG + nR
              EndIf
              nLocation = Random(*resize\width - 1) * 3 + Random(*resize\height - 1) * *resize\widthStep

              If TestColor(*resize, nTotal, nLocation)
                x2 = nLocation % *resize\widthStep / 3
                y2 = nLocation / *resize\widthStep

                If Sqr((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1)) <= nDistance
                  cvLine(*spiderweb, x1, y1, x2, y2, nB, nG, nR, 0, 1, 8, #Null) : nCount + 1
                EndIf
              EndIf

              If nCount > #TESTS : NewPixel = #True : nCount = 0 : EndIf

              nTries + 1
            Next
          EndIf
          cvShowImage(#CV_WINDOW_NAME, *spiderweb)
          cvShowImage(#CV_WINDOW_NAME + " - Spider Web", *resize)

          If nStop : keyPressed = cvWaitKey(0) : Else : keyPressed = cvWaitKey(10) : EndIf
          If keyPressed = 32 : nStop ! #True : EndIf

        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*spiderweb)
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

OpenCV("images/fruits.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\