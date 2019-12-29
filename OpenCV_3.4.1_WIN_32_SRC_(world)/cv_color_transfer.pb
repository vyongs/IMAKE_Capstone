IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Performs a color transfer between two images." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle between the color-transfer and original image." + #LF$ + #LF$ +
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

    If *resize\nChannels = 3
      *main.IplImage = cvLoadImage("images/sketch1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
      *source.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 3)
      *target.IplImage = cvCreateImage(*main\width, *main\height, #IPL_DEPTH_32F, 3)
      *source32.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 3)
      *target32.IplImage = cvCreateImage(*main\width, *main\height, #IPL_DEPTH_32F, 3)
      cvConvertScale(*resize, *source, 1 / 255, 0)
      cvConvertScale(*main, *target, 1 / 255, 0)
      cvCvtColor(*source, *source32, #CV_BGR2Lab, 1)
      cvCvtColor(*target, *target32, #CV_BGR2Lab, 1)
      mean1.CvScalar : std_dev1.CvScalar
      mean2.CvScalar : std_dev2.CvScalar
      cvAvgSdv(*source32, @mean1, @std_dev1, #Null)
      cvAvgSdv(*target32, @mean2, @std_dev2, #Null)
      *l.IplImage = cvCreateImage(*target32\width, *target32\height, #IPL_DEPTH_32F, 1)
      *a.IplImage = cvCreateImage(*target32\width, *target32\height, #IPL_DEPTH_32F, 1)
      *b.IplImage = cvCreateImage(*target32\width, *target32\height, #IPL_DEPTH_32F, 1)
      cvSplit(*target32, *l, *a, *b, #Null)
      cvSubS(*l, mean2\val[0], 0, 0, 0, *l, #Null)
      cvSubS(*a, mean2\val[1], 0, 0, 0, *a, #Null)
      cvSubS(*b, mean2\val[2], 0, 0, 0, *b, #Null)
      cvConvertScale(*l, *l, std_dev2\val[0] / std_dev1\val[0], 0)
      cvConvertScale(*a, *a, std_dev2\val[1] / std_dev1\val[1], 0)
      cvConvertScale(*b, *b, std_dev2\val[2] / std_dev1\val[2], 0)
      cvAddS(*l, mean1\val[0], 0, 0, 0, *l, #Null)
      cvAddS(*a, mean1\val[1], 0, 0, 0, *a, #Null)
      cvAddS(*b, mean1\val[2], 0, 0, 0, *b, #Null)

      For y = 0 To *target\height - 1
        For x = 0 To *target\width - 1
          l = PeekA(@*l\imageData\b + y * *l\widthStep + x)
          a = PeekA(@*a\imageData\b + y * *a\widthStep + x)
          b = PeekA(@*b\imageData\b + y * *b\widthStep + x)

          If l < 0 : PokeA(@*l\imageData\b + y * *l\widthStep + x, 0) : ElseIf l > 255 : PokeA(@*l\imageData\b + y * *l\widthStep + x, 255) : EndIf
          If a < 0 : PokeA(@*a\imageData\b + y * *a\widthStep + x, 0) : ElseIf a > 255 : PokeA(@*a\imageData\b + y * *a\widthStep + x, 255) : EndIf
          If b < 0 : PokeA(@*b\imageData\b + y * *b\widthStep + x, 0) : ElseIf b > 255 : PokeA(@*b\imageData\b + y * *b\widthStep + x, 255) : EndIf

        Next
      Next
      *transfer.IplImage = cvCreateImage(*target32\width, *target32\height, #IPL_DEPTH_32F, 3)
      *final.IplImage = cvCreateImage(*target32\width, *target32\height, #IPL_DEPTH_8U, 3)
      cvMerge(*l, *a, *b, #Null, *transfer)
      cvCvtColor(*transfer, *transfer, #CV_Lab2BGR, 1)
      cvConvertScale(*transfer, *final, 255, 0)
      cvConvertScale(*source, *source, 255, 0)
      *reset.IplImage = cvCloneImage(*final)

      If *resize\width > *resize\height : iRatio.d = 150 / *resize\width : Else : iRatio = 150 / *resize\height : EndIf

      iWidth = *resize\width * iRatio
      iHeight = *resize\height * iRatio
      *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_32F, 3)
      cvResize(*source, *PIP, #CV_INTER_AREA)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *final
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *final
          Select PIP
            Case 0
              cvSetImageROI(*final, 20, 20, iWidth, iHeight)
              cvAndS(*final, 0, 0, 0, 0, *final, #Null)
              cvAdd(*final, *PIP, *final, #Null)
              cvResetImageROI(*final)
              cvRectangleR(*final, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            Case 1
              cvSetImageROI(*final, *final\width - (150 + 20), 20, iWidth, iHeight)
              cvAndS(*final, 0, 0, 0, 0, *final, #Null)
              cvAdd(*final, *PIP, *final, #Null)
              cvResetImageROI(*final)
              cvRectangleR(*final, *final\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
          EndSelect

          If main : cvShowImage(#CV_WINDOW_NAME, *main) : Else : cvShowImage(#CV_WINDOW_NAME, *final) : EndIf

          keyPressed = cvWaitKey(0)

          Select keyPressed
            Case 32
              main ! #True
              *param\Pointer1 = *main
            Case 86, 118
              If Not main
                PIP = (PIP + 1) % 3
                cvReleaseImage(@*final)
                *final = cvCloneImage(*reset)
                *param\Pointer1 = *final
              EndIf
          EndSelect
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*PIP)
      cvReleaseImage(@*reset)
      cvReleaseImage(@*final)
      cvReleaseImage(@*transfer)
      cvReleaseImage(@*b)
      cvReleaseImage(@*a)
      cvReleaseImage(@*l)
      cvReleaseImage(@*target32)
      cvReleaseImage(@*source32)
      cvReleaseImage(@*target)
      cvReleaseImage(@*source)
      cvReleaseImage(@*main)
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

OpenCV("images/lena.jpg")
; IDE Options = PureBasic 5.40 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\