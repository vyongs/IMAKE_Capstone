IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Apply a pixel spread effect to an image." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Spread Horizontally." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Spread Vertically." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Animate pixel spread." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset Image."

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

ProcedureC CvTrackbarCallback1(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

Procedure SpreadPixels(nSpreadX, nSpreadY, nWidth, nHeight, *resize.IplImage, *spread.IplImage)
  nHalfSpreadX = nSpreadX / 2
  nHalfSpreadY = nSpreadY / 2

  For y = 0 To nHeight
    For x = 0 To nWidth
      nRandomX.f = Random(2147483647) / 2147483647
      nRandomY.f = Random(2147483647) / 2147483647
      nRX = nRandomX * nSpreadX - nHalfSpreadX
      nRY = nRandomY * nSpreadY - nHalfSpreadY
      nX = x + nRX : nY = y + nRY

      If nX < 0 : nX = 0 : EndIf : If nX > nWidth : nX = nWidth : EndIf
      If nY < 0 : nY = 0 : EndIf : If nY > nHeight : nY = nHeight : EndIf

      nB = PeekA(@*resize\imageData\b + (y * *resize\widthStep) + x * 3 + 0)
      nG = PeekA(@*resize\imageData\b + (y * *resize\widthStep) + x * 3 + 1)
      nR = PeekA(@*resize\imageData\b + (y * *resize\widthStep) + x * 3 + 2)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 0, nB)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 1, nG)
      PokeA(@*spread\imageData\b + (nY * *spread\widthStep) + nX * 3 + 2, nR)
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
      cvCreateTrackbar("Spread X", #CV_WINDOW_NAME, @nSpreadX, *resize\width / 2, @CvTrackbarCallback1())
      cvCreateTrackbar("Spread Y", #CV_WINDOW_NAME, @nSpreadY, *resize\height / 2, @CvTrackbarCallback2())
      *spread.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *spread
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
      nWidth = *resize\width - 1 : nHeight = *resize\height - 1

      If nWidth < nHeight : nSpread = nWidth / 4 : Else : nSpread = nHeight / 4 : EndIf

      Repeat
        If *resize
          SpreadPixels(nSpreadX, nSpreadY, nWidth, nHeight, *resize, *spread)
          cvShowImage(#CV_WINDOW_NAME, *spread)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              cvSetTrackbarPos("Spread X", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Spread Y", #CV_WINDOW_NAME, 0)
            Case 32
              cvSetTrackbarPos("Spread X", #CV_WINDOW_NAME, nSpread)
              cvSetTrackbarPos("Spread Y", #CV_WINDOW_NAME, nSpread)

              For rtnCount = 0 To nSpread
                SpreadPixels(rtnCount, rtnCount, nWidth, nHeight, *resize, *spread)
                cvShowImage(#CV_WINDOW_NAME, *spread)
                cvWaitKey(10)
              Next
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*spread)
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

OpenCV("images/sketch1.jpg")
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\