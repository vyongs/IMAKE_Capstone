IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nB, nG, nR, nSize

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Utilizing OpenCV's mouse callback, adds the ability to doodle on the loaded image." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Doodle on the image." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between colors." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the image." + #LF$ + #LF$ +
                  "[ < ] KEY   " + #TAB$ + ": Adjust thickness smaller." + #LF$ +
                  "[ > ] KEY   " + #TAB$ + ": Adjust thickness larger."

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
  Static pt1.CvPoint

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      pt1\x = x
      pt1\y = y
    Case #CV_EVENT_LBUTTONUP
      pt1\x = -1
      pt1\y = -1
    Case #CV_EVENT_MOUSEMOVE
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        If pt1\x > 0 Or pt1\y > 0
          pt2.CvPoint : pt2\x = x : pt2\y = y
          cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, nB, nG, nR, 0 , nSize, #CV_AA, #Null)
          cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
          pt1 = pt2
        EndIf
      EndIf
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
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\nChannels = 3
      nB = 0 : nG = 0 : nR = 255 : size = 1 : nSize = 4
      cvCircle(*resize, 25, 25, 20, nB, nG, nR, 0, #CV_FILLED, #CV_AA, #Null)
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_DUPLEX, 1, 1, #Null, 1, #CV_AA)
      cvPutText(*resize, "1", 15, 35, @font, 0, 0, 0, 0)
      *reset.IplImage = cvCloneImage(*resize)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          cvShowImage(#CV_WINDOW_NAME, *resize)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              cvCopy(*reset, *resize, #Null)
              cvCircle(*resize, 25, 25, 20, nB, nG, nR, 0, #CV_FILLED, #CV_AA, #Null)
              cvPutText(*resize, Str(size), 15, 35, @font, 0, 0, 0, 0)
            Case 32
              Select color % 3
                Case 0
                  nB = 0
                  nG = 255
                  nR = 0
                Case 1
                  nB = 255
                  nG = 0
                  nR = 0
                Case 2
                  nB = 0
                  nG = 0
                  nR = 255
              EndSelect
              color + 1
              cvCircle(*resize, 25, 25, 20, nB, nG, nR, 0, #CV_FILLED, #CV_AA, #Null)
              cvPutText(*resize, Str(size), 15, 35, @font, 0, 0, 0, 0)
            Case 44, 60
              If size > 2 : size - 1 : nSize = size * 10 : Else : size = 1 : nSize = 4 : EndIf

              cvCircle(*resize, 25, 25, 20, nB, nG, nR, 0, #CV_FILLED, #CV_AA, #Null)
              cvPutText(*resize, Str(size), 15, 35, @font, 0, 0, 0, 0)
            Case 46, 62
              If size < 5 : size + 1 : nSize = size * 10 : EndIf

              cvCircle(*resize, 25, 25, 20, nB, nG, nR, 0, #CV_FILLED, #CV_AA, #Null)
              cvPutText(*resize, Str(size), 15, 35, @font, 0, 0, 0, 0)
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*reset)
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

OpenCV("images/nebula.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\