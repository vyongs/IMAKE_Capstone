IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Tries to detect frontal-faces of different sizes using HaarCascades." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust scale factor." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Minimum neighbors." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Change HaarCascade." + #LF$ + #LF$ +
                  "[ M ] KEY   " + #TAB$ + ": Switch between masks." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Toggle scale-factor flag."

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
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

Procedure SetMask(*frame.IplImage, mask.s, x, y, width, height)
  *image.IplImage = cvLoadImage(mask, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *resize.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 3)
  *mask.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  Dim *resizeChannel.IplImage(3)
  *resizeChannel(0) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *resizeChannel(1) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *resizeChannel(2) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  Dim *maskResult.IplImage(3)
  *maskResult(0) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *maskResult(1) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *maskResult(2) = cvCreateImage(width, height, #IPL_DEPTH_8U, 1)
  *merge.IplImage = cvCreateImage(width, height, #IPL_DEPTH_8U, 3)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  cvResize(*image, *resize, #CV_INTER_AREA)
  cvCvtColor(*resize, *mask, #CV_BGR2GRAY, 1)
  cvErode(*mask, *mask, *kernel, 1)
  cvDilate(*mask, *mask, *kernel, 3)
  cvSmooth(*mask, *mask, #CV_GAUSSIAN, 7, 7, 0, 0)
  cvThreshold(*mask, *mask, 240, 255, #CV_THRESH_BINARY_INV)
  cvSplit(*resize, *resizeChannel(0), *resizeChannel(1), *resizeChannel(2), #Null)
  cvAnd(*resizeChannel(0), *mask, *maskResult(0), #Null)
  cvAnd(*resizeChannel(1), *mask, *maskResult(1), #Null)
  cvAnd(*resizeChannel(2), *mask, *maskResult(2), #Null)
  cvMerge(*maskResult(0), *maskResult(1), *maskResult(2), #Null, *merge)
  cvSetImageROI(*frame, x, y, width, height)
  cvCopy(*merge, *frame, *mask)
  cvResetImageROI(*frame)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*merge)
  cvReleaseImage(@*maskResult(2))
  cvReleaseImage(@*maskResult(1))
  cvReleaseImage(@*maskResult(0))
  cvReleaseImage(@*resizeChannel(2))
  cvReleaseImage(@*resizeChannel(1))
  cvReleaseImage(@*resizeChannel(0))
  cvReleaseImage(@*mask)
  cvReleaseImage(@*resize)
  cvReleaseImage(@*image)
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
      *resize1.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize1, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48 + 42)
      *resize1.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize1\width > 200 And *resize1\height > 200 And *resize1\nChannels = 3
      nScaleFactor = 4 : nMinNeighbors = 1
      cvCreateTrackbar("Scale", #CV_WINDOW_NAME, @nScaleFactor, 9, @CvTrackbarCallback1())
      cvCreateTrackbar("Neighbors", #CV_WINDOW_NAME, @nMinNeighbors, 4, @CvTrackbarCallback2())
      Dim haarcascade.s(4)
      haarcascade(0) = "haarcascade_frontalface_default.xml"
      haarcascade(1) = "haarcascade_frontalface_alt.xml"
      haarcascade(2) = "haarcascade_frontalface_alt2.xml"
      haarcascade(3) = "haarcascade_frontalface_alt_tree.xml"
      haarcascade(4) = "haarcascade_frontalface_JHPJHP.xml"
      faceOld = -1 : scale = 2
      iWidth = Round(*resize1\width / scale, #PB_Round_Nearest)
      iHeight = Round(*resize1\height / scale, #PB_Round_Nearest)
      *gray.IplImage = cvCreateImage(*resize1\width, *resize1\height, #IPL_DEPTH_8U, 1)
      *resize2.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize1, *gray, #CV_BGR2GRAY, 1)
      cvEqualizeHist(*gray, *gray)
      cvResize(*gray, *resize2, #CV_INTER_AREA)
      *reset1.IplImage = cvCloneImage(*resize1)
      *reset2.IplImage = cvCloneImage(*resize2)
      *cascade.CvHaarClassifierCascade = cvLoad(haarcascade(face), #Null, #Null, #Null)
      *storage.CvMemStorage = cvCreateMemStorage(0)
      *faces.CvSeq
      *element.CvRect
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize1
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize1
          cvClearMemStorage(*storage)
          *faces = cvHaarDetectObjects(*resize2, *cascade, *storage, 1 + ((nScaleFactor + 1) / 10), nMinNeighbors, flags + 1, 0, 0, 0, 0)

          For rtnPoint = 0 To *faces\total - 1
            *element = cvGetSeqElem(*faces, rtnPoint)

            If *element
              x = *element\x * scale
              y = *element\y * scale
              width = (*element\x + *element\width) * scale
              height = (*element\y + *element\height) * scale

              If face <> faceOld
                Select mask
                  Case 0
                    Select face
                      Case 0
                        cvRectangle(*resize1, x, y, width, height, 0, 255, 255, 0, 2, #CV_AA, #Null)
                      Case 1
                        cvRectangle(*resize1, x, y, width, height, 255, 0, 0, 0, 2, #CV_AA, #Null)
                      Case 2
                        cvRectangle(*resize1, x, y, width, height, 0, 255, 0, 0, 2, #CV_AA, #Null)
                      Case 3
                        cvRectangle(*resize1, x, y, width, height, 0, 0, 255, 0, 2, #CV_AA, #Null)
                      Case 4
                        cvRectangle(*resize1, x, y, width, height, 255, 255, 0, 0, 2, #CV_AA, #Null)
                    EndSelect
                  Case 1 To 4
                  SetMask(*resize1, "images/mask" + Str(mask) + ".jpg", x, y, Abs(width - x), Abs(height - y))
                EndSelect
              EndIf
            EndIf
          Next
          cvShowImage(#CV_WINDOW_NAME, *resize1)
          keyPressed = cvWaitKey(0)

          If face <> faceOld : faceOld = face : EndIf

          If keyPressed = 13 Or keyPressed = 32 Or keyPressed = 77 Or keyPressed = 109 Or keyPressed = 83 Or keyPressed = 115
            Select keyPressed
              Case 32
                face = (face + 1) % 5

                If FileSize(haarcascade(face)) = -1 : face = (face + 1) % 5 : EndIf

                *cascade = cvLoad(haarcascade(face), #Null, #Null, #Null)
              Case 77, 109
                mask = (mask + 1) % 5
              Case 83, 115
                flags ! #True
            EndSelect
            faceOld = -1
            cvReleaseImage(@*resize1)
            cvReleaseImage(@*resize2)
            *resize1 = cvCloneImage(*reset1)
            *resize2 = cvCloneImage(*reset2)
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseMemStorage(@*storage)
      cvReleaseHaarClassifierCascade(@*cascade)
      cvReleaseImage(@*resize2)
      cvReleaseImage(@*gray)
      cvReleaseImage(@*resize1)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If openCV
        openCV = #False
        exitCV = #False
        OpenCV(OpenCVImage())
      EndIf
    Else
      If *resize1\nChannels = 3
        MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the size requirements, please try another image.", #MB_ICONERROR)
      Else
        MessageRequester(#CV_WINDOW_NAME, ImageFile + #LF$ + #LF$ + "... does not meet the channel requirements, please try another image.", #MB_ICONERROR)
      EndIf
      cvReleaseImage(@*resize1)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/faces.jpg")
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\