IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nFlag, nAnchor, Dim srcPoint.CvPoint2D32f(4), Dim dstPoint.CvPoint2D32f(4)

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates a perspective transform from four pairs of corresponding points." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Modify warp dimensions." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle control anchors." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset warp dimensions." + #LF$ + #LF$ +
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

Procedure InRectangle(pX, pY, tlX, tlY, brX, brY)
 If pX >= tlX And pX <= brX And pY >= tlY And pY <= brY : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
EndProcedure

Procedure SetDimensions(width, height)
  srcPoint(0)\x = 0
  srcPoint(0)\y = 0
  srcPoint(1)\x = width - 1
  srcPoint(1)\y = 0
  srcPoint(2)\x = 0
  srcPoint(2)\y = height - 1
  srcPoint(3)\x = width - 1
  srcPoint(3)\y = height - 1
  dstPoint(0)\x = width * 0.05
  dstPoint(0)\y = height * 0.33
  dstPoint(1)\x = width * 0.9
  dstPoint(1)\y = height * 0.25
  dstPoint(2)\x = width * 0.2
  dstPoint(2)\y = height * 0.7
  dstPoint(3)\x = width * 0.8
  dstPoint(3)\y = height * 0.9
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      *save = *param\Pointer1
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      If nAnchor
        nFlag = -1

        For rtnCount = 0 To 4 - 1
          If InRectangle(x, y, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5)
            nFlag = rtnCount
            Break
          EndIf
        Next
      EndIf
    Case #CV_EVENT_MOUSEMOVE
      If nFlag <> -1 And Bool(flags & #CV_EVENT_FLAG_LBUTTON)
        nAnchor = 0
        dstPoint(nFlag)\x = x
        dstPoint(nFlag)\y = y
        keybd_event_(#VK_SPACE, 0, 0, 0)
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

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      nFlag = -1 : nAnchor = 1
      *warp.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
      *matrix.IplImage = cvCloneImage(*resize)
      *reset.IplImage = cvCloneImage(*resize)
      keybd_event_(#VK_RETURN, 0, 0, 0)
      iRatio.d = 150 / *resize\width
      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
      cvResize(*image, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *matrix
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *matrix
          Select PIP
            Case 0
              cvSetImageROI(*matrix, 20, 20, iWidth, iHeight)
              cvAndS(*matrix, 0, 0, 0, 0, *matrix, #Null)
              cvAdd(*matrix, *PIP, *matrix, #Null)
              cvResetImageROI(*matrix)
              cvRectangleR(*matrix, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*matrix, *matrix\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*matrix, 0, 0, 0, 0, *matrix, #Null)
              cvAdd(*matrix, *PIP, *matrix, #Null)
              cvResetImageROI(*matrix)
              cvRectangleR(*matrix, *matrix\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect
          cvShowImage(#CV_WINDOW_NAME, *matrix)
          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 13
              nFlag = -1 : nAnchor = 1
              SetDimensions(*resize\width, *resize\height)
              cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *warp)
              cvWarpPerspective(*resize, *matrix, *warp, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)

              For rtnCount = 0 To 4 - 1
                cvRectangle(*matrix, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
              Next
            Case 32
              nAnchor ! #True
              cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *warp)
              cvWarpPerspective(*resize, *matrix, *warp, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)

              If nAnchor
                For rtnCount = 0 To 4 - 1
                  cvRectangle(*matrix, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
                Next
              EndIf
            Case 86, 118
              PIP = (PIP + 1) % 3
              cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *warp)
              cvWarpPerspective(*resize, *matrix, *warp, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 0, 0, 0, 0)

              If nAnchor
                For rtnCount = 0 To 4 - 1
                  cvRectangle(*matrix, dstPoint(rtnCount)\x - 5, dstPoint(rtnCount)\y - 5, dstPoint(rtnCount)\x + 5, dstPoint(rtnCount)\y + 5, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
                Next
              EndIf
              *param\Pointer1 = *matrix
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*matrix)
      cvReleaseMat(@*warp)
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

OpenCV("images/rubix.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\