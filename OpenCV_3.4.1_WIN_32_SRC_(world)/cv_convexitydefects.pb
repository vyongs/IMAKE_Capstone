IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, nHand

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the contour areas, finding the convex hull of point sets to convexity defects." + #LF$ + #LF$ +
                  "START       " + #TAB$ + ": Green." + #LF$ +
                  "END         " + #TAB$ + ": Red." + #LF$ +
                  "DEPTH       " + #TAB$ + ": Blue." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between views." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch between images."

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
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
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

    If *resize\nChannels = 1
      *gray.IplImage = cvCloneImage(*resize)
    Else
      *gray.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
      cvCvtColor(*resize, *gray, #CV_BGR2GRAY, 1)
    EndIf
    cvThreshold(*gray, *gray, 30, 255, #CV_THRESH_BINARY_INV | #CV_THRESH_OTSU)
    *storage.CvMemStorage = cvCreateMemStorage(0) : cvClearMemStorage(*storage) : *contours.CvSeq
    nContours = cvFindContours(*gray, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

    If nContours
      *contour.IplImage = cvCreateImage(*gray\width, *gray\height, #IPL_DEPTH_8U, 3) : cvSetZero(*contour)
      *hull.CvSeq : *defect.CvSeq

      For rtnCount = 0 To nContours - 1
        area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

        If area > 100000
          cvDrawContours(*contour, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
          *hull.CvSeq = cvConvexHull2(*contours, #Null, #CV_CLOCKWISE, #False)
          *defect = cvConvexityDefects(*contours, *hull, #Null)
          Dim elements.CvConvexityDefect(*defect\total) : Dim pts.CvPoint(0)
          cvCvtSeqToArray(*defect, @elements(), 0, #CV_WHOLE_SEQ_END_INDEX)

          For rtnDefect = 0 To *defect\total - 1
            If elements(rtnDefect)\depth > 15
              startX = elements(rtnDefect)\start\x : startY = elements(rtnDefect)\start\y
              endX = elements(rtnDefect)\end\x : endY = elements(rtnDefect)\end\y
              depth_pointX = elements(rtnDefect)\depth_point\x : depth_pointY = elements(rtnDefect)\depth_point\y
              cvCircle(*resize, startX, startY, 5, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
              cvCircle(*resize, endX, endY, 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
              cvCircle(*resize, depth_pointX, depth_pointY, 5, 255, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
              arrCount = ArraySize(pts())
              ReDim pts(arrCount + 3)
              pts(arrCount)\x = startX : pts(arrCount)\y = startY
              pts(arrCount + 1)\x = depth_pointX : pts(arrCount + 1)\y = depth_pointY
              pts(arrCount + 2)\x = endX : pts(arrCount + 2)\y = endY
              count + 1
            EndIf
          Next
          npts = ArraySize(pts())
          cvPolyLine(*resize, pts(), @npts, 1, #True, 0, 0, 0, 0, 2, #CV_AA, #Null)
        EndIf
        *contours = *contours\h_next
      Next
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
      cvPutText(*resize, "Fingers: " + Str(count - 1), 10, 30, @font, 255, 0, 0, 0)
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          Select view
            Case 0
              *param\Pointer1 = *resize
              cvShowImage(#CV_WINDOW_NAME, *resize)
            Case 1
              *param\Pointer1 = *gray
              cvShowImage(#CV_WINDOW_NAME, *gray)
            Case 2
              *param\Pointer1 = *contour
              cvShowImage(#CV_WINDOW_NAME, *contour)
          EndSelect
          keyPressed = cvWaitKey(0)

          If keyPressed = 32 : view = (view + 1) % 3 : EndIf

        EndIf
      Until keyPressed = 13 Or keyPressed = 27 Or exitCV
      FreeMemory(*param)
    EndIf
    cvReleaseMemStorage(@*storage)
    cvReleaseImage(@*contour)
    cvReleaseImage(@*gray)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If keyPressed = 13
      exitCV = #False
      nHand = (nHand + 1) % 3
      OpenCV("images/hand" + Str(nHand + 1) + ".jpg")
    EndIf
  EndIf
EndProcedure

OpenCV("images/hand1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\