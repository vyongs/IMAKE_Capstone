IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, hWnd_stereo, hWnd_control

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Computes disparity using the BM (Block Matching) algorithm for a rectified stereo pair of images." + #LF$ + #LF$ +
                  "CONTROLS    " + #TAB$ + ": Adjust settings." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Filter objects by depth." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset controls." + #LF$ + #LF$ + 
                  "[ M ] KEY   " + #TAB$ + ": Toggle disparity map."

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
      SendMessage_(hWnd_stereo, #WM_CLOSE, 0, 0)
      SendMessage_(hWnd_control, #WM_CLOSE, 0, 0)
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

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_Z, 0, 0, 0)
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
    *image1.IplImage = cvLoadImage(ImageFile, #CV_LOAD_IMAGE_GRAYSCALE)
    lpRect.RECT : GetWindowRect_(GetDesktopWindow_(), @lpRect) : dtWidth = lpRect\right : dtHeight = lpRect\bottom

    If *image1\width * 2 >= dtWidth - 100 Or *image1\height >= dtHeight - 100
      iWidth = dtWidth - 100
      iRatio1.d = iWidth / (*image1\width * 2)
      iHeight = dtHeight - 100
      iRatio2.d = iHeight / *image1\height

      If iRatio1 < iRatio2
        iWidth = *image1\width * iRatio1
        iHeight = *image1\height * iRatio1
      Else
        iWidth = *image1\width * iRatio2
        iHeight = *image1\height * iRatio2
      EndIf
      cvResizeWindow(#CV_WINDOW_NAME, iWidth, iHeight)
      *resize1.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, *image1\nChannels)
      cvResize(*image1, *resize1, #CV_INTER_AREA)
    Else
      cvResizeWindow(#CV_WINDOW_NAME, *image1\width, *image1\height)
      *resize1.IplImage = cvCloneImage(*image1)
    EndIf
    cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
    ToolTip(window_handle, #CV_DESCRIPTION)
    cvNamedWindow(#CV_WINDOW_NAME + " - StereoBM", #CV_WINDOW_AUTOSIZE)
    hWnd_stereo = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - StereoBM"))
    SendMessage_(hWnd_stereo, #WM_SETICON, 0, opencv)
    wStyle = GetWindowLongPtr_(hWnd_stereo, #GWL_STYLE)
    SetWindowLongPtr_(hWnd_stereo, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
    cvResizeWindow(#CV_WINDOW_NAME + " - StereoBM", *resize1\width, *resize1\height)
    cvMoveWindow(#CV_WINDOW_NAME + " - StereoBM", *resize1\width + 50, 20)
    cvNamedWindow(#CV_WINDOW_NAME + " - StereoBM State", #CV_WINDOW_AUTOSIZE)
    hWnd_control = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - StereoBM State"))
    SendMessage_(hWnd_control, #WM_SETICON, 0, opencv)
    wStyle = GetWindowLongPtr_(hWnd_control, #GWL_STYLE)
    SetWindowLongPtr_(hWnd_control, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
    cvResizeWindow(#CV_WINDOW_NAME + " - StereoBM State", 320, 400)
    cvMoveWindow(#CV_WINDOW_NAME + " - StereoBM State", *resize1\width * 2 + 80, 20)
    *state.CvStereoBMState = cvCreateStereoBMState(#CV_STEREO_BM_BASIC, 0)
    nSAD = 20 : nMD = 64 : *state\textureThreshold = 12 : *state\uniquenessRatio = 0 : *state\speckleWindowSize = 0 : *state\speckleRange = 0
    cvCreateTrackbar("Pre-Filter", #CV_WINDOW_NAME + " - StereoBM State", @nPFS, 250, @CvTrackbarCallback())
    cvCreateTrackbar("Pre-Cap", #CV_WINDOW_NAME + " - StereoBM State", @nPFC, 62, @CvTrackbarCallback())
    cvCreateTrackbar("SAD-Size", #CV_WINDOW_NAME + " - StereoBM State", @nSAD, 250, @CvTrackbarCallback())
    cvCreateTrackbar("Min-Disp", #CV_WINDOW_NAME + " - StereoBM State", @nMD, 128, @CvTrackbarCallback())
    cvCreateTrackbar("No-Disp", #CV_WINDOW_NAME + " - StereoBM State", @nNod, 20, @CvTrackbarCallback())
    cvCreateTrackbar("Texture", #CV_WINDOW_NAME + " - StereoBM State", @*state\textureThreshold, 50, @CvTrackbarCallback())
    cvCreateTrackbar("Uniqueness", #CV_WINDOW_NAME + " - StereoBM State", @*state\uniquenessRatio, 50, @CvTrackbarCallback())
    cvCreateTrackbar("Spec.Size", #CV_WINDOW_NAME + " - StereoBM State", @*state\speckleWindowSize, 50, @CvTrackbarCallback())
    cvCreateTrackbar("Spec.Range", #CV_WINDOW_NAME + " - StereoBM State", @*state\speckleRange, 50, @CvTrackbarCallback())
    *image2.IplImage = cvLoadImage("images/scene_right.png", #CV_LOAD_IMAGE_GRAYSCALE)
    *resize2.IplImage = cvCreateImage(*resize1\width, *resize1\height, #IPL_DEPTH_8U, *resize1\nChannels)
    cvResize(*image2, *resize2, #CV_INTER_AREA)
    *disparity.CvMat = cvCreateMat(*resize1\height, *resize1\width, CV_MAKETYPE(#CV_16S, 1))
    *visual.CvMat = cvCreateMat(*resize1\height, *resize1\width, CV_MAKETYPE(#CV_8U, 1))
    *stereo.CvMat = cvCreateMat(*resize1\height, *resize1\width, CV_MAKETYPE(#CV_8U, 1))
    *state\preFilterSize = nPFS + 5 : If Not *state\preFilterSize % 2 : *state\preFilterSize + 1 : EndIf
    *state\SADWindowSize = nSAD + 5 : If Not *state\SADWindowSize % 2 : *state\SADWindowSize + 1 : EndIf
    *state\minDisparity = nMD - 64 : *state\preFilterCap = nPFC + 1 : *state\numberOfDisparities = (nNod + 1) * 16
    cvFindStereoCorrespondenceBM(*resize1, *resize2, *disparity, *state)
    cvConvertScale(*disparity, *visual, 1, 0)
    scalar.CvScalar : threshold = 40
    *stereo = cvCloneImage(*resize1)
    BringWindowToTop(hWnd)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *stereo
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *resize1
        If keyPressed = 32 And threshold > 40
          For y = 0 To *resize1\height - 1
            For x = 0 To *resize1\width - 1
              If cvGetReal2D(*visual, y, x) > threshold
                cvGet2D(@scalar, *resize1, y, x)
                cvSet2D(*stereo, y, x, scalar\val[0], scalar\val[1], scalar\val[2], 0)
              Else
                cvSet2D(*stereo, y, x, 128, 128, 128, 0)
              EndIf
            Next
          Next
          *param\Pointer1 = *stereo
        EndIf

        If nMap : cvShowImage(#CV_WINDOW_NAME, *resize2) : Else : cvShowImage(#CV_WINDOW_NAME, *visual) : EndIf

        cvShowImage(#CV_WINDOW_NAME + " - StereoBM", *stereo)
        keyPressed = cvWaitKey(0)

        Select keyPressed
          Case 13
            cvSetTrackbarPos("Pre-Filter", #CV_WINDOW_NAME + " - StereoBM State", 0)
            cvSetTrackbarPos("Pre-Cap", #CV_WINDOW_NAME + " - StereoBM State", 0)
            cvSetTrackbarPos("SAD-Size", #CV_WINDOW_NAME + " - StereoBM State", 20)
            cvSetTrackbarPos("Min-Disp", #CV_WINDOW_NAME + " - StereoBM State", 64)
            cvSetTrackbarPos("No-Disp", #CV_WINDOW_NAME + " - StereoBM State", 0)
            cvSetTrackbarPos("Texture", #CV_WINDOW_NAME + " - StereoBM State", 12)
            cvSetTrackbarPos("Uniqueness", #CV_WINDOW_NAME + " - StereoBM State", 0)
            cvSetTrackbarPos("Spec.Size", #CV_WINDOW_NAME + " - StereoBM State", 0)
            cvSetTrackbarPos("Spec.Range", #CV_WINDOW_NAME + " - StereoBM State", 0)
          Case 32
            If threshold = 200
              threshold = 40
              cvReleaseImage(@*stereo)
              *stereo = cvCloneImage(*resize1)
            Else
              threshold + 40
            EndIf
          Case 77, 109
            nMap ! 1
          Case 90, 122
            *state\preFilterSize = nPFS + 5 : If Not *state\preFilterSize % 2 : *state\preFilterSize + 1 : EndIf
            *state\SADWindowSize = nSAD + 5 : If Not *state\SADWindowSize % 2 : *state\SADWindowSize + 1 : EndIf
            *state\minDisparity = nMD - 64
            *state\preFilterCap = nPFC + 1
            *state\numberOfDisparities = (nNod + 1) * 16
            cvFindStereoCorrespondenceBM(*resize1, *resize2, *disparity, *state)
            cvConvertScale(*disparity, *visual, 1, 0)
        EndSelect
      EndIf
    Until keyPressed = 27 Or exitCV
    cvReleaseStereoBMState(@*state)
    cvReleaseMat(@*visual)
    cvReleaseMat(@*disparity)
    cvReleaseImage(@*resize2)
    cvReleaseImage(@*image2)
    cvReleaseImage(@*resize1)
    cvReleaseImage(@*image1)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/scene_left.png")
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\