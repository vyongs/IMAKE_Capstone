IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using a Laplacian pyramid with the help of an image mask, two images are blended together." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle image effect."

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

Procedure ReConstruct(Array *LS.IplImage(1), *dst.IplImage, nLevels)
  *up.IplImage : *currentImage.IplImage = cvCloneImage(*LS(nLevels - 1))
  *dst_32F.IplImage = cvCreateImage(*dst\width, *dst\height, #IPL_DEPTH_32F, *dst\nChannels)

  For i = nLevels - 1 To 1 Step -1
    *up = cvCreateImage(*LS(i - 1)\width, *LS(i - 1)\height, #IPL_DEPTH_32F, *dst\nChannels)
    cvPyrUp(*currentImage, *up, #CV_GAUSSIAN_5x5) : *currentImage = cvCloneImage(*up)
    cvAdd(*LS(i - 1), *up, *currentImage, #Null)
    cvReleaseImage(@*up)
  Next
  cvCopy(*currentImage, *dst_32F, #Null)
  cvConvertScale(*dst_32F, *dst, 255, 0)
  cvReleaseImage(@*dst_32F)
  cvReleaseImage(@*currentImage)
EndProcedure

Procedure BuildLP(*src.IplImage, Array *LP.IplImage(1), nLevels)
  *currentImage.IplImage = cvCreateImage(*src\width, *src\height, #IPL_DEPTH_32F, *src\nChannels)
	*src_32F.IplImage = cvCreateImage(*src\width, *src\height, #IPL_DEPTH_32F, *src\nChannels)
	cvConvertScale(*src, *src_32F, 1 / 255, 0)
	cvCopy(*src_32F, *currentImage, #Null)
	*down.IplImage : *up.IplImage

	For i = 0 To nLevels - 2
	  *down = cvCreateImage(*currentImage\width / 2, *currentImage\height / 2, #IPL_DEPTH_32F, *src\nChannels)
	  cvPyrDown(*currentImage, *down, #CV_GAUSSIAN_5x5)
	  *up = cvCreateImage(*currentImage\width, *currentImage\height, #IPL_DEPTH_32F, *src\nChannels)
	  cvPyrUp(*down, *up, #CV_GAUSSIAN_5x5)
	  *LP(i) = cvCreateImage(*currentImage\width, *currentImage\height, #IPL_DEPTH_32F, *src\nChannels)
	  cvSub(*currentImage, *up, *LP(i), #Null) : *currentImage = cvCloneImage(*down)
	  *LP(nLevels - 1) = cvCreateImage(*currentImage\width, *currentImage\height, #IPL_DEPTH_32F, *src\nChannels)
	  cvCopy(*currentImage, *LP(nLevels - 1), #Null)
	  cvReleaseImage(@*up)
	  cvReleaseImage(@*down)
	Next
	cvReleaseImage(@*src_32F)
	cvReleaseImage(@*currentImage)
EndProcedure

Procedure BlendImages(*A.IplImage, *B.IplImage, *R.IplImage, *dst.IplImage, nLevels)
  *mask8U.IplImage = cvCreateImage(*R\width, *R\height, #IPL_DEPTH_8U, 1)
  *mask.IplImage = cvCreateImage(*R\width, *R\height, #IPL_DEPTH_32F, 1)
  cvCvtColor(*R, *mask8U, #CV_BGR2GRAY, 1)
  cvConvertScale(*mask8U, *mask, 1 / 255, 0)
  Dim *GR.IplImage(nLevels) : *GR_8U.IplImage
  *GR(0) = cvCloneImage(*mask)

  For i = 1 To nLevels - 1
    *GR(i) = cvCreateImage(*GR(i - 1)\width / 2, *GR(i - 1)\height / 2, *GR(0)\depth, *GR(0)\nChannels)
		cvPyrDown(*GR(i - 1), *GR(i), #CV_GAUSSIAN_5x5)
  Next
  Dim *LA.IplImage(nLevels) : Dim *LB.IplImage(nLevels) : Dim *LS.IplImage(nLevels)
	BuildLP(*A, *LA(), nLevels)
	BuildLP(*B, *LB(), nLevels)
	curr_ls.CvScalar : curr_la.CvScalar : curr_lb.CvScalar : curr_gr.CvScalar

	For l = 0 To nLevels - 1
	  nWidth = *LA(l)\width : nHeight = *LA(l)\height
		*LS(l) = cvCreateImage(nWidth, nHeight, #IPL_DEPTH_32F, *A\nChannels)

		For h = 0 To nHeight - 1
		  For w = 0 To nWidth - 1
		    cvGet2D(@curr_gr, *GR(l), w, h)
				cvGet2D(@curr_la, *LA(l), w, h)
				cvGet2D(@curr_lb, *LB(l), w, h)
				curr_ls\val[0] = curr_gr\val[0] * curr_la\val[0] + (1 - curr_gr\val[0]) * curr_lb\val[0]

				If *A\nChannels = 3
				  curr_ls\val[1] = curr_gr\val[0] * curr_la\val[1] + (1 - curr_gr\val[0]) * curr_lb\val[1]
					curr_ls\val[2] = curr_gr\val[0] * curr_la\val[2] + (1 - curr_gr\val[0]) * curr_lb\val[2]
				EndIf
 				cvSet2D(*LS(l), w, h, curr_ls\val[0], curr_ls\val[1], curr_ls\val[2], 0)
		  Next
		Next
	Next

	For l = 0 To nLevels - 1
	  cvReleaseImage(@*LB(l))
	  cvReleaseImage(@*LA(l))
	  cvReleaseImage(@*GR(l))
	Next
	cvReleaseImage(@*mask)
	cvReleaseImage(@*mask8U)
	ReConstruct(*LS(), *dst, nLevels)

	For l = 0 To nLevels - 1
	  cvReleaseImage(@*LS(l))
	Next
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
    nAdjustX = 0 : nAdjustY = 90 : nLevels = 4
    *hand.IplImage = cvCreateImage(600, 600, *resize\depth, *resize\nChannels)
    cvResize(*resize, *hand, #CV_INTER_AREA)
    *eye.IplImage = cvLoadImage("images/blend1_1b.png", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
    *eye_resize.IplImage = cvCreateImage(*hand\width, *hand\height, *hand\depth, *hand\nChannels) : cvSetZero(*eye_resize)
    cvSetImageROI(*eye_resize, *hand\width / 2 - *eye\width / 2 + nAdjustX, *hand\height / 2 - *eye\height / 2 + nAdjustY, *eye\width, *eye\height)
    cvAdd(*eye_resize, *eye, *eye_resize, #Null)
    cvResetImageROI(*eye_resize)
    *mask.IplImage = cvCreateImage(*hand\width, *hand\height, *hand\depth, *hand\nChannels) : cvSetZero(*mask)
    cvEllipse(*mask, *hand\width / 2 + nAdjustX, *hand\height / 2 + nAdjustY, 70, 50, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
    *blend.IplImage = cvCreateImage(*hand\width, *hand\height, *hand\depth, *hand\nChannels)
  	BlendImages(*eye_resize, *hand, *mask, *blend, nLevels)
    *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
    *param\Pointer1 = *blend
    *param\Value = window_handle
    cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

    Repeat
      If *blend
        If nOriginal : cvShowImage(#CV_WINDOW_NAME, *hand) : Else : cvShowImage(#CV_WINDOW_NAME, *blend) : EndIf

        keyPressed = cvWaitKey(0)

        If keyPressed = 32 : nOriginal ! #True : EndIf

      EndIf
    Until keyPressed = 27 Or exitCV
    FreeMemory(*param)
    cvReleaseImage(@*blend)
    cvReleaseImage(@*mask)
    cvReleaseImage(@*eye_resize)
    cvReleaseImage(@*eye)
    cvReleaseImage(@*hand)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()
  EndIf
EndProcedure

OpenCV("images/hand3.jpg")
; IDE Options = PureBasic 5.71 LTS (Windows - x86)
; CursorPosition = 1
; Folding = --
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\