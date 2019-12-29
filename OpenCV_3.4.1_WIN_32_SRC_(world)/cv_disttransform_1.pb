IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the distance to the closest zero pixel for each pixel of the source image." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust the threshold." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Iterate various modes." + #LF$ + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Toggle Voronoi pixel type."

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

    If *resize\width > 200 And *resize\height > 200
      cvCreateTrackbar("Threshold", #CV_WINDOW_NAME, @nThreshold, 254, @CvTrackbarCallback())
      *dist.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 1)
      *dist8u.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)
      *dist8u1.IplImage = cvCloneImage(*resize)
      *dist8u2.IplImage = cvCloneImage(*resize)
      *dist32s.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32S, 1)
      *edge.IplImage = cvCloneImage(*resize)
      *labels.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32S, 1)
      Dim colors(9, 3)
      colors(0, 0) = 0 : colors(0, 1) = 0 : colors(0, 2) = 0
      colors(1, 0) = 255 : colors(1, 1) = 0 : colors(1, 2) = 0
      colors(2, 0) = 255 : colors(2, 1) = 128 : colors(2, 2) = 0
      colors(3, 0) = 255 : colors(3, 1) = 255 : colors(3, 2) = 0
      colors(4, 0) = 0 : colors(4, 1) = 255 : colors(4, 2) = 0
      colors(5, 0) = 0 : colors(5, 1) = 128 : colors(5, 2) = 255
      colors(6, 0) = 0 : colors(6, 1) = 255 : colors(6, 2) = 255
      colors(7, 0) = 0 : colors(7, 1) = 0 : colors(7, 2) = 255
      colors(8, 0) = 255 : colors(8, 1) = 0 : colors(8, 2) = 255
      dist_type = #CV_DIST_C
      mask_size = #CV_DIST_MASK_3
      labeltype = -1
      *ll.LONG : *dd.FLOAT : *d.BYTE
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *dist8u
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *edge
          cvThreshold(*resize, *edge, nThreshold, 255, #CV_THRESH_BINARY)

          If voronoi
            cvDistTransform(*edge, *dist, dist_type, mask_size, #Null, *labels, labeltype)
          Else
            cvDistTransform(*edge, *dist, dist_type, mask_size, #Null, #Null, #CV_DIST_LABEL_CCOMP)
          EndIf

          If voronoi
            For i = 0 To *labels\height - 1
              *ll = @*labels\imageData\b + i * *labels\widthStep
              *dd = @*dist\imageData\b + i * *dist\widthStep
              *d = @*dist8u\imageData\b + i * *dist8u\widthStep

              For j = 0 To *labels\width - 1
                If PeekL(@*ll\l + j * 4) = 0 Or PeekF(@*dd\f + j * 4) = 0
                  idx = 0
                Else
                  idx = (PeekL(@*ll\l + j * 4) - 1) % 8 + 1
                EndIf
                b = colors(idx, 0)
                g = colors(idx, 1)
                r = colors(idx, 2)
                PokeA(@*d\b + j * 3 + 0, b)
                PokeA(@*d\b + j * 3 + 1, g)
                PokeA(@*d\b + j * 3 + 2, r)
              Next
            Next
          Else
            cvConvertScale(*dist, *dist, 5000, 0)
            cvPow(*dist, *dist, 0.5)
            cvConvertScale(*dist, *dist32s, 1, 0.5)
            cvAndS(*dist32s, 255, 255, 255, 0, *dist32s, #Null)
            cvConvertScale(*dist32s, *dist8u1, 1, 0)
            cvConvertScale(*dist32s, *dist32s, -1, 0)
            cvAddS(*dist32s, 255, 255, 255, 0, *dist32s, #Null)
            cvConvertScale(*dist32s, *dist8u2, 1, 0)
            cvMerge(*dist8u1, *dist8u2, *dist8u2, 0, *dist8u)
          EndIf
          cvShowImage(#CV_WINDOW_NAME, *dist8u)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              If voronoi : mask = (mask + 1) % 3 : Else : mask = (mask + 1) % 5 : EndIf

              Select mask
                Case 0
                  dist_type = #CV_DIST_C
                  mask_size = #CV_DIST_MASK_3
                Case 1
                  dist_type = #CV_DIST_L1
                  mask_size = #CV_DIST_MASK_3
                Case 2
                  dist_type = #CV_DIST_L2
                  mask_size = #CV_DIST_MASK_3
                Case 3
                  dist_type = #CV_DIST_L2
                  mask_size = #CV_DIST_MASK_5
                Case 4
                  dist_type = #CV_DIST_L2
                  mask_size = #CV_DIST_MASK_PRECISE
              EndSelect
            Case 86, 118
              labeltype = (labeltype + 1) % 3

              If labeltype = 2
                voronoi = #False
              Else
                voronoi = #True

                If mask > 2
                  mask = 0
                  dist_type = #CV_DIST_C
                  mask_size = #CV_DIST_MASK_3
                EndIf
              EndIf
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*labels)
      cvReleaseImage(@*edge)
      cvReleaseImage(@*dist32s)
      cvReleaseImage(@*dist8u2)
      cvReleaseImage(@*dist8u1)
      cvReleaseImage(@*dist8u)
      cvReleaseImage(@*dist)
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

OpenCV("images/thinning1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\