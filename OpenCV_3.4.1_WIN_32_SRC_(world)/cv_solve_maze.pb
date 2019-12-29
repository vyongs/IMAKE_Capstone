IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, Dim *clear.IplImage(1), nMaze

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Maze game / solve a maze using a morphological transformation." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Manually solve the maze." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Show solution in stages." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch between mazes." + #LF$ + #LF$ +
                  "[ C ] KEY   " + #TAB$ + ": Clear to last point / Reset." + #LF$ + #LF$ +
                  "Perfect Maze: Only one path from any point to any other point, no sections, no circular paths, and no open areas." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage to a Maze Generator."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
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
      If *param\Message = #Null$
        cvCircle(*param\Pointer1, x, y, 8, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
        cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
        pt1\x = x
        pt1\y = y
      EndIf
    Case #CV_EVENT_LBUTTONUP
      pt1\x = -1
      pt1\y = -1
      nCount = ArraySize(*clear()) + 1
      ReDim *clear(nCount)
      *clear(nCount - 1) = cvCloneImage(*param\Pointer1)
    Case #CV_EVENT_MOUSEMOVE
      If Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        If *param\Message = #Null$
          pt2.CvPoint : pt2\x = x : pt2\y = y
          cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 255, 0, 0, 0, 4, #CV_AA, #Null)
          cvShowImage(#CV_WINDOW_NAME, *param\Pointer1)
          pt1 = pt2
        EndIf
      EndIf
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://mazegenerator.net/")
  EndSelect
EndProcedure

Procedure OpenCV(ImageFile.s)
  If FileSize(ImageFile) > 0
    cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
    window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
    *window_name = cvGetWindowName(window_handle)
    lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

    If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
      MenuItem(1, "Save")
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
    *clear(0) = cvCloneImage(*resize)
    *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
    cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
    BringWindowToTop(hWnd)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *resize
    *param\Message = #Null$
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *resize
        cvShowImage(#CV_WINDOW_NAME, *resize)
        keyPressed = cvWaitKey(0)

        If keyPressed = 67 Or keyPressed = 99
          nCount = ArraySize(*clear()) - 1

          If nCount > 0
            ReDim *clear(nCount)
            cvReleaseImage(@*resize)
            *resize = cvCloneImage(*clear(nCount - 1))
            *param\Pointer1 = *resize
          EndIf
        EndIf
      EndIf
    Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

    If keyPressed = 32
      cvThreshold(*gray, *gray, 100, 255, #CV_THRESH_BINARY_INV)
      *storage.CvMemStorage = cvCreateMemStorage(0)
      cvClearMemStorage(*storage)
      *contours.CvSeq
      nContours = cvFindContours(*gray, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

      If nContours = 2
        *path.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1) : cvSetZero(*path)
        *erode.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1) : cvSetZero(*erode)
        Dim *channel.IplImage(3)

        For rtnCount = 0 To 3 - 1
          *channel(rtnCount) = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1) : cvSetZero(*channel(rtnCount))
        Next
        *maze.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3) : cvSetZero(*maze)
        *kernel.IplConvKernel = cvCreateStructuringElementEx(19, 19, 9, 9, #CV_SHAPE_RECT, 1)
        cvDrawContours(*path, *contours, 255, 255, 255, 0, 255, 255, 255, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
        *param\Pointer1 = *path
        *param\Message = "X"

        If keyPressed = 32
          Repeat
            If *path
              cvShowImage(#CV_WINDOW_NAME, *path)
              keyPressed = cvWaitKey(0)
            EndIf
          Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV
        EndIf

        If keyPressed = 32
          cvDilate(*path, *path, *kernel, 1)
          cvErode(*path, *erode, *kernel, 1)
          cvAbsDiff(*path, *erode, *path)
          *param\Pointer1 = *erode

          Repeat
            If *erode
              cvShowImage(#CV_WINDOW_NAME, *erode)
              keyPressed = cvWaitKey(0)
            EndIf
          Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV
        EndIf

        If keyPressed = 32
          cvSplit(*resize, *channel(0), *channel(1), *channel(2), #Null)
          cvXor(*path, *channel(0), *channel(0), #Null)
          cvXor(*path, *channel(1), *channel(1), #Null)
          cvMerge(*channel(0), *channel(1), *channel(2), #Null, *maze)
          *param\Pointer1 = *path

          Repeat
            If *path
              cvShowImage(#CV_WINDOW_NAME, *path)
              keyPressed = cvWaitKey(0)
            EndIf
          Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV
        EndIf

        If keyPressed = 32
          BringWindowToTop(hWnd)
          *param\Pointer1 = *maze

          Repeat
            If *maze
              cvShowImage(#CV_WINDOW_NAME, *maze)
              keyPressed = cvWaitKey(0)
            EndIf
          Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 67 Or keyPressed = 99 Or exitCV
        EndIf
        cvReleaseStructuringElement(@*kernel)
        cvReleaseImage(@*maze)

        For rtnCount = 0 To 3 - 1
          cvReleaseImage(@*channel(rtnCount))
        Next
        cvReleaseImage(@*erode)
        cvReleaseImage(@*path)
        FreeMemory(*param)
      EndIf
      cvReleaseMemStorage(@*storage)
    EndIf
    cvReleaseImage(@*gray)

    For rtnCount = 0 To ArraySize(*clear()) - 1
      cvReleaseImage(@*clear(rtnCount))
    Next
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If keyPressed = 13 Or keyPressed = 67 Or keyPressed = 99
      exitCV = #False
      Dim *clear.IplImage(1)

      If keyPressed = 13 : nMaze = (nMaze + 1) % 3 : EndIf

      OpenCV("images/maze" + Str(nMaze + 1) + ".jpg")
    EndIf
  EndIf
EndProcedure

OpenCV("images/maze1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\