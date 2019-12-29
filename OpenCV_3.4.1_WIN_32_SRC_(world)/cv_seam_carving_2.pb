IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, select_object, hWnd_seams, *seams.IplImage, nSeams

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Deleting vertical seams in an image by calculating the intensity of grayscale pixels (experimental)." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust seam spacing." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Highlight / Select area." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Seam carving / Resize." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch to next image." + #LF$ + #LF$ +
                  "[ A ] KEY   " + #TAB$ + ": Set Sobel aperture size." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Set Sobel X / Y order." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
      SendMessage_(hWnd_seams, #WM_CLOSE, 0, 0)
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Shared selection.CvRect
  Shared origin.CvPoint

  If select_object > 0 And *param\Pointer2
    *select.IplImage
    cvReleaseImage(@*select)
    *select = cvCloneImage(*param\Pointer2)
    selection\x = origin\x
    selection\y = origin\y
    CV_MIN(selection\x, x)
    CV_MIN(selection\y, y)
    selection\width = selection\x + CV_IABS(x - origin\x)
    selection\height = selection\y + CV_IABS(y - origin\y)
    CV_MAX(selection\x, 0)
    CV_MAX(selection\y, 0)
    CV_MIN(selection\width, *select\width)
    CV_MIN(selection\height, *select\height)
    selection\width - selection\x
    selection\height - selection\y
  EndIf

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *seams
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      If *param\Pointer2
        origin\x = x
        origin\y = y
        selection\x = x
        selection\y = y
        selection\width = 0
        selection\height = 0
        select_object = 1
      EndIf
    Case #CV_EVENT_LBUTTONUP
      If *param\Pointer2 : select_object = -1 : EndIf
    Case #CV_EVENT_MOUSEMOVE
      Select select_object
        Case 0
          selection\x = 0
          selection\y = 0
          selection\width = 0
          selection\height = 0
        Case -1
          opacity.d = 0.4
          *select.IplImage = cvCloneImage(*param\Pointer2)
          cvRectangle(*select, selection\x, 0, selection\x + selection\width, *select\height, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
          cvRectangle(*param\Pointer2, selection\x, 0, selection\x + selection\width, *param\Pointer2\height, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
          cvAddWeighted(*select, opacity, *param\Pointer1, 1 - opacity, 0, *select)
          cvShowImage(#CV_WINDOW_NAME, *select)
          cvReleaseImage(@*select)
          select_object = 0
        Case 1
          opacity.d = 0.4

          If selection\x = 0 : selection\x = 2 : EndIf
          If selection\x + selection\width >= *select\width : selection\width - 3 : EndIf
          If selection\y = 0 : selection\y = 2 : EndIf
          If selection\y + selection\height >= *select\height : selection\height - 3 : EndIf

          cvSetImageROI(*select, selection\x, selection\y, selection\width, selection\height)
          cvXorS(*select, 255, 0, 255, 0, *select, #Null)
          cvResetImageROI(*select)
          cvAddWeighted(*select, opacity, *param\Pointer1, 1 - opacity, 0, *select)
          cvRectangle(*select, selection\x, selection\y, selection\x + selection\width, selection\y + selection\height, 255, 0, 0, 0, 1, #CV_AA, #Null)
          cvShowImage(#CV_WINDOW_NAME, *select)
          cvReleaseImage(@*select)
      EndSelect
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://www.faculty.idc.ac.il/arik/SCWeb/imret/index.html")
  EndSelect
EndProcedure

ProcedureC CvTrackbarCallback(pos) : EndProcedure

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

    If *image\width * 2 >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / (*image\width * 2)
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
      cvCreateTrackbar("Spacing", #CV_WINDOW_NAME, @nSpacing, 10, @CvTrackbarCallback())
      cvNamedWindow(#CV_WINDOW_NAME + " - Seam Carving", #CV_WINDOW_AUTOSIZE)
      hWnd_seams = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Seam Carving"))
      SendMessage_(hWnd_seams, #WM_SETICON, 0, opencv)
      wStyle = GetWindowLongPtr_(hWnd_seams, #GWL_STYLE)
      SetWindowLongPtr_(hWnd_seams, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
      cvResizeWindow(#CV_WINDOW_NAME + " - Seam Carving", *resize\width, *resize\height)
      cvMoveWindow(#CV_WINDOW_NAME + " - Seam Carving", *resize\width + 50, 20)
      *seams = cvCloneImage(*resize)
      *select.IplImage = cvCloneImage(*resize)
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      *edge.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
      cvLaplace(*gray, *gray, 1)
      nAperture = 1
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Pointer2 = *select
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
      cvShowImage(#CV_WINDOW_NAME, *resize)

      Repeat
        If sobel
          Select sobel
            Case 1
              cvSobel(*gray, *edge, 1, 1, nAperture)
            Case 2
              cvSobel(*gray, *edge, 1, 0, nAperture)
            Case 3
              cvSobel(*gray, *edge, 0, 1, nAperture)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME + " - Seam Carving", *edge)
        Else
          cvSobel(*gray, *edge, 1, 0, 5)
          cvShowImage(#CV_WINDOW_NAME + " - Seam Carving", *seams)
        EndIf
        keyPressed = cvWaitKey(0)

        Select keyPressed
          Case 32
            cvShowImage(#CV_WINDOW_NAME, *resize)
          Case 65, 97
            If Not sobel : sobel = 1 : EndIf
            If sobel = 1 And aperture = 0 : aperture = 2 : Else : aperture = (aperture + 1) % 4 : EndIf

            Select aperture
              Case 0
                nAperture = 1
              Case 1
                nAperture = 3
              Case 2
                nAperture = 5
              Case 3
                nAperture = 7
            EndSelect
          Case 83, 115
            sobel = (sobel + 1) % 4
        EndSelect
      Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

      If keyPressed = 32
        Dim xRemove(*resize\height)
        *clone.IplImage = cvCloneImage(*resize)

        For i = *resize\width - 1 To 0 Step -2
          iPosition = i
          B = PeekA(@*select\imageData\b + iPosition * 3 + 0)
          G = PeekA(@*select\imageData\b + iPosition * 3 + 1)
          R = PeekA(@*select\imageData\b + iPosition * 3 + 2)

          If B = 0 And G = 255 And R = 0 : Continue : Else : color + 1 : EndIf

          For j = 0 To *resize\height - 1
            If iPosition + 1 > *resize\width - 1
              intensity_1 = 256
            Else
              B = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition + 1) * 3 + 0)
              G = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition + 1) * 3 + 1)
              R = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition + 1) * 3 + 2)

              If B = 0 And G = 255 And R = 0
                intensity_1 = 256
              Else
                intensity_1 = PeekA(@*edge\imageData\b + (j * *edge\widthStep) + iPosition + 1)
              EndIf
            EndIf
            B = PeekA(@*select\imageData\b + (j * *select\widthStep) + iPosition * 3 + 0)
            G = PeekA(@*select\imageData\b + (j * *select\widthStep) + iPosition * 3 + 1)
            R = PeekA(@*select\imageData\b + (j * *select\widthStep) + iPosition * 3 + 2)

            If B = 0 And G = 255 And R = 0
              intensity_2 = 256
            Else
              intensity_2 = PeekA(@*edge\imageData\b + (j * *edge\widthStep) + iPosition)
            EndIf

            If iPosition - 1 < 0
              intensity_3 = 256
            Else
              B = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition - 1) * 3 + 0)
              G = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition - 1) * 3 + 1)
              R = PeekA(@*select\imageData\b + (j * *select\widthStep) + (iPosition - 1) * 3 + 2)

              If B = 0 And G = 255 And R = 0
                intensity_3 = 256
              Else
                intensity_3 = PeekA(@*edge\imageData\b + (j * *edge\widthStep) + iPosition - 1)
              EndIf
            EndIf

            If intensity_1 < intensity_2
              If intensity_1 < intensity_3 : iPosition + 1 : Else : iPosition - 1 : EndIf
            Else
              If intensity_3 < intensity_2 : iPosition - 1 : EndIf
            EndIf
            xRemove(j) = iPosition
            PokeA(@*resize\imageData\b + (j * *resize\widthStep) + (iPosition * 3) + 0, 0)
            PokeA(@*resize\imageData\b + (j * *resize\widthStep) + (iPosition * 3) + 1, 0)
            PokeA(@*resize\imageData\b + (j * *resize\widthStep) + (iPosition * 3) + 2, nColor)
          Next
          cvReleaseImage(@*seams)
          *seams = cvCreateImage(*edge\width - 1, *edge\height, #IPL_DEPTH_8U, 3)
          cvWaitKey(1)

          For y = 0 To *edge\height - 1
            For x = 0 To *edge\width - 1
              If x = xRemove(y)
                Continue
              Else
                If x > xRemove(y) : xAdjustment = x - 1 : Else : xAdjustment = x : EndIf

                B = PeekA(@*clone\imageData\b + (y * *clone\widthStep) + (x * 3) + 0)
                G = PeekA(@*clone\imageData\b + (y * *clone\widthStep) + (x * 3) + 1)
                R = PeekA(@*clone\imageData\b + (y * *clone\widthStep) + (x * 3) + 2)
                PokeA(@*seams\imageData\b + (y * *seams\widthStep) + (xAdjustment * 3) + 0, B)
                PokeA(@*seams\imageData\b + (y * *seams\widthStep) + (xAdjustment * 3) + 1, G)
                PokeA(@*seams\imageData\b + (y * *seams\widthStep) + (xAdjustment * 3) + 2, R)
                B = PeekA(@*select\imageData\b + (y * *select\widthStep) + (x * 3) + 0)
                G = PeekA(@*select\imageData\b + (y * *select\widthStep) + (x * 3) + 1)
                R = PeekA(@*select\imageData\b + (y * *select\widthStep) + (x * 3) + 2)
                PokeA(@*select\imageData\b + (y * *select\widthStep) + (xAdjustment * 3) + 0, B)
                PokeA(@*select\imageData\b + (y * *select\widthStep) + (xAdjustment * 3) + 1, G)
                PokeA(@*select\imageData\b + (y * *select\widthStep) + (xAdjustment * 3) + 2, R)
              EndIf
            Next
          Next
          cvShowImage(#CV_WINDOW_NAME, *resize)
          cvShowImage(#CV_WINDOW_NAME + " - Seam Carving", *seams)
          keyPressed = cvWaitKey(20)

          If keyPressed = 13 Or keyPressed = 27 Or exitCV : Break : EndIf

          cvReleaseImage(@*edge)
          cvReleaseImage(@*gray)
          cvReleaseImage(@*clone)
          *edge = cvCreateImage(*seams\width, *seams\height, #IPL_DEPTH_8U, 1)
          *gray = cvCreateImage(*seams\width, *seams\height, #IPL_DEPTH_8U, 1)
          *clone = cvCloneImage(*seams)
          cvCvtColor(*seams, *gray, #CV_BGR2GRAY, 1)
          cvLaplace(*gray, *gray, 1)

          Select sobel
            Case 0
              cvSobel(*gray, *edge, 1, 0, 5)
            Case 1
              cvSobel(*gray, *edge, 1, 1, nAperture)
            Case 2
              cvSobel(*gray, *edge, 1, 0, nAperture)
            Case 3
              cvSobel(*gray, *edge, 0, 1, nAperture)
          EndSelect

          If nSpacing > 0 : i - (nSpacing + 1) : EndIf
          If color % 2 : nColor = 0 : Else : nColor = 255 : EndIf

        Next

        If keyPressed <> 13 And keyPressed <> 27 And exitCV = #False
          *param\Pointer2 = #Null

          Repeat
            If *seams
              cvShowImage(#CV_WINDOW_NAME, *resize)
              cvShowImage(#CV_WINDOW_NAME + " - Seam Carving", *seams)
              keyPressed = cvWaitKey(0)

              If keyPressed = 32
                If *seams\width < *resize\width
                  iRatio.d = *resize\width / *seams\width
                  *temp.IplImage = cvCloneImage(*seams)
                  cvReleaseImage(@*seams)
                  *seams = cvCreateImage(*resize\width, *resize\height * iRatio, #IPL_DEPTH_8U, *resize\nChannels)
                  cvResize(*temp, *seams, #CV_INTER_CUBIC)
                  cvReleaseImage(@*temp)
                EndIf
              EndIf
            EndIf
          Until keyPressed = 13 Or keyPressed = 27 Or exitCV
        EndIf
        cvReleaseImage(@*clone)
      EndIf
      FreeMemory(*param)
      cvReleaseImage(@*edge)
      cvReleaseImage(@*gray)
      cvReleaseImage(@*select)
      cvReleaseImage(@*seams)
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If keyPressed = 13
        exitCV = #False
        nSeams = (nSeams + 1) % 2
        OpenCV("images/seams" + Str(nSeams + 1) + ".jpg")
      ElseIf openCV
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

OpenCV("images/seams1.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\