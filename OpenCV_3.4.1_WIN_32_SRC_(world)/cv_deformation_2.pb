IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nTrackbar

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Deform a grayscale image by manipulating pixel locations." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust deformation." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust angle." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Outline an area to deform." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle deformation." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the image." + #LF$ + #LF$ +
                  "[ X ] KEY   " + #TAB$ + ": Exit selection mode."

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

Global Dim pts.CvPoint(0)

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Static pt1.CvPoint

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      Dim pts.CvPoint(0)
      nTrackbar ! #True
      keybd_event_(#VK_SPACE, 0, 0, 0)
      pt1\x = x
      pt1\y = y
    Case #CV_EVENT_LBUTTONUP
      If ArraySize(pts()) < 40 : keybd_event_(#VK_X, 0, 0, 0) : EndIf

      pt1\x = -1
      pt1\y = -1
    Case #CV_EVENT_MOUSEMOVE
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        pt2.CvPoint : pt2\x = x : pt2\y = y
        cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 0, 0, 0, 0 , 4, #CV_AA, #Null)
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
        arrCount = ArraySize(pts())
        ReDim pts(arrCount + 1)
        pts(arrCount)\x = x
        pts(arrCount)\y = y
        pt1 = pt2
      EndIf
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback1(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

Procedure SetBorder(*image.IplImage, nWidth, nHeight)
  cvLine(*image, 0, 0, nWidth, 0, 0, 0, 0, 0, 2, 8, #Null)
  cvLine(*image, nWidth - 1, 0, nWidth - 1, nHeight, 0, 0, 0, 0, 2, 8, #Null)
  cvLine(*image, nWidth, nHeight - 1, 0, nHeight - 1, 0, 0, 0, 0, 2, 8, #Null)
  cvLine(*image, 0, nHeight, 0, 0, 0, 0, 0, 0, 2, 8, #Null)
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

    If *resize\width > 200 And *resize\height > 200
      cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 20, @CvTrackbarCallback1())
      cvCreateTrackbar("Angle", #CV_WINDOW_NAME, @nAngle, 20, @CvTrackbarCallback2())
      SetBorder(*resize, *resize\width, *resize\height)
      *reset.IplImage = cvCloneImage(*resize)
      *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *input.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_32F, 1))
      *output.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_32F, 1))
      *deform.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 1))
      *draw.CvMat = cvCreateMat(*resize\height, *resize\width, CV_MAKETYPE(#CV_8U, 1))
      Dim pts(4) : pts(0)\x = 0: pts(0)\y = 0 : pts(1)\x = *mask\width : pts(1)\y = 0
      pts(2)\x = *mask\width: pts(2)\y = *mask\height : pts(3)\x = 0 : pts(3)\y = *mask\height
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *draw
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          cvConvert(*resize, *input)

          If nDeform And (keyPressed = 90 Or keyPressed = 122)
            cvSetZero(*mask)
            npts = ArraySize(pts())
            cvFillPoly(*mask, pts(), @npts, 1, 255, 255, 255, 0, #CV_AA, #Null)

            For j = 0 To *mask\height - 1
              For i = 0 To *mask\width - 1
                If PeekA(@*mask\imageData\b + j * *mask\widthStep + i) = 255
                  If nTrackbar
                    xo.d = nDeform * Sin(2 * #PI * i / (nAngle * 4 + 128))
                    yo.d = nDeform * Sin(2 * #PI * j / (nAngle * 4 + 128))
                  Else
                    xo.d = nDeform * Sin(2 * #PI * j / (nAngle * 4 + 128))
                    yo.d = nDeform * Sin(2 * #PI * i / (nAngle * 4 + 128))
                  EndIf
                  maxA = 0 : maxB = i + xo
                  CV_MAX(maxA, maxB)
                  ix = *mask\width - 1
                  CV_MIN(ix, maxA)
                  maxA = 0 : maxB = j + yo
                  CV_MAX(maxA, maxB)
                  iy = *mask\height - 1
                  CV_MIN(iy, maxA)
                  cvmSet(*output, j, i, cvmGet(*input, iy, ix))
                Else
                  cvmSet(*output, j, i, cvmGet(*input, j, i))
                EndIf
              Next
            Next
            cvConvert(*output, *deform)
          Else
            cvConvert(*input, *deform)
          EndIf
          cvCopy(*deform, *draw, #Null)
          cvShowImage(#CV_WINDOW_NAME, *deform)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              nTrackbar = 0
              Dim pts(4) : pts(0)\x = 0: pts(0)\y = 0 : pts(1)\x = *mask\width : pts(1)\y = 0
              pts(2)\x = *mask\width: pts(2)\y = *mask\height : pts(3)\x = 0 : pts(3)\y = *mask\height
              cvSetTrackbarPos("Deform", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Angle", #CV_WINDOW_NAME, 0)
              cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 20, @CvTrackbarCallback1())
              cvReleaseImage(@*resize)
              *resize = cvCloneImage(*reset)
            Case 32
              nTrackbar ! #True
              cvSetTrackbarPos("Deform", #CV_WINDOW_NAME, 0)

              If nTrackbar
                cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 10, @CvTrackbarCallback1())
              Else
                cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 20, @CvTrackbarCallback1())
              EndIf
              SetBorder(*deform, *resize\width, *resize\height)
              cvCopy(*deform, *resize, #Null)
            Case 88, 120
              Dim pts(4) : pts(0)\x = 0: pts(0)\y = 0 : pts(1)\x = *mask\width : pts(1)\y = 0
              pts(2)\x = *mask\width: pts(2)\y = *mask\height : pts(3)\x = 0 : pts(3)\y = *mask\height
              cvSetTrackbarPos("Deform", #CV_WINDOW_NAME, 0)

              If nTrackbar
                cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 10, @CvTrackbarCallback1())
              Else
                cvCreateTrackbar("Deform", #CV_WINDOW_NAME, @nDeform, 20, @CvTrackbarCallback1())
              EndIf
              SetBorder(*deform, *resize\width, *resize\height)
              cvCopy(*deform, *resize, #Null)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseMat(@*draw)
      cvReleaseMat(@*deform)
      cvReleaseMat(@*output)
      cvReleaseMat(@*input)
      cvReleaseImage(@*mask)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        nTrackbar = 0
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

OpenCV("images/weight3.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\