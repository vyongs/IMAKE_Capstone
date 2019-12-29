IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Balance color by scaling the histogram of the RGB channels." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust balance." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle offset." + #LF$ + #LF$ +
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

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

Procedure ColorBalance(*in.IplImage, *out.IplImage, InMin.f, InMax.f, OutMin.f, OutMax.f, Balance, UseOffset)
  Dim *inSplit.IplImage(3)

  For rtnCount = 0 To 3 - 1
    *inSplit(rtnCount) = cvCreateImage(*in\width, *in\height, #IPL_DEPTH_8U, 1)
  Next
  cvSplit(*in, *inSplit(0), *inSplit(1), *inSplit(2), #Null)
  s1.f = Balance + 1 : s2.f = Balance + 1 : nBins = 16 : nDepth = 2
  nElements = Pow(nBins, nDepth)

  For rtnCount = 0 To 3 - 1
    Dim hist(nElements * 2)

    For nSize = 0 To *inSplit(rtnCount)\imageSize - 1
      nPos = 0 : nOffset = 0
      nMin.f = InMin - 0.5 : nMax.f = InMax + 0.5
      nInterval.f = (nMax - nMin) / nBins
      nValue = PeekA(@*inSplit(rtnCount)\imageData\b + nSize)

      For i = 0 To nDepth - 1
        nBin = (nValue - nMin + 1e-4f) / nInterval
        hist(nPos + nBin) + 1

        If UseOffset : nOffset + Pow(nBins, i) : EndIf

        nPos = (nOffset + nPos + nBin) * nBins
        nMin + nBin * nInterval
        nInterval / nBins
      Next
    Next
    nTotal = *inSplit(rtnCount)\imageSize
    p1 = 0 : p2 = nBins - 1
    n1 = 0 : n2 = nTotal
    nMin = InMin - 0.5
    nMax = InMax + 0.5
    nInterval = (nMax - nMin) / nBins
    nOffset = 0

    For i = 0 To nDepth - 1
      While n1 + hist(p1) < s1 * nTotal / 100
        n1 + hist(p1) : p1 + 1
        nMin + nInterval
      Wend

      If UseOffset : nOffset + Pow(nBins, i) : EndIf

      p1 * nBins + nOffset

      While n2 - hist(p2) > (100 - s2) * nTotal / 100
        n2 - hist(p2) : p2 - 1
        nMax - nInterval
      Wend
      p2 * nBins - 1
      p2 + nOffset
      nInterval / nBins
    Next

    For nSize = 0 To *inSplit(rtnCount)\imageSize - 1
      nValue = PeekA(@*inSplit(rtnCount)\imageData\b + nSize)
      nColor = (OutMax - OutMin) * (nValue - nMin) / (nMax - nMin) + OutMin

      If nColor < 0 : nColor = 0
      ElseIf nColor > 255 : nColor = 255 : EndIf

      PokeA(@*inSplit(rtnCount)\imageData\b + nSize, nColor)
    Next
  Next
  cvMerge(*inSplit(0), *inSplit(1), *inSplit(2), #Null, *out)

  For rtnCount = 3 - 1 To 0 Step -1
    cvReleaseImage(@*inSplit(rtnCount))
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

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *image\width
      iHeight = dtHeight - (100 + 48)
      iRatio2.d = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight + 48)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      cvCreateTrackbar("Balance", #CV_WINDOW_NAME, @nBalance, 10, @CvTrackbarCallback())
      *balance.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      cvResize(*resize, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *balance
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          ColorBalance(*resize, *balance, 0, 255, 0, 255, nBalance, nOffset)

          Select PIP
            Case 0
              cvSetImageROI(*balance, 20, 20, iWidth, iHeight)
              cvAndS(*balance, 0, 0, 0, 0, *balance, #Null)
              cvAdd(*balance, *PIP, *balance, #Null)
              cvResetImageROI(*balance)
              cvRectangleR(*balance, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*balance, *balance\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*balance, 0, 0, 0, 0, *balance, #Null)
              cvAdd(*balance, *PIP, *balance, #Null)
              cvResetImageROI(*balance)
              cvRectangleR(*balance, *balance\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *balance)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              nOffset ! #True
            Case 86, 118
              PIP = (PIP + 1) % 3
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*balance)
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

OpenCV("images/enhance2.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\