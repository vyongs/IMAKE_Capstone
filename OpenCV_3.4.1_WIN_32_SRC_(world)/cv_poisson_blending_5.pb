IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, nBlend

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using a Poisson blending algorithm, a localized illumination change is achieved." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Execute illumination." + #LF$ +
                  "ENTER       " + #TAB$ + ": Switch to next image." + #LF$ + #LF$ +
                  "Double-Click the window to open a webpage for additional information."

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
    Case #CV_EVENT_LBUTTONDBLCLK
      RunProgram("http://www.cs.brown.edu/courses/cs195-g/asgn/proj2/resources/PoissonImageEditing.pdf")
  EndSelect
EndProcedure

Procedure GetGradientX(*image.IplImage, *gx.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  cvSetZero(*gx)

  For i = 0 To h - 1
    For j = 0 To w - 2
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*gx, i, (j * channel + c) * 4), PeekA(@CV_IMAGE_ELEM(*image, i, (j + 1) * channel + c)) - PeekA(@CV_IMAGE_ELEM(*image, i, j * channel + c)))
      Next
    Next
  Next
EndProcedure

Procedure GetGradientY(*image.IplImage, *gy.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  cvSetZero(*gy)

  For i = 0 To h - 2
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*gy, i, (j * channel + c) * 4), PeekA(@CV_IMAGE_ELEM(*image, (i + 1), j * channel + c)) - PeekA(@CV_IMAGE_ELEM(*image, i, j * channel + c)))
      Next
    Next
  Next
EndProcedure

Procedure LapX(*image.IplImage, *gxx.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  cvSetZero(*gxx)

  For i = 0 To h - 1
    For j = 0 To w - 2
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*gxx, i, ((j + 1) * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*image, i, ((j + 1) * channel + c) * 4)) - PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + c) * 4)))
      Next
    Next
  Next
EndProcedure

Procedure LapY(*image.IplImage, *gyy.IplImage)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  cvSetZero(*gyy)

  For i = 0 To h - 2
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*gyy, (i + 1), (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*image, (i + 1), (j * channel + c) * 4)) - PeekF(@CV_IMAGE_ELEM(*image, i, (j * channel + c) * 4)))
      Next
    Next
  Next
EndProcedure

Procedure Dst(Array gtest.d(1), Array gfinal.d(1), h, w)
  *temp.CvMat = cvCreateMat(2 * h + 2, 1, CV_MAKETYPE(#CV_32F, 1))
  *res.CvMat = cvCreateMat(h, 1, CV_MAKETYPE(#CV_32F, 1))
  Dim *planes1.CvMat(2)
  Dim *planes2.CvMat(2)

  For rtnCount = 0 To 2 - 1
    *planes1(rtnCount) = cvCreateMat(*temp\rows, *temp\cols, CV_MAKETYPE(#CV_32F, 1))
    *planes2(rtnCount) = cvCreateMat(*temp\rows, *temp\cols, CV_MAKETYPE(#CV_32F, 1))
  Next
  *complex.CvMat = cvCreateMat(*temp\rows, *temp\cols, CV_MAKETYPE(#CV_32F, 2))

  For i = 0 To w - 1
    cvmSet(*temp, 0, 0, 0)
    r = 1

    For j = 0 To h - 1
      idx = UnsignedLong(j * w + i)
      cvmSet(*temp, r, 0, gtest(idx))
      r + 1
    Next
    cvmSet(*temp, h + 1, 0, 0)
    r = h + 2

    For j = h - 1 To 0 Step -1
      idx = UnsignedLong(j * w + i)
      cvmSet(*temp, r, 0, -1 * gtest(idx))
      r + 1
    Next
    cvCopy(*temp, *planes1(0), #Null)
    cvSetZero(*planes1(1))
    cvMerge(*planes1(0), *planes1(1), #Null, #Null, *complex)
    cvDFT(*complex, *complex, #CV_DXT_FORWARD, 0)
    cvSetZero(*planes2(0))
    cvSetZero(*planes2(1))
    cvSplit(*complex, *planes2(0), *planes2(1), #Null, #Null)
    fac.d = -2
    z = 0

    For c = 1 To h
      cvmSet(*res, z, 0, cvmGet(*planes2(1), c, 0) / fac)
      z + 1
    Next
    z = 0

    For q = 0 To h - 1
      idx = UnsignedLong(q * w + i)
      gfinal(idx) = cvmGet(*res, z, 0)
      z + 1
    Next
  Next
  cvReleaseMat(@*complex)

  For rtnCount = 0 To 2 - 1
    cvReleaseMat(@*planes2(rtnCount))
    cvReleaseMat(@*planes1(rtnCount))
  Next
  cvReleaseMat(@*res)
  cvReleaseMat(@*temp)
EndProcedure

Procedure iDst(Array gtest.d(1), Array gfinal.d(1), h, w)
  nn = h + 1
  Dst(gtest(), gfinal(), h, w)

  For i = 0 To h - 1
    For j = 0 To w - 1
      idx = UnsignedLong(i * w + j)
      gfinal(idx) = 2 * gfinal(idx) / nn
    Next
  Next
EndProcedure

Procedure Transpose(Array mat.d(1), Array mat_t.d(1), h, w)
  *temp.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

  For i = 0 To h - 1
    For j = 0 To w - 1
      idx = UnsignedLong(i * w + j)
      cvmSet(*temp, i, j, mat(idx))
    Next
  Next
  *temp_t.CvMat = cvCreateMat(w, h, CV_MAKETYPE(#CV_32F, 1))
  cvTranspose(*temp, *temp_t)

  For i = 0 To w - 1
    For j = 0 To h - 1
      idx = UnsignedLong(i * h + j)
      mat_t(idx) = cvmGet(*temp_t, i, j)
    Next
  Next
  cvReleaseMat(@*temp_t)
  cvReleaseMat(@*temp)
EndProcedure

Procedure PoissonSolver(*image.IplImage, *gxx.IplImage, *gyy.IplImage, *result.CvMat)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  *lap.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)

  For i = 0 To h - 1
    For j = 0 To w - 1
      PokeF(@CV_IMAGE_ELEM(*lap, i, j * 4), PeekF(@CV_IMAGE_ELEM(*gxx, i, j * 4)) + PeekF(@CV_IMAGE_ELEM(*gyy, i, j * 4)))
    Next
  Next
  temp.CvMat
  *bound.CvMat = cvGetMat(*image, @temp, #Null, 0)

  For i = 1 To h - 2
    For j = 1 To w - 2
      PokeA(@*bound\ptr\b + i * *bound\Step + j, 0)
    Next
  Next

  Dim f_bp.d(h * w)

  For i = 1 To h - 2
    For j = 1 To w - 2
      idx = UnsignedLong(i * w + j)
      f_bp(idx) = -4 * PeekA(@*bound\ptr\b + i * *bound\Step + j) + PeekA(@*bound\ptr\b + i * *bound\Step + (j + 1)) + PeekA(@*bound\ptr\b + i * *bound\Step + (j - 1)) + PeekA(@*bound\ptr\b + (i - 1) * *bound\Step + j) + PeekA(@*bound\ptr\b + (i + 1) * *bound\Step + j)
    Next
  Next
  *diff.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_32F, 1))

  For i = 0 To h - 1
    For j = 0 To w - 1
      idx = UnsignedLong(i * w + j)
      cvmSet(*diff, i, j, PeekF(@CV_IMAGE_ELEM(*lap, i, j * 4)) - f_bp(idx))
    Next
  Next

  Dim gtest.d((h - 2) * (w - 2))

  For i = 0 To h - 3
    For j = 0 To w - 3
      idx = UnsignedLong(i * (w - 2) + j)
      gtest(idx) = cvmGet(*diff, i + 1, j + 1)
    Next
  Next

  Dim gfinal.d((h - 2) * (w - 2))
  Dim gfinal_t.d((h - 2) * (w - 2))
  Dim denom.d((h - 2) * (w - 2))
  Dim f3.d((h - 2) * (w - 2))
  Dim f3_t.d((h - 2) * (w - 2))
  Dim image_d.d(h * w)
  Dst(gtest(), gfinal(), h - 2, w - 2)
  Transpose(gfinal(), gfinal_t(), h - 2, w - 2)
  Dst(gfinal_t(), gfinal(), w - 2, h - 2)  
  Transpose(gfinal(), gfinal_t(), w - 2, h - 2)
  cy = 1

  For i = 0 To w - 3
    cx = 1

    For j = 0 To h - 3
      idx = UnsignedLong(j * (w - 2) + i)
      denom(idx) = 2 * Cos(#PI * cy / (w - 1)) - 2 + 2 * Cos(#PI * cx / (h - 1)) - 2
      cx + 1
    Next
    cy + 1
  Next

  For idx = 0 To UnsignedLong((w - 2) * (h - 2) - 1)
    gfinal_t(idx) / denom(idx)
  Next  
  iDst(gfinal_t(), f3(), h - 2, w - 2)
  Transpose(f3(), f3_t(), h - 2, w - 2)
  iDst(f3_t(), f3(), w - 2, h - 2)
  Transpose(f3(), f3_t(), w - 2, h - 2)

  For i = 0 To h - 1
    For j = 0 To w - 1
      idx = UnsignedLong(i * w + j)
      image_d(idx) = PeekA(@CV_IMAGE_ELEM(*image, i, j))
    Next
  Next

  For i = 1 To h - 2
    id2 = 0

    For j = 1 To w - 2
      idx = UnsignedLong(i * w + j)
      idx1 = UnsignedLong(id1 * (w - 2) + id2)
      image_d(idx) = f3_t(idx1)
      id2 + 1
    Next
    id1 + 1
  Next

  For i = 0 To h - 1
    For j = 0 To w - 1
      idx = UnsignedLong(i * w + j)

      If image_d(idx) <= 0
        PokeA(@*result\ptr\b + i * *result\Step + j, 0)
      ElseIf image_d(idx) >= 255
        PokeA(@*result\ptr\b + i * *result\Step + j, 255)
      Else
        PokeA(@*result\ptr\b + i * *result\Step + j, image_d(idx))
      EndIf
    Next
  Next
  cvReleaseMat(@*diff)
  cvReleaseImage(@*lap)
EndProcedure

Procedure PoissonBlend(*image.IplImage, *mask.IplImage, posX, posY)
  w = *image\width
  h = *image\height
  channel = *image\nChannels
  wMask = *mask\width
  hMask = *mask\height
  channel1 = *mask\nChannels
  *grx.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  *gry.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  *sgx.IplImage = cvCreateImage(wMask, hMask, #IPL_DEPTH_32F, 3)
  *sgy.IplImage = cvCreateImage(wMask, hMask, #IPL_DEPTH_32F, 3)
  *S.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)
  *ero.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)
  *res.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)
  cvSetZero(*S)
  cvSetZero(*res)
  GetGradientX(*image, *grx)
  GetGradientY(*image, *gry)
  GetGradientX(*mask, *sgx)
  GetGradientY(*mask, *sgy)

  For i = posX To posX + wMask - 1
    jj = posY

    For j = 0 To hMask - 2
      For c = 0 To channel1 - 1
        PokeA(@CV_IMAGE_ELEM(*S, jj, i * channel1 + c), 255)
      Next
      jj + 1
    Next
  Next
  *bmaskx.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*S, *bmaskx, 1 / 255, 0)
  *bmasky.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*S, *bmasky, 1 / 255, 0)

  For i = posX To posX + wMask - 1
    jj = posY

    For j = 0 To hMask - 2
      For c = 0 To channel1 - 1
        PokeF(@CV_IMAGE_ELEM(*bmaskx, jj, (i * channel1 + c) * 4), PeekF(@CV_IMAGE_ELEM(*sgx, j, (ii * channel1 + c) * 4)))
        PokeF(@CV_IMAGE_ELEM(*bmasky, jj, (i * channel1 + c) * 4), PeekF(@CV_IMAGE_ELEM(*sgy, j, (ii * channel1 + c) * 4)))
      Next
      jj + 1
    Next
    ii + 1
  Next
  *element = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  cvErode(*S, *ero, *element, 1)
  *smask.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*ero, *smask, 1 / 255, 0)
  *srx32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *srx32, 1 / 255, 0)
  *sry32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *sry32, 1 / 255, 0)

  For i = 0 To h - 1
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*srx32, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*bmaskx, i, (j * channel + c) * 4)) * PeekF(@CV_IMAGE_ELEM(*smask, i, (j * channel + c) * 4)))
        PokeF(@CV_IMAGE_ELEM(*sry32, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*bmasky, i, (j * channel + c) * 4)) * PeekF(@CV_IMAGE_ELEM(*smask, i, (j * channel + c) * 4)))
      Next
    Next
  Next
  *magnitude.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *magnitude, 1 / 255, 0)

  For i = 0 To h - 1
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*magnitude, i, (j * channel + c) * 4), Sqr(Pow(PeekF(@CV_IMAGE_ELEM(*srx32, i, (j * channel + c) * 4)), 2) + Pow(PeekF(@CV_IMAGE_ELEM(*sry32, i, (j * channel + c) * 4)), 2)))
      Next
    Next
  Next
  *srx_32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *srx_32, 1 / 255, 0)
  *sry_32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *sry_32, 1 / 255, 0)
  alpha.f = 0.2
  beta.f = 0.4

  For i = 0 To h - 1
    For j = 0 To w - 1
      For c = 0 To channel - 1
        If PeekF(@CV_IMAGE_ELEM(*srx32, i, (j * channel + c) * 4)) <> 0
          PokeF(@CV_IMAGE_ELEM(*srx_32, i, (j * channel + c) * 4), Pow(alpha, beta) * PeekF(@CV_IMAGE_ELEM(*srx32, i, (j * channel + c) * 4)) * Pow(PeekF(@CV_IMAGE_ELEM(*magnitude, i, (j * channel + c) * 4)), -1 * beta))
          PokeF(@CV_IMAGE_ELEM(*sry_32, i, (j * channel + c) * 4), Pow(alpha, beta) * PeekF(@CV_IMAGE_ELEM(*sry32, i, (j * channel + c) * 4)) * Pow(PeekF(@CV_IMAGE_ELEM(*magnitude, i, (j * channel + c) * 4)), -1 * beta))
        EndIf
      Next
    Next
  Next
  cvNot(*ero, *ero)
  *smask1.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*ero, *smask1, 1 / 255, 0)
  *grx32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *grx32, 1 / 255, 0)
  *gry32.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  cvConvertScale(*res, *gry32, 1 / 255, 0)

  For i = 0 To h - 1
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*grx32, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*grx, i, (j * channel + c) * 4)) * PeekF(@CV_IMAGE_ELEM(*smask1, i, (j * channel + c) * 4)))
        PokeF(@CV_IMAGE_ELEM(*gry32, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*gry, i, (j * channel + c) * 4)) * PeekF(@CV_IMAGE_ELEM(*smask1, i, (j * channel + c) * 4)))
      Next
    Next
  Next
  *fx.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  *fy.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)

  For i = 0 To h - 1
    For j = 0 To w - 1
      For c = 0 To channel - 1
        PokeF(@CV_IMAGE_ELEM(*fx, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*grx32, i, (j * channel + c) * 4)) + PeekF(@CV_IMAGE_ELEM(*srx_32, i, (j * channel + c) * 4)))
        PokeF(@CV_IMAGE_ELEM(*fy, i, (j * channel + c) * 4), PeekF(@CV_IMAGE_ELEM(*gry32, i, (j * channel + c) * 4)) + PeekF(@CV_IMAGE_ELEM(*sry_32, i, (j * channel + c) * 4)))
      Next
    Next
  Next
  *gxx.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  *gyy.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 3)
  LapX(*fx, *gxx)
  LapY(*fy, *gyy)
  *b_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
  *g_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
  *r_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 1)
  cvSplit(*image, *b_channel, *g_channel, *r_channel, #Null)
  *bx_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  *gx_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  *rx_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  cvSplit(*gxx, *bx_channel, *gx_channel, *rx_channel, #Null)
  *by_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  *gy_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  *ry_channel.IplImage = cvCreateImage(w, h, #IPL_DEPTH_32F, 1)
  cvSplit(*gyy, *by_channel, *gy_channel, *ry_channel, #Null)
  *b_result.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_8U, 1))
  *g_result.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_8U, 1))
  *r_result.CvMat = cvCreateMat(h, w, CV_MAKETYPE(#CV_8U, 1))

  Repeat
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)
  Until keyPressed = 13 Or keyPressed = 27 Or keyPressed = 32 Or exitCV

  If keyPressed = 32
    font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
    cvPutText(*image, "Working...", 20, 40, @font, 0, 0, 255, 0)
    cvShowImage(#CV_WINDOW_NAME, *image)
    cvWaitKey(100)
    PoissonSolver(*b_channel, *bx_channel, *by_channel, *b_result)
    PoissonSolver(*g_channel, *gx_channel, *gy_channel, *g_result)
    PoissonSolver(*r_channel, *rx_channel, *ry_channel, *r_result)
    *final.IplImage = cvCreateImage(w, h, #IPL_DEPTH_8U, 3)

    For i = 0 To h - 1
      For j = 0 To w - 1
       PokeA(@CV_IMAGE_ELEM(*final, i, j * 3 + 0), PeekA(@*b_result\ptr\b + i * *b_result\Step + j))
       PokeA(@CV_IMAGE_ELEM(*final, i, j * 3 + 1), PeekA(@*g_result\ptr\b + i * *g_result\Step + j))
       PokeA(@CV_IMAGE_ELEM(*final, i, j * 3 + 2), PeekA(@*r_result\ptr\b + i * *r_result\Step + j))
      Next
    Next
  EndIf

  If keyPressed = 13 : exitCV = -1 : EndIf

  cvReleaseMat(@*r_result)
  cvReleaseMat(@*g_result)
  cvReleaseMat(@*b_result)
  cvReleaseImage(@*ry_channel)
  cvReleaseImage(@*gy_channel)
  cvReleaseImage(@*by_channel)
  cvReleaseImage(@*rx_channel)
  cvReleaseImage(@*gx_channel)
  cvReleaseImage(@*bx_channel)
  cvReleaseImage(@*r_channel)
  cvReleaseImage(@*g_channel)
  cvReleaseImage(@*b_channel)
  cvReleaseImage(@*gyy)
  cvReleaseImage(@*gxx)
  cvReleaseImage(@*fy)
  cvReleaseImage(@*fx)
  cvReleaseImage(@*gry32)
  cvReleaseImage(@*grx32)
  cvReleaseImage(@*smask1)
  cvReleaseImage(@*magnitude)
  cvReleaseImage(@*sry_32)
  cvReleaseImage(@*srx_32)
  cvReleaseImage(@*sry32)
  cvReleaseImage(@*srx32)
  cvReleaseImage(@*smask)
  cvReleaseImage(@*bmasky)
  cvReleaseImage(@*bmaskx)
  cvReleaseImage(@*res)
  cvReleaseImage(@*ero)
  cvReleaseImage(@*S)
  cvReleaseImage(@*sgy)
  cvReleaseImage(@*sgx)
  cvReleaseImage(@*gry)
  cvReleaseImage(@*grx)
  ProcedureReturn *final
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
    cvMoveWindow(#CV_WINDOW_NAME, 25, 25)
    ToolTip(window_handle, #CV_DESCRIPTION)

    Select nBlend
      Case 0
        *roi.IplImage = cvCreateImage(65, 65, *resize\depth, *resize\nChannels)
        x = (*resize\width / 2) - (*roi\width / 2) - 5
        y = (*resize\height / 2) - (*roi\height / 2) - 5
        cvSetImageROI(*resize, x, y, 65, 65)
      Case 1
        *roi.IplImage = cvCreateImage(40, 40, *resize\depth, *resize\nChannels)
        x = 35
        y = (*resize\height / 2) - (*roi\height / 2) + 5
        cvSetImageROI(*resize, x, y, 40, 40)
    EndSelect
    cvCopy(*resize, *roi, #Null)
    cvResetImageROI(*resize)

    If *resize\nChannels = 3
      BringWindowToTop(hWnd)
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
      *blend.IplImage = PoissonBlend(*resize, *roi, x, y)

      If *blend
        *param\Pointer1 = *blend

        Repeat
          If *blend
            cvShowImage(#CV_WINDOW_NAME, *blend)
            keyPressed = cvWaitKey(0)
          EndIf
        Until keyPressed = 13 Or keyPressed = 27 Or exitCV
        cvReleaseImage(@*blend)
      Else
        If exitCV = -1 : keyPressed = 13 : EndIf
      EndIf
      FreeMemory(*param)
    Else
      MessageRequester(#CV_WINDOW_NAME, "Process Cancelled..." + #LF$ + #LF$ + "Image does not meet the channel requirements.", #MB_ICONERROR)
    EndIf
    cvReleaseImage(@*roi)
    cvReleaseImage(@*resize)
    cvReleaseImage(@*image)
    cvDestroyAllWindows()

    If keyPressed = 13
      exitCV = #False
      nBlend = (nBlend + 1) % 2
      OpenCV("images/blend5_" + Str(nBlend + 1) + ".jpg")
    EndIf
  EndIf
EndProcedure

OpenCV("images/blend5_1.jpg")
; IDE Options = PureBasic 5.50 (Windows - x86)
; CursorPosition = 1
; Folding = --
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\