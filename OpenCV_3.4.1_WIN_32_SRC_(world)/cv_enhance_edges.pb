IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc, nEdge

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Enhance the edges of an image in 2 stages using various filters." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Start next stage." + #LF$ +
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

Procedure GetGradientX(*image.CvMat, *gx.CvMat)
  h = *image\rows
  w = *image\cols
  cvSetZero(*gx)

  For i = 0 To h - 1
    For j = 0 To w - 2
      cvmSet(*gx, i, j, cvmGet(*image, i, j + 1) - cvmGet(*image, i, j))
    Next
  Next
EndProcedure

Procedure GetGradientY(*image.CvMat, *gy.CvMat)
  h = *image\rows
  w = *image\cols
  cvSetZero(*gy)

  For i = 0 To h - 2
    For j = 0 To w - 1
      cvmSet(*gy, i, j, cvmGet(*image, i + 1, j) - cvmGet(*image, i, j))
    Next
  Next
EndProcedure

Procedure FindMagnitude(*image.CvMat)
  h = *image\rows
  w = *image\cols
  Dim *planes.CvMat(3)

	For rtnCount = 0 To 3 - 1
	  *planes(rtnCount) = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	Next
	cvSplit(*image, *planes(0), *planes(1), *planes(2), 0)
  *magXR.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magYR.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magXG.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magYG.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magXB.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magYB.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  GetGradientX(*planes(0), *magXR)
	GetGradientY(*planes(0), *magYR)
	GetGradientX(*planes(1), *magXG)
	GetGradientY(*planes(1), *magYG)
	GetGradientX(*planes(2), *magXB)
	GetGradientY(*planes(2), *magYB)
	*magx.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *magy.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *mag1.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *mag2.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  *mag3.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
  cvCartToPolar(*magXR, *magYR, *mag1, #Null, #False)
  cvCartToPolar(*magXG, *magYG, *mag2, #Null, #False)
  cvCartToPolar(*magXB, *magYB, *mag3, #Null, #False)
  *magnitude.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

  For i = 0 To h - 1
    For j = 0 To w - 1
      cvmSet(*magnitude, i, j, cvmGet(*mag1, i, j) + cvmGet(*mag2, i, j) + cvmGet(*mag3, i, j))
    Next
  Next

  For i = 0 To h - 1
    For j = 0 To w - 1
      cvmSet(*magnitude, i, j, 1 - cvmGet(*magnitude, i, j))
    Next
  Next
  cvReleaseMat(@*mag3)
  cvReleaseMat(@*mag2)
  cvReleaseMat(@*mag1)
  cvReleaseMat(@*magy)
  cvReleaseMat(@*magx)
  cvReleaseMat(@*magYB)
  cvReleaseMat(@*magXB)
  cvReleaseMat(@*magYG)
  cvReleaseMat(@*magXG)
  cvReleaseMat(@*magYR)
  cvReleaseMat(@*magXR)

  For rtnCount = 0 To 3 - 1
	  cvReleaseMat(@*planes(rtnCount))
	Next
	ProcedureReturn *magnitude
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

Procedure NormalizedFilter(*edge.CvMat, *horiz.CvMat, radius.f)
  myinf.d = 9.9e307
  h = *edge\rows
  w = *edge\cols
  channel = (CV_MAT_TYPE(*edge\type) / 8) + 1
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
  *box_filter.CvMat = cvCreateMat(h, w + 1, CV_MAKETYPE(#CV_32F, 3))
  cvSetZero(*box_filter)
  scalar1.CvScalar
  scalar2.CvScalar

  For i = 0 To h - 1
	  cvGet2D(@scalar1, *edge, i, 0)
	  cvSet2D(*box_filter, i, 1, scalar1\val[0], scalar1\val[1], scalar1\val[2], 0)

	  For j = 2 To w
	    cvGet2D(@scalar1, *edge, i, j - 1)
	    cvGet2D(@scalar2, *box_filter, i, j - 1)
	    val0.f = scalar1\val[0] + scalar2\val[0]
	    val1.f = scalar1\val[1] + scalar2\val[1]
	    val2.f = scalar1\val[2] + scalar2\val[2]
	    cvSet2D(*box_filter, i, j, val0, val1, val2, 0)
	  Next
	Next
  *indices.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*final.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 3))
	cvSetZero(*indices)
	cvSetZero(*final)

	For i = 0 To h - 1
	  For j = 0 To w - 1
	    cvmSet(*indices, i, j, i + 1)
	  Next
	Next
	*a.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*b.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	*flag.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))
	cvSetZero(*a)
	cvSetZero(*b)
  cvSet(*flag, 1, 1, 1, 0, #Null)

  For i = 0 To h - 1
    For j = 0 To w - 1
      cvmSet(*flag, i, j, cvmGet(*flag, i, j))
    Next
  Next

  For i = 0 To h - 1
    For j = 0 To w - 1
      cvmSet(*a, i, j, (cvmGet(*flag, i, j) - 1) * h * (w + 1) + (cvmGet(*lower_idx, i, j) - 1) * h + cvmGet(*indices, i, j))
      cvmSet(*b, i, j, (cvmGet(*flag, i, j) - 1) * h * (w + 1) + (cvmGet(*upper_idx, i, j) - 1) * h + cvmGet(*indices, i, j))
    Next
  Next

  For i = 0 To h - 1
    For j = 0 To w - 1
      r = cvmGet(*b, i, j) / (h * (w * 2 + 2))
      rem = cvmGet(*b, i, j) - r * h
			q = rem / h
			p = rem - q * h

			If q = 0
			  p = h
			  q = w
			  r - 1
			EndIf

			If p = 0
			  p = h
			  q - 1
			EndIf
			r1 = cvmGet(*a, i, j) / (h * (w * 2 + 2))
			rem1 = cvmGet(*a, i, j) - r1 * h

			q1 = rem1 / h
			p1 = rem1 - q1 * h

			If p1 = 0
			  p1 = h
			  q1 - 1
			EndIf  			
 			cvGet2D(@scalar1, *box_filter, p - 1, q)
 			cvGet2D(@scalar2, *box_filter, p1 - 1, q1)
			final.f = cvmGet(*upper_idx, i, j) - cvmGet(*lower_idx, i, j)
			val0.f = (scalar1\val[0] - scalar2\val[0]) / final
			val1.f = (scalar1\val[1] - scalar2\val[1]) / final
			val2.f = (scalar1\val[2] - scalar2\val[2]) / final
			cvSet2D(*final, i, j, val0, val1, val2, 0)
		Next
	Next

  For i = 0 To h - 1
    For j = 0 To w - 1
      cvGet2D(@scalar1, *final, i, j)
	    cvSet2D(*edge, i, j, scalar1\val[0], scalar1\val[1], scalar1\val[2], 0)
    Next
  Next
  cvReleaseMat(@*flag)
  cvReleaseMat(@*b)
  cvReleaseMat(@*a)
  cvReleaseMat(@*final)
  cvReleaseMat(@*indices)
  cvReleaseMat(@*box_filter)
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

Procedure SmoothEdge(*image.IplImage, sigma_s.f, sigma_r.f)
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
  *ctV_t.CvMat = cvCreateMat(w, h, CV_MAKETYPE(#CV_32F, 1))
  cvTranspose(*ctV, *ctV_t)
  *edge.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 3))
  *edge_t.CvMat = cvCreateMat(w, h, CV_MAKETYPE(#CV_32F, 3))

  For i = 0 To h - 1
    For j = 0 To w - 1
      val0.f = PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + 0) * 4))
      val1.f = PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + 1) * 4))
      val2.f = PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + 2) * 4))
      cvSet2D(*edge, i, j, val0, val1, val2, 0)
    Next
  Next
  radius.f = Sqr(3) * sigma_s * Sqr(3) / Sqr(Pow(4, 1) - 1)
  NormalizedFilter(*edge, *ctH, radius)
  cvTranspose(*edge, *edge_t)
  NormalizedFilter(*edge_t, *ctV_t, radius)
  cvTranspose(*edge_t, *edge)
  cvReleaseMat(@*edge_t)
  cvReleaseMat(@*ctV_t)
  cvReleaseMat(@*ctV)
  cvReleaseMat(@*ctH)
	cvReleaseMat(@*vert)
  cvReleaseMat(@*horiz)
  cvReleaseImage(@*disty)
  cvReleaseImage(@*distx)
  cvReleaseImage(@*derivy)
  cvReleaseImage(@*derivx)
	ProcedureReturn *edge
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
        w = *resize\width
        h = *resize\height
        *resize32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
        cvConvertScale(*resize, *resize32, 1 / 255, 0)
        font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
        cvPutText(*resize, "Working...", 20, 40, @font, 0, 0, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *resize)
        cvWaitKey(1000)
        temp1.CvMat
        *temp1.CvMat = cvGetMat(*resize32, @temp1, #Null, 0)
        *magnitude.CvMat = FindMagnitude(*temp1)
        temp2.IplImage
        *temp2.IplImage = cvGetImage(*magnitude, @temp2)
        *gray.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
        cvConvertScale(*temp2, *gray, 255, 0)
        cvReleaseMat(@*magnitude)
        *param\Pointer1 = *gray

        Repeat
          cvShowImage(#CV_WINDOW_NAME, *gray)
          keyPressed = cvWaitKey(0)
        Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV
      EndIf

      If keyPressed = 32
        *color.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)
        cvCvtColor(*gray, *color, #CV_GRAY2BGR, 1)
        cvPutText(*color, "Working...", 20, 40, @font, 0, 0, 255, 0)
        cvShowImage(#CV_WINDOW_NAME, *color)
        cvWaitKey(100)
    		sigma_s.f = 60
    		sigma_r.f = 0.30
    		*edge.CvMat = SmoothEdge(*resize32, sigma_s, sigma_r)
    		*magnitude.CvMat = FindMagnitude(*edge)
    		*temp2 = cvGetImage(*magnitude, @temp2)
    		*final.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
    		cvConvertScale(*temp2, *final, 255, 0)
    		*param\Pointer1 = *final

        Repeat
          If *final
            cvShowImage(#CV_WINDOW_NAME, *final)
            keyPressed = cvWaitKey(0)
          EndIf
        Until keyPressed = 13 Or keyPressed = 27 Or exitCV
        FreeMemory(*param)
        cvReleaseImage(@*final)
        cvReleaseMat(@*magnitude)
        cvReleaseMat(@*edge)
        cvReleaseImage(@*color)
        cvReleaseImage(@*gray)
        cvReleaseImage(@*resize32)
      EndIf
      cvReleaseImage(@*resize)
      cvReleaseImage(@*image)
      cvDestroyAllWindows()

      If keyPressed = 13
        exitCV = #False
        nEdge = (nEdge + 1) % 2
        OpenCV("images/sketch" + Str(nEdge + 1) + ".jpg")
      ElseIf openCV
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

OpenCV("images/sketch1.jpg")
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\