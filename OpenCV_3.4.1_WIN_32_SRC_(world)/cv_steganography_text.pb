IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Steganography is the practice of concealing a file, message, image, or video within another file, message, image, or video." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Extract text to notepad."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 1
          openCV = #True
          keybd_event_(#VK_ESCAPE, 0, 0, 0)
        Case 2
          FileName.s = SaveCVImage(#True, 3)

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

Procedure ExtractText(ImageFile.s, *steganography.IplImage, nWidth, nHeight)
  *image.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)

  If *image\width > nWidth Or *image\height > nHeight
    *original.IplImage = cvCreateImage(nWidth, nHeight, #IPL_DEPTH_8U, 3)
    cvResize(*image, *original, #CV_INTER_AREA)
  Else
    *original.IplImage = cvCloneImage(*image)
  EndIf
  HiddenText.s = #Null$ : ClearClipboard()

  For i = 0 To *original\height - 1
    For j = 0 To *original\width - 1
      B1 = PeekA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 0)
      G1 = PeekA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 1)
      R1 = PeekA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 2)

      If Chr(B1) = "J" And Chr(G1) = "H" And Chr(R1) = "P" : Break 2 : EndIf

      B2 = PeekA(@*original\imageData\b + (i * *original\widthStep) + j * 3 + 0)
      G2 = PeekA(@*original\imageData\b + (i * *original\widthStep) + j * 3 + 1)
      R2 = PeekA(@*original\imageData\b + (i * *original\widthStep) + j * 3 + 2)

      Select #True
        Case Bool(B1 <> B2)
          If G1 = G2
            HiddenText + Chr(Abs(B1 - B2) + 97 - 1)
          Else
            Select #True
              Case Bool(Abs(G1 - G2) = 1)
                HiddenText + Chr(Abs(B1 - B2) + 65 - 1)
              Case Bool(Abs(G1 - G2) = 2)
                HiddenText + Chr(Abs(B1 - B2) + 48 - 1)
            EndSelect
          EndIf
        Case Bool(R1 <> R2)
          Select Abs(R1 - R2)
            Case 1
              HiddenText + #CRLF$
            Case 2
              HiddenText + Chr(32)
            Case 3
              HiddenText + Chr(38)
            Case 4
              HiddenText + Chr(39)
            Case 5
              HiddenText + Chr(44)
            Case 6
              HiddenText + Chr(45)
            Case 7
              HiddenText + Chr(46)
            Case 8
              HiddenText + Chr(58)
            Case 9
              HiddenText + Chr(59)
            Case 10
              HiddenText + Chr(151)
          EndSelect
      EndSelect
    Next
  Next
  cvReleaseImage(@*original)
  SetClipboardText(HiddenText)
  RunProgram("notepad.exe") : Delay(200)
  hWnd = FindWindow_("notepad", #Null)
  hWndChild = FindWindowEx_(hWnd, #Null, "Edit", #Null)
  SendMessage_(hWnd, #WM_SETTEXT, #Null, @"United States Declaration of Independence")
  SendMessage_(hWndChild, #WM_SETTEXT, #Null, @HiddenText)
  ClearClipboard()
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

    If *resize\width > 400 And *resize\height > 400 And *resize\nChannels = 3
      *steganography.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_8U, 3)

      If ReadFile(0, "other/declaration.txt")
        ReadFile = #True

        For i = 0 To *resize\height - 1
          For j = 0 To *resize\width - 1
            B = PeekA(@*resize\imageData\b + (i * *resize\widthStep) + j * 3 + 0)
            G = PeekA(@*resize\imageData\b + (i * *resize\widthStep) + j * 3 + 1)
            R = PeekA(@*resize\imageData\b + (i * *resize\widthStep) + j * 3 + 2)
            pixel = (pixel + 1) % 25

            If Eof(0) And ReadFile
              B = Asc("J")
              G = Asc("H")
              R = Asc("P")
              ReadFile = #False
            Else
              If pixel = 0
                nChar = Asc(ReadString(0, #PB_Ascii, 1))

                Select nChar
                  Case 0
                    If R > 0 : R - 1 : Else : R + 1 : EndIf
                  Case 32
                    If R > 1 : R - 2 : Else : R + 2 : EndIf
                  Case 38
                    If R > 2 : R - 3 : Else : R + 3 : EndIf
                  Case 39
                    If R > 3 : R - 4 : Else : R + 4 : EndIf
                  Case 44
                    If R > 4 : R - 5 : Else : R + 5 : EndIf
                  Case 45
                    If R > 5 : R - 6 : Else : R + 6 : EndIf
                  Case 46
                    If R > 6 : R - 7 : Else : R + 7 : EndIf
                  Case 48 To 57
                    If B > 9 : B - (nChar - 48) - 1 : Else : B + (nChar - 48) + 1 : EndIf
                    If G > 2 : G - 2 : Else : G + 2 : EndIf
                  Case 58
                    If R > 7 : R - 8 : Else : R + 8 : EndIf
                  Case 59
                    If R > 8 : R - 9 : Else : R + 9 : EndIf
                  Case 65 To 90
                    If B > 25 : B - (nChar - 65) - 1 : Else : B + (nChar - 65) + 1 : EndIf
                    If G > 1 : G - 1 : Else : G + 1 : EndIf
                  Case 97 To 122
                    If B > 25 : B - (nChar - 97) - 1 : Else : B + (nChar - 97) + 1 : EndIf
                  Case 151
                    If R > 9 : R - 10 : Else : R + 10 : EndIf
                EndSelect
              EndIf
            EndIf
            PokeA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 0, B)
            PokeA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 1, G)
            PokeA(@*steganography\imageData\b + (i * *steganography\widthStep) + j * 3 + 2, R)
          Next
        Next
        CloseFile(0)
      Else
        *steganography = cvCloneImage(*resize)
      EndIf
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *steganography
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        If *steganography
          cvShowImage(#CV_WINDOW_NAME, *steganography)
          keyPressed = cvWaitKey(0)

          If keyPressed = 32 : ExtractText(ImageFile, *steganography, *resize\width, *resize\height) : EndIf

        EndIf
      Until keyPressed = 27 Or exitCV
      FreeMemory(*param)
      cvReleaseImage(@*steganography)
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

OpenCV("images/sketch1.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\