IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Add or subtract every array element of an image." + #LF$ + #LF$ +
                  "TRACKBAR 1  " + #TAB$ + ": Adjust Red value." + #LF$ +
                  "TRACKBAR 2  " + #TAB$ + ": Adjust Green value." + #LF$ +
                  "TRACKBAR 3  " + #TAB$ + ": Adjust Blue value." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle Add / Subtract." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset Image."

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
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback2(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
EndProcedure

ProcedureC CvTrackbarCallback3(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
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

    If *image\width >= dtWidth - 100 Or *image\height >= dtHeight - (100 + 48 + 42 + 84)
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / *image\width
      iHeight = dtHeight - (100 + 48 + 42 + 84)
      iRatio2.d = iHeight / *image\height

      If iRatio1 < iRatio2
        iWidth = *image\width * iRatio1
        iHeight = *image\height * iRatio1
      Else
        iWidth = *image\width * iRatio2
        iHeight = *image\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight + 48 + 42 + 84)
      *resize.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image\nChannels)
      cvResize(*image, *resize, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height + 48 + 42 + 84)
      *resize.IplImage = cvCloneImage(*image)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)

    If *resize\width > 200 And *resize\height > 200
      cvCreateTrackbar("Red", #CV_WINDOW_NAME, @nR, 255, @CvTrackbarCallback3())
      cvCreateTrackbar("Green", #CV_WINDOW_NAME, @nG, 255, @CvTrackbarCallback2())
      cvCreateTrackbar("Blue", #CV_WINDOW_NAME, @nB, 255, @CvTrackbarCallback1())
      *copy.IplImage = cvCloneImage(*resize)
      *reset1.IplImage = cvCloneImage(*resize)
      *reset2.IplImage = cvCloneImage(*resize)
      *reset3.IplImage = cvCloneImage(*resize)
      *caculate.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, *resize\nChannels)
      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
      cvPutText(*resize, "ADD", 22, 42, @font, 0, 0, 0, 0)
      cvPutText(*resize, "ADD", 20, 40, @font, 255, 255, 255, 0)
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
              cvReleaseImage(@*resize)
              *resize = cvCloneImage(*reset3)
              cvReleaseImage(@*copy)
              *copy = cvCloneImage(*reset3)
              cvReleaseImage(@*reset1)
              *reset1 = cvCloneImage(*reset3)
              cvReleaseImage(@*reset2)
              *reset2 = cvCloneImage(*reset3)
              cvSetTrackbarPos("Red", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Green", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Blue", #CV_WINDOW_NAME, 0)
              nCaculate = 0
            Case 32
               cvReleaseImage(@*resize)
              *resize = cvCloneImage(*copy)
              cvReleaseImage(@*reset1)
              *reset1 = cvCloneImage(*copy)
              cvReleaseImage(@*reset2)
              *reset2 = cvCloneImage(*copy)
              cvSetTrackbarPos("Red", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Green", #CV_WINDOW_NAME, 0)
              cvSetTrackbarPos("Blue", #CV_WINDOW_NAME, 0)
              nCaculate ! #True
            Default
              cvReleaseImage(@*resize)
              *resize = cvCloneImage(*reset1)
              cvReleaseImage(@*copy)
              *copy = cvCloneImage(*reset2)
          EndSelect
          cvSet(*caculate, nB, nG, nR, 0, #Null)

          If nCaculate
            cvSub(*resize, *caculate, *resize, #Null)
            cvSub(*copy, *caculate, *copy, #Null)
            cvPutText(*resize, "SUBTRACT", 22, 42, @font, 0, 0, 0, 0)
            cvPutText(*resize, "SUBTRACT", 20, 40, @font, 255, 255, 255, 0)
          Else
            cvAdd(*resize, *caculate, *resize, #Null)
            cvAdd(*copy, *caculate, *copy, #Null)
            cvPutText(*resize, "ADD", 22, 42, @font, 0, 0, 0, 0)
            cvPutText(*resize, "ADD", 20, 40, @font, 255, 255, 255, 0)
          EndIf
          *param\Pointer1 = *copy
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*caculate)
      cvReleaseImage(@*reset3)
      cvReleaseImage(@*reset2)
      cvReleaseImage(@*reset1)
      cvReleaseImage(@*copy)
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

OpenCV("images/starrynight.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\