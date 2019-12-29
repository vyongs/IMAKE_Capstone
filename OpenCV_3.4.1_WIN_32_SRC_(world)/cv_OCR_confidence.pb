IncludeFile "includes/cv_functions.pbi"
IncludeFile "includes/pb_tesseract.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "OpenCV + Tesseract OCR"
#CV_DESCRIPTION = "Using Tesseract OCR (Optical Character Recognition) an image is translated to text displaying its confidence-level in stages." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Switch between stages."

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

Procedure GetConfidence(*confidence.IplImage, hApi, iLevel)
  *gray.IplImage = cvCreateImage(*confidence\width, *confidence\height, #IPL_DEPTH_8U, 1)
  *bin.IplImage = cvCreateImage(*confidence\width, *confidence\height, #IPL_DEPTH_8U, 1)

  If *confidence\nChannels = 3 : cvCvtColor(*confidence, *gray, #CV_BGR2GRAY, 1) : Else : *gray = cvCloneImage(*confidence) : EndIf

  threshold.d = cvThreshold(*gray, *bin, 10, 255, #CV_THRESH_OTSU)
  TessBaseAPIClearAdaptiveClassifier(hAPI)
  TessBaseAPISetImage(hApi, *bin\imageData, *bin\width, *bin\height, 1, *bin\widthStep)
  *box.BOX : *boxes.BOXA = TessBaseAPIGetComponentImages(hApi, iLevel, 1, #Null, #Null)
  Debug "-------------------------"

  Select iLevel
    Case 0
      Debug "RIL_BLOCK"
    Case 1
      Debug "RIL_PARA"
    Case 2
      Debug "RIL_TEXTLINE"
    Case 3
      Debug "RIL_WORD"
    Case 4
      Debug "RIL_SYMBOL"
  EndSelect
  Debug "-------------------------"

  For rtnCount = 0 To *boxes\n - 1
    *box = boxaGetBox(*boxes, rtnCount, #L_CLONE)
    TessBaseAPISetRectangle(hApi, *box\x, *box\y, *box\w, *box\h)
    ocrResult.s = RTrim(PeekS(TessBaseAPIGetUTF8Text(hApi), -1, #PB_UTF8),Chr(10))
    MeanTextConf.f = TessBaseAPIMeanTextConf(hApi)

    Select MeanTextConf
      Case 0 To 64
        cvRectangleR(*confidence, *box\x - 1, *box\y - 1, *box\w + 2, *box\h + 2, 0, 0, 255, 0, 1, #CV_AA, #Null)
      Case 65 To 77
        cvRectangleR(*confidence, *box\x - 1, *box\y - 1, *box\w + 2, *box\h + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
      Case 78 To 100
        cvRectangleR(*confidence, *box\x - 1, *box\y - 1, *box\w + 2, *box\h + 2, 0, 255, 0, 0, 1, #CV_AA, #Null)
      Default
        cvRectangleR(*confidence, *box\x - 1, *box\y - 1, *box\w + 2, *box\h + 2, 255, 0, 0, 0, 1, #CV_AA, #Null)
    EndSelect
    Debug ocrResult : Debug "CONFIDENCE LEVEL: " + Str(MeanTextConf)
  Next : Debug #Null$
  cvReleaseImage(@*bin)
  cvReleaseImage(@*gray)
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
    hAPI = TesseractInit(#PSM_AUTO, #OEM_TESSERACT_ONLY, #PB_Compiler_FilePath + "binaries/tesseract/tessdata", "eng", #Null$)

    If hAPI
      cvShowImage(#CV_WINDOW_NAME, *resize)
      cvWaitKey(100)
      *confidence.IplImage = cvCloneImage(*resize)
      GetConfidence(*confidence, hApi, iLevel)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *confidence
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *confidence
          cvShowImage(#CV_WINDOW_NAME, *confidence)
          keyPressed = cvWaitKey(0)

          If keyPressed = 32
            iLevel = (iLevel + 1) % 5
            cvReleaseImage(@*confidence)
            *confidence = cvCloneImage(*resize)
            GetConfidence(*confidence, hApi, iLevel)
            *param\Pointer1 = *confidence
          EndIf
        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*confidence)
    EndIf
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If openCV
      openCV = #False
      exitCV = #False
      OpenCV(OpenCVImage())
    EndIf
  EndIf
EndProcedure

OpenCV("images/euro_text.png")
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableXP
; CurrentDirectory = binaries\
