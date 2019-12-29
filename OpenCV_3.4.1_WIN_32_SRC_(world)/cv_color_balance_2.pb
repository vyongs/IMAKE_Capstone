IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Balance color by contrast stretching the RGB channels, or applying a normalize algorithm." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust balance." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle method." + #LF$ + #LF$ +
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

Procedure ContrastStretching(*src.IplImage, *dst.IplImage, nMin, nMax, nIndex)
  If nMax <= nMin
    nIndexValue = 255 / 2

    For y = 0 To *src\height - 1
      For x = 0 To *src\width - 1
        PokeA(@*dst\imageData\b + y * *dst\widthStep + x * 3 + nIndex, nIndexValue)
      Next
    Next
  Else
    Dim nNorm(256)
    For i = 0 To nMin - 1 : nNorm(i) = 0 : Next
    For i = nMin To nMax - 1 : nNorm(i) = (i - nMin) * 255 / (nMax - nMin + 0.5) : Next
    For i = nMax To 256 - 1 : nNorm(i) = 255 : Next

    For y = 0 To *src\height - 1
      For x = 0 To *src\width - 1
        nColor = PeekA(@*src\imageData\b + y * *src\widthStep + x * 3 + nIndex)
        PokeA(@*dst\imageData\b + y * *dst\widthStep + x * 3 + nIndex, nNorm(nColor))
      Next
    Next
  EndIf
EndProcedure

Procedure ColorBalance(*resize.IplImage, Array *bgr_Planes.IplImage(1), *balance.IplImage, Balance)
  histSize = 256 : Dim range.f(2) : range(0) = 0 : range(1) = 256
  *histRange.FLOAT : PokeL(@*histRange, @range())
  *b_hist.CvHistogram = cvCreateHist(1, @histSize, #CV_HIST_ARRAY, @*histRange, #True)
  *g_hist.CvHistogram = cvCreateHist(1, @histSize, #CV_HIST_ARRAY, @*histRange, #True)
  *r_hist.CvHistogram = cvCreateHist(1, @histSize, #CV_HIST_ARRAY, @*histRange, #True)
  cvCalcHist(@*bgr_Planes(0), *b_hist, #False, #Null)
  cvCalcHist(@*bgr_Planes(1), *g_hist, #False, #Null)
  cvCalcHist(@*bgr_Planes(2), *r_hist, #False, #Null)
  Dim cbhist.f(histSize) : Dim cghist.f(histSize) : Dim crhist.f(histSize)

  For i = 0 To histSize - 1
    If i = 0
      cbhist(i) = PeekF(*b_hist\bins\fl + i * 4)
      cghist(i) = PeekF(*g_hist\bins\fl + i * 4)
      crhist(i) = PeekF(*r_hist\bins\fl + i * 4)
    Else
      cbhist(i) = cbhist(i - 1) + PeekF(*b_hist\bins\fl + i * 4)
      cghist(i) = cghist(i - 1) + PeekF(*g_hist\bins\fl + i * 4)
      crhist(i) = crhist(i - 1) + PeekF(*r_hist\bins\fl + i * 4)
    EndIf
  Next
  vMin1 = 0 : vMin2 = 0 : vMin3 = 0
  vMax1 = histSize - 1 : vMax2 = vMax1 : vMax3 = vMax1
  nSize = *resize\width * *resize\height
  s1.f = Balance + 1 : s2.f = Balance + 1

  While vMin1 < histSize - 1 And cbhist(vMin1) <= nSize * s1 / 100 : vMin1 + 1 : Wend
  While vMax1 < histSize And cbhist(vMax1) > nSize * (1 - s2 / 100) : vMax1 - 1 : Wend
  If vMax1 < histSize - 1 : vMax1 + 1 : EndIf
  While vMin2 < histSize - 1 And cghist(vMin2) <= nSize * s1 / 100 : vMin2 + 1 : Wend
  While vMax2 < histSize And cghist(vMax2) > nSize * (1 - s2 / 100) : vMax2 - 1 : Wend
  If vMax2 < histSize - 1 : vMax2 + 1 : EndIf
  While vMin3 < histSize - 1 And crhist(vMin3) <= nSize * s1 / 100 : vMin3 + 1 : Wend
  While vMax3 < histSize And crhist(vMax3) > nSize * (1 - s2 / 100) : vMax3 - 1 : Wend
  If vMax3 < histSize - 1 : vMax3 + 1 : EndIf

  cvCopy(*resize, *balance, #Null)
  ContrastStretching(*resize, *balance, vMin1, vMax1, 0)
  ContrastStretching(*resize, *balance, vMin2, vMax2, 1)
  ContrastStretching(*resize, *balance, vMin3, vMax3, 2)
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
      Dim *bgr_Planes.IplImage(3)

      For rtnCount = 0 To 3 - 1
        *bgr_Planes(rtnCount) = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      Next
      cvSplit(*resize, *bgr_Planes(0), *bgr_Planes(1), *bgr_Planes(2), #Null)
      *normalize.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *image\nChannels)
      cvNormalize(*bgr_Planes(0), *bgr_Planes(0), 0, 255, #CV_MINMAX, #Null)
      cvNormalize(*bgr_Planes(1), *bgr_Planes(1), 0, 255, #CV_MINMAX, #Null)
      cvNormalize(*bgr_Planes(2), *bgr_Planes(2), 0, 255, #CV_MINMAX, #Null)
      cvMerge(*bgr_Planes(0), *bgr_Planes(1), *bgr_Planes(2), #Null, *normalize)
      *balance.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *image\nChannels)
      *reset1.IplImage = cvCloneImage(*normalize)
      *reset2.IplImage = cvCloneImage(*balance)
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
        If *balance
          If nMethod
            Select PIP
              Case 0
                cvSetImageROI(*normalize, 20, 20, iWidth, iHeight)
                cvAndS(*normalize, 0, 0, 0, 0, *normalize, #Null)
                cvAdd(*normalize, *PIP, *normalize, #Null)
                cvResetImageROI(*normalize)
                cvRectangleR(*normalize, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
              Case 1
                cvSetImageROI(*normalize, *normalize\width - (150 + 20), 20, iWidth, iHeight)
                cvAndS(*normalize, 0, 0, 0, 0, *normalize, #Null)
                cvAdd(*normalize, *PIP, *normalize, #Null)
                cvResetImageROI(*normalize)
                cvRectangleR(*normalize, *normalize\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            EndSelect
            cvShowImage(#CV_WINDOW_NAME, *normalize)
          Else
            ColorBalance(*resize, *bgr_Planes(), *balance, nBalance)

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
          EndIf
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              nMethod ! #True
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvReleaseImage(@*normalize)
              *normalize = cvCloneImage(*reset1)
              cvReleaseImage(@*balance)
              *balance = cvCloneImage(*reset2)

              If nMethod : *param\Pointer1 = *normalize : Else : *param\Pointer1 = *balance : EndIf

          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset2)
      cvReleaseImage(@*reset1)
      cvReleaseImage(@*balance)
      cvReleaseImage(@*normalize)

      For rtnCount = 3 - 1 To 0 Step -1
        cvReleaseImage(@*bgr_Planes(rtnCount))
      Next
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
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\