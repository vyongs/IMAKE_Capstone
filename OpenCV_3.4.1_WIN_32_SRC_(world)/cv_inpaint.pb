IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nInpaint, nSize, noDraw

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Restores the selected region in an image using the region neighborhood." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Mark the repair area." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Set / Apply repair." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the image." + #LF$ + #LF$ +
                  "[ < ] KEY   " + #TAB$ + ": Adjust thickness smaller." + #LF$ +
                  "[ > ] KEY   " + #TAB$ + ": Adjust thickness larger." + #LF$ +
                  "[ I ] KEY   " + #TAB$ + ": Toggle inpainting method." + #LF$ + #LF$ +
                  "BLUE        " + #TAB$ + ": Navier-Stokes" + #LF$ +
                  "GREEN       " + #TAB$ + ": [Telea04]" + #LF$ +
                  "RED         " + #TAB$ + ": Navier-Stokes & [Telea04]"

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
        If Not noDraw
          pt2.CvPoint : pt2\x = x : pt2\y = y

          Select nInpaint
            Case 0
              cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 255, 0, 0, 0 , nSize, #CV_AA, #Null)
            Case 1
              cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 0, 255, 0, 0 , nSize, #CV_AA, #Null)
            Case 2
              cvLine(*param\Pointer1, pt1\x, pt1\y, pt2\x, pt2\y, 0, 0, 255, 0 , nSize, #CV_AA, #Null)
          EndSelect
          cvLine(*param\Pointer2, pt1\x, pt1\y, pt2\x, pt2\y, 255, 0, 0, 0 , nSize, #CV_AA, #Null)
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
    Dim arrLine.CvPoint4D(20) : offset = 40 : B = 255 : G = 0 : R = 0 : nSize = 1
    font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_DUPLEX, 1, 1, #Null, 1, #CV_AA)
    cvCircle(*resize, 25, 25, 20, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
    cvPutText(*resize, "1", 15, 35, @font, 0, 0, 0, 0)
    *temp.IplImage = cvCloneImage(*resize)
    *mask.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 1)
    *inpaint.IplImage = cvCloneImage(*resize)
    *reset.IplImage = cvCloneImage(*resize)
    cvSetZero(*mask)
    keybd_event_(#VK_RETURN, 0, 0, 0)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *temp
    *param\Pointer2 = *mask
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

    Repeat
      If *resize
        Select keyPressed
          Case 13
            *resize.IplImage = cvCloneImage(*reset)

            For rtnCount = 0 To 20 - 1
              arrLine(rtnCount)\x1 = Random(*resize\width - 10, 10) : arrLine(rtnCount)\y1 = Random(*resize\height - 10, 10)
              arrLine(rtnCount)\x2 = Random(*resize\width - 20, 20) : arrLine(rtnCount)\y2 = Random(*resize\width - 20, 20)
              cvLine(*resize, arrLine(rtnCount)\x1, arrLine(rtnCount)\y1, arrLine(rtnCount)\x2, arrLine(rtnCount)\y2, 255, 255, 255, 0, 1, #CV_AA, #Null)
            Next
            cvCircle(*resize, 25, 25, 20, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
            cvPutText(*resize, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
            cvSetZero(*mask)
            cvCopy(*resize, *temp, #Null)
            cvCopy(*resize, *inpaint, #Null)
            cvShowImage(#CV_WINDOW_NAME, *resize)
          Case 32
            noDraw = #True

            For rtnCount = 0 To 20 - 1
              cvLine(*temp, arrLine(rtnCount)\x1, arrLine(rtnCount)\y1, arrLine(rtnCount)\x2, arrLine(rtnCount)\y2, B, G, R, 0, nSize, #CV_AA, #Null)
              cvLine(*mask, arrLine(rtnCount)\x1, arrLine(rtnCount)\y1, arrLine(rtnCount)\x2, arrLine(rtnCount)\y2, 255, 0, 0, 0, nSize, #CV_AA, #Null)
            Next
            cvCircle(*temp, 25, 25, 20, 128, 128, 128, 0, #CV_FILLED, #CV_AA, #Null)
            cvPutText(*temp, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *temp)

            Repeat : keyPressed = cvWaitKey(0) : Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

            Select keyPressed
              Case 13
                noDraw = #False
                Continue
              Case 27
                Break
              Case 32
                If nInpaint > 1
                  cvInpaint(*inpaint, *mask, *inpaint, 3, #CV_INPAINT_NS)
                  cvInpaint(*inpaint, *mask, *inpaint, 3, #CV_INPAINT_TELEA)
                Else
                  cvInpaint(*inpaint, *mask, *inpaint, 3, inpaint)
                EndIf
                cvCircle(*inpaint, 25, 25, 20, 128, 128, 128, 0, #CV_FILLED, #CV_AA, #Null)
                cvPutText(*inpaint, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
                cvSetZero(*mask)
                cvCopy(*inpaint, *temp, #Null)
                cvShowImage(#CV_WINDOW_NAME, *inpaint)

                Repeat : keyPressed = cvWaitKey(0) : Until keyPressed = 13 Or keyPressed = 27 Or exitCV
                If keyPressed = 13 : noDraw = #False : Continue : Else : Break : EndIf

                noDraw = #False
            EndSelect
          Case 44, 60
            If nSize > 1 : nSize - 1 : EndIf

            cvCircle(*temp, 25, 25, 20, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
            cvPutText(*temp, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *temp)
          Case 46, 62
            If nSize < 9 : nSize + 1 : EndIf

            cvCircle(*temp, 25, 25, 20, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
            cvPutText(*temp, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
            cvShowImage(#CV_WINDOW_NAME, *temp)
          Case 73, 105
            nInpaint = (nInpaint + 1) % 3
            cvSetZero(*mask)

            Select nInpaint
              Case 0
                B = 255
                G = 0
                R = 0
              Case 1
                B = 0
                G = 255
                R = 0
              Case 2
                B = 0
                G = 0
                R = 255
            EndSelect
            cvCircle(*inpaint, 25, 25, 20, B, G, R, 0, #CV_FILLED, #CV_AA, #Null)
            cvPutText(*inpaint, Str(nSize), 15, 35, @font, 0, 0, 0, 0)
            cvCopy(*inpaint, *temp, #Null)
            cvShowImage(#CV_WINDOW_NAME, *inpaint)
        EndSelect
        keyPressed = cvWaitKey(0)
      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*reset)
    cvReleaseImage(@*inpaint)
    cvReleaseImage(@*mask)
    cvReleaseImage(@*temp)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If openCV
      nInpaint = 0
      openCV = #False
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/seams1.jpg")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\