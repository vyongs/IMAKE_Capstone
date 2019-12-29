IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draw text using PureBasic commands with any font onto an OpenCV generated image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Change to another font."

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

    If *resize\width >= 640 And *resize\height >= 480 And *resize\nChannels = 3
      *reset.IplImage = cvCloneImage(*resize)
      *mask.IplImage = cvCreateImage(*resize\width, 80, #IPL_DEPTH_8U, *resize\nChannels)
      pbImage = CreateImage(#PB_Any, *mask\width, 80, 24, RGB(0, 0, 0))
      fontName.s = "Comic Sans MS"
      nFont = LoadFont(#PB_Any, fontName, 36, #PB_Font_HighQuality)

      If *resize\width = 640 : fontX = 20 : Else : fontX = (*resize\width - 640) / 2 + 20 : EndIf : fontY = 5

      font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *resize
          cvSetZero(*mask)

          If StartDrawing(ImageOutput(pbImage))
            DrawingFont(FontID(nFont))
            DrawText(fontX, fontY, "Use any font with OpenCV!", RGB(Random(255), Random(255), Random(255)))
            *mask\imageData = DrawingBuffer()
            StopDrawing()
          EndIf
          cvFlip(*mask, #Null, 0)
          cvSetImageROI(*resize, 0, *resize\height - 100, *resize\width, 80)
          cvAddS(*resize, 70, 70, 70, 0, *resize, 0)
          cvSub(*resize, *mask, *resize, 0)
          cvResetImageROI(*resize)
          cvPutText(*resize, fontName, 7, 30, @font, 0, 0, 0, 0)
          cvPutText(*resize, fontName, 5, 28, @font, 255, 255, 255, 0)
          cvShowImage(#CV_WINDOW_NAME, *resize)
          keyPressed = cvWaitKey(0)

          If keyPressed = 32
            newfont = (newfont + 1) % 10
            FreeFont(nFont)

            Select newfont
              Case 0
                fontName = "Comic Sans MS"
                fontY = 5
                nFont = LoadFont(#PB_Any, "Comic Sans MS", 36, #PB_Font_HighQuality)
              Case 1
                fontName = "Arial"
                fontY = 12
                nFont = LoadFont(#PB_Any, "Arial", 37, #PB_Font_HighQuality)
              Case 2
                fontName = "Impact"
                fontY = 8
                nFont = LoadFont(#PB_Any, "Impact", 42, #PB_Font_HighQuality)
              Case 3
                fontName = "Times New Roman"
                fontY = 10
                nFont = LoadFont(#PB_Any, "Times New Roman", 40, #PB_Font_HighQuality)
              Case 4
                fontName = "Verdana"
                fontY = 14
                nFont = LoadFont(#PB_Any, "Verdana", 33, #PB_Font_HighQuality)
              Case 5
                fontName = "Courier New"
                fontY = 22
                nFont = LoadFont(#PB_Any, "Courier New", 30, #PB_Font_HighQuality)
              Case 6
                fontName = "Tahoma"
                fontY = 8
                nFont = LoadFont(#PB_Any, "Tahoma", 38, #PB_Font_HighQuality)
              Case 7
                fontName = "Modern"
                fontY = 8
                nFont = LoadFont(#PB_Any, "Modern", 44, #PB_Font_Bold | #PB_Font_HighQuality)
              Case 8
                fontName = "Georgia"
                fontY = 14
                nFont = LoadFont(#PB_Any, "Georgia", 37, #PB_Font_HighQuality)
              Case 9
                fontName = "Garamond"
                fontY = 12
                nFont = LoadFont(#PB_Any, "Garamond", 41, #PB_Font_HighQuality)
            EndSelect
          EndIf
          cvReleaseImage(@*resize)
          *resize = cvCloneImage(*reset)
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      FreeFont(nFont)
      FreeImage(pbImage)
      cvReleaseImage(@*mask)
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

OpenCV("images/colors.jpg")
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\