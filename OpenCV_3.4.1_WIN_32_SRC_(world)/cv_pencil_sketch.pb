IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nPencil

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Simulate a color / black & white pencil sketch from an image." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Start / Swap sketch." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch to next image."

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

Procedure DiffX(*image.IplImage, *temp.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels

  For i = 0 To h - 1
    For j = 0 To w - 2
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*temp, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*image, i, ((j + 1) * channel + c) * 4)) - PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + c) * 4)))
      Next
    Next
  Next
EndProcedure

Procedure DiffY(*image.IplImage, *temp.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels

  For i = 0 To h - 2
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*temp, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*image, (i + 1), (j * channel + c) * 4)) - PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + c) * 4)))
      Next
    Next
  Next
EndProcedure

Procedure PencilFilter(*horiz.CvMat, *pencil.CvMat, radius.f)
  myinf.d = 9.9e307
  h = *horiz\rows
  w = *horiz\cols
	*lower_pos.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*upper_pos.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

	For i = 0 To h - 1
	  For j = 0 To w - 1
	    cvmSet(*lower_pos, i, j, cvmGet(*horiz, i, j) - radius)
	    cvmSet(*upper_pos, i, j, cvmGet(*horiz, i, j) + radius)
	  Next
	Next
	*lower_idx.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*upper_idx.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*domain_row.CvMat = cvCreateMat(1, w + 1, CV_MAKETYPE(#CV_32F, 1))
	*lower_pos_row.CvMat = cvCreateMat(1, w, CV_MAKETYPE(#CV_32F, 1))
	*upper_pos_row.CvMat = cvCreateMat(1, w, CV_MAKETYPE(#CV_32F, 1))
	*temp_lower_idx.CvMat = cvCreateMat(1, w, CV_MAKETYPE(#CV_32F, 1))
	*temp_upper_idx.CvMat = cvCreateMat(1, w, CV_MAKETYPE(#CV_32F, 1))
	cvSetZero(*lower_idx)
	cvSetZero(*upper_idx)
	cvSetZero(*domain_row)

	For i = 0 To h - 1
	  For j = 0 To w - 1
	    cvmSet(*domain_row, 0, j, cvmGet(*horiz, i, j))
	  Next
    cvmSet(*domain_row, 0, w, myinf)
    cvSetZero(*lower_pos_row)
    cvSetZero(*upper_pos_row)

    For j = 0 To w - 1
      cvmSet(*lower_pos_row, 0, j, cvmGet(*lower_pos, i, j))
      cvmSet(*upper_pos_row, 0, j, cvmGet(*upper_pos, i, j))
    Next
    cvSetZero(*temp_lower_idx)
    cvSetZero(*temp_upper_idx)

    For j = 0 To w - 1
      If cvmGet(*domain_row, 0, j) > cvmGet(*lower_pos_row, 0, 0)
        cvmSet(*temp_lower_idx, 0, 0, j)
        Break
      EndIf
    Next

    For j = 0 To w - 1
      If cvmGet(*domain_row, 0, j) > cvmGet(*upper_pos_row, 0, 0)
        cvmSet(*temp_upper_idx, 0, 0, j)
        Break
      EndIf
    Next
    temp = 0

    For j = 1 To w - 1
      count = 0

      For k = cvmGet(*temp_lower_idx, 0, j - 1) To w
        If cvmGet(*domain_row, 0, k) > cvmGet(*lower_pos_row, 0, j)
          temp = count
          Break
        EndIf
        count + 1
      Next
      cvmSet(*temp_lower_idx, 0, j, cvmGet(*temp_lower_idx, 0, j - 1) + temp)
      count = 0

      For k = cvmGet(*temp_upper_idx, 0, j - 1) To w
        If cvmGet(*domain_row, 0, k) > cvmGet(*upper_pos_row, 0, j)
          temp = count
          Break
        EndIf
        count + 1
      Next
      cvmSet(*temp_upper_idx, 0, j, cvmGet(*temp_upper_idx, 0, j - 1) + temp)
    Next

    For j = 0 To w - 1
      cvmSet(*lower_idx, i, j, cvmGet(*temp_lower_idx, 0, j) + 1)
      cvmSet(*upper_idx, i, j, cvmGet(*temp_upper_idx, 0, j) + 1)
    Next
  Next

	For i = 0 To h - 1
	  For j = 0 To w - 1
	    cvmSet(*pencil, i, j, cvmGet(*upper_idx, i, j) - cvmGet(*lower_idx, i, j))
	  Next
	Next
	cvReleaseMat(@*temp_upper_idx)
	cvReleaseMat(@*temp_lower_idx)
	cvReleaseMat(@*upper_pos_row)
	cvReleaseMat(@*lower_pos_row)
	cvReleaseMat(@*domain_row)
	cvReleaseMat(@*upper_idx)
	cvReleaseMat(@*lower_idx)
	cvReleaseMat(@*upper_pos)
	cvReleaseMat(@*lower_pos)
EndProcedure

Structure PENCIL_SKETCH
  *black.IplImage
  *color.IplImage
EndStructure

Procedure PencilSketch(*image.IplImage, sigma_s.f, sigma_r.f, shade.f, *ps.PENCIL_SKETCH)
  iterations = 1
  w = *image\width
  h = *image\height
	channel = *image\nChannels
	*derivx.IplImage = cvCreateImage(w - 1, h, #IPL_DEPTH_32F, 3)
	*derivy.IplImage = cvCreateImage(w, h - 1, #IPL_DEPTH_32F, 3)
	*distx.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
	*disty.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
	cvSetZero(*derivx)
	cvSetZero(*derivy)
	cvSetZero(*distx)
	cvSetZero(*disty)
	DiffX(*image, *derivx)
	DiffY(*image, *derivy)

	For i = 0 To h - 1
	  k = 1

	  For j = 0 To w - 2
	    For c = 0 To channel - 1
	      PokeF(@CV_IMAGE_ELEM(*distx, i, k * 4), PeekF(@CV_IMAGE_ELEM(*distx, i, k * 4)) + Abs(PeekF(@CV_IMAGE_ELEM(*derivx, i, (j * channel + c) * 4))))
	    Next
	    k + 1
	  Next
	Next
	k = 1

	For i = 0 To h - 2
	  For j = 0 To w - 1
	    For c = 0 To channel - 1
	      PokeF(@CV_IMAGE_ELEM(*disty, k, j * 4), PeekF(@CV_IMAGE_ELEM(*disty, k, j * 4)) + Abs(PeekF(@CV_IMAGE_ELEM(*derivy, i, (j * channel + c) * 4))))
	    Next
	  Next
	  k + 1
	Next
	*horiz.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*vert.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

	For i = 0 To h - 1
	  For j = 0 To w - 1
      cvmSet(*horiz, i, j, 1 + (sigma_s / sigma_r) * PeekF(@CV_IMAGE_ELEM(*distx, i, j * 4)))
      cvmSet(*vert, i, j, 1 + (sigma_s / sigma_r) * PeekF(@CV_IMAGE_ELEM(*disty, i, j * 4)))
    Next
  Next
  *ctH.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *ctV.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

  For i = 0 To h - 1
    cvmSet(*ctH, i, 0, cvmGet(*horiz, i, 0))

    For j = 1 To w - 1
      cvmSet(*ctH, i, j, cvmGet(*horiz, i, j) + cvmGet(*ctH, i, j - 1))
    Next
  Next

  For j = 0 To w - 1
    cvmSet(*ctV, 0, j, cvmGet(*vert, 0, j))

    For i = 1 To h - 1
      cvmSet(*ctV, i, j, cvmGet(*vert, i, j) + cvmGet(*ctV, i - 1, j))
    Next
  Next
  *black.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *penx.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *peny.CvMat = cvCreateMat(w, h, CV_MAKETYPE(#CV_32F, 1))
	*peny_t.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*ctV_t.CvMat = cvCreateMat(w, h, CV_MAKETYPE(#CV_32F, 1))
  *YUV.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  *Y_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
	*U_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
	*V_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
	*color.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
	cvSetZero(*black)
  cvTranspose(*ctV, *ctV_t)
	cvCvtColor(*image, *YUV, #CV_BGR2YUV, 1)

	For i = 0 To iterations - 1
	  radius.f = Sqr(3) * sigma_s * Sqr(3) * Pow(2, (iterations - (i + 1))) / Sqr(Pow(4, iterations) - 1)
	  PencilFilter(*ctH, *penx, radius)
	  PencilFilter(*ctV_t, *peny, radius)
	  cvTranspose(*peny, *peny_t)

	  For k = 0 To h - 1
	    For j = 0 To w - 1
	      cvmSet(*black, k, j, shade * (cvmGet(*penx, k, j) + cvmGet(*peny_t, k, j)))
	    Next
	  Next
    cvSplit(*YUV, *Y_channel, *U_channel, *V_channel, #Null)

    For k = 0 To h - 1
      For j = 0 To w - 1
        PokeF(@CV_IMAGE_ELEM(*Y_channel, k, j * 4), cvmGet(*black, k, j))
      Next
    Next
    cvMerge(*Y_channel, *U_channel, *V_channel, #Null, *YUV)
    cvCvtColor(*YUV, *color, #CV_YUV2BGR, 1)
  Next
  *pencil.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
  cvConvertScale(*black, *pencil, 255, 0)
  *ps\black = *pencil
  *pencil.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)
  cvConvertScale(*color, *pencil, 255, 0)
  *ps\color = *pencil
  cvReleaseImage(@*color)
  cvReleaseImage(@*V_channel)
  cvReleaseImage(@*U_channel)
  cvReleaseImage(@*Y_channel)
  cvReleaseImage(@*YUV)
  cvReleaseMat(@*ctV_t)
  cvReleaseMat(@*peny_t)
  cvReleaseMat(@*peny)
  cvReleaseMat(@*penx)
  cvReleaseMat(@*black)
  cvReleaseMat(@*ctV)
  cvReleaseMat(@*ctH)
  cvReleaseMat(@*vert)
  cvReleaseMat(@*horiz)
  cvReleaseImage(@*disty)
  cvReleaseImage(@*distx)
  cvReleaseImage(@*derivy)
  cvReleaseImage(@*derivx)
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
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        cvShowImage(#CV_WINDOW_NAME, *resize)
        keyPressed = cvWaitKey(0)
      Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

      If keyPressed = 32
        *resize32.IplImage = cvCreateImage(*resize\width, *resize\height, #IPL_DEPTH_32F, 3)
        cvConvertScale(*resize, *resize32, 1 / 255, 0)
        font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
        cvPutText(*resize, "Working...", 20, 40, @font, 0, 0, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *resize)
        cvWaitKey(100)
    		sigma_s.f = 60
    		sigma_r.f = 0.07
    		shade.f = 0.05
    		PencilSketch(*resize32, sigma_s, sigma_r, shade, @ps.PENCIL_SKETCH)
    		*pencil.IplImage = ps\color
        *param\Pointer1 = *pencil

        Repeat
          If *pencil
            cvShowImage(#CV_WINDOW_NAME, *pencil)
            keyPressed = cvWaitKey(0)

            If keyPressed = 32
              pencil ! #True

              If pencil : *pencil = ps\black : Else : *pencil = ps\color : EndIf

              *param\Pointer1 = *pencil
            EndIf
          EndIf
        Until keyPressed = 13 Or keyPressed = 27 Or exitCV
        FreeMemory(*param)
        cvReleaseImage(@*pencil)
        cvReleaseImage(@*resize32)
      EndIf
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If keyPressed = 13
        exitCV = #False
        nPencil = (nPencil + 1) % 2
        OpenCV("images/sketch" + Str(nPencil + 1) + ".jpg")
      ElseIf openCV
        openCV = #False
        exitCV = #False
        nPencil = 0
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

OpenCV("images/sketch1.jpg")
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\