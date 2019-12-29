IncludeFile "includes/cv_functions.pbi"

Global openCV, *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Simulates the LOMO (Leningrad Optical Mechanical Association) camera lens effect." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle LOMO effects." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the image."

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

Structure LUT_VALUES
  a.a
  b.a
  c.a
EndStructure

Procedure SetHSV(*image.IplImage, h, s, v)
  Dim lut.LUT_VALUES(256)
  *hsv.IplImage = cvCreateImage(*image\width, *image\height, #IPL_DEPTH_8U, 3)
  cvSetZero(*hsv)
  cvCvtColor(*image, *hsv, #CV_BGR2HSV, 1)
  *lut_mat.CvMat = cvCreateMatHeader(1, 256, CV_MAKETYPE(#CV_8U, 3))
  cvSetData(*lut_mat, lut(), 0)

  For i = 0 To 256 - 1
    value = i + h

    If value < 0 : value = 0 : EndIf
    If value > 255 : value = 255 : EndIf

    lut(i)\a = value
    value = i + s

    If value < 0 : value = 0 : EndIf
    If value > 255 : value = 255 : EndIf

    lut(i)\b = value
    value = i + v

    If value < 0 : value = 0 : EndIf
    If value > 255 : value = 255 : EndIf

    lut(i)\c = value
  Next
  cvLUT(*hsv, *hsv, *lut_mat)
  cvCvtColor(*hsv, *image, #CV_HSV2BGR, 1)
  cvReleaseImage(@*hsv)
EndProcedure

Procedure SetBrightnessAndContrast(*image.IplImage, Brightness, Contrast)
  Dim lut.LUT_VALUES(256)
  *lut_mat.CvMat = cvCreateMatHeader(1, 256, CV_MAKETYPE(#CV_8U, 3))
  cvSetData(*lut_mat, lut(), 0)

  If Contrast > 0
    Delta.d = 127 * Contrast / 100
    a.d = 255 / (255 - Delta * 2)
    b.d = a * (Brightness - Delta)
  Else
    Delta.d = -128 * Contrast / 100
    a.d = (256 - Delta * 2) / 255
    b.d = a * Brightness + Delta
  EndIf

  For x = 0 To 256 - 1
    y = a * x + b

    If y < 0 : y = 0 : EndIf
    If y > 255 : y = 255 : EndIf

    lut(x)\a = y
    lut(x)\b = y
    lut(x)\c = y
  Next
  cvLUT(*image, *image, *lut_mat)
  cvReleaseMat(@*lut_mat)
EndProcedure

Procedure SetGammaCurves(*image.IplImage, rIn, rOut, gIn, gOut, bIn, bOut)
  Dim lut.LUT_VALUES(256)
  rr = Log(rOut) / Log(rIn)
  rg = Log(gOut) / Log(gIn)
  rb = Log(bOut) / Log(bIn)
  *lut_mat.CvMat = cvCreateMatHeader(1, 256, CV_MAKETYPE(#CV_8U, 3))
  cvSetData(*lut_mat, lut(), 0)

  For x = 0 To 256 - 1
    y = 255 * Pow(x / 255, rb)
    lut(x)\a = y
    y = 255 * Pow(x / 255, rg)
    lut(x)\b = y
    y = 255 * Pow(x / 255, rr)
    lut(x)\c = y
  Next
  cvLUT(*image, *image, *lut_mat)
  cvReleaseMat(@*lut_mat)
EndProcedure

Procedure.d GetDistance(x1, y1, x2, y2)
  ProcedureReturn Sqr(Pow(x1 - x2, 2) + Pow(y1 - y2, 2))
EndProcedure

Procedure NaturalVignetting(imageWidth, imageHeight, maxAngle.f)
  maxRad.d = Sqr(Pow(imageWidth / 2, 2) + Pow(imageHeight / 2, 2))
  *eikona.IplImage = cvCreateImage(imageWidth, imageHeight, #IPL_DEPTH_64F, 1)
  cvSet(*eikona, 1, 0, 0, 0, #Null)

  For i = 0 To *eikona\height - 1
    For j = 0 To *eikona\width - 1
      distance.d = GetDistance(imageWidth / 2, imageHeight / 2, j, i)
      cvSet2D(*eikona, i, j, Pow(Cos(distance / maxRad * maxAngle), 4), 0, 0, 0)
    Next
  Next
  ProcedureReturn *eikona
EndProcedure

Procedure MechanicalVignetting(imageWidth, imageHeight, fallOff)
  radius.d = imageWidth / 2 * 95 / 100
  maxRad.d = Sqr(Pow(imageWidth / 2, 2) + Pow(imageHeight / 2, 2))
  *eikona.IplImage = cvCreateImage(imageWidth, imageHeight, #IPL_DEPTH_64F, 1)
  cvSet(*eikona, 1, 0, 0, 0, #Null)

  For i = 0 To *eikona\height - 1
    For j = 0 To *eikona\width - 1
      distance.d = GetDistance(imageWidth / 2, imageHeight / 2, j, i)

      If distance > radius
        If distance > radius + fallOff
          cvSet2D(*eikona, i, j, 0, 0, 0, 0)
        Else
          cvSet2D(*eikona, i, j, 1 - Pow((distance - radius) / fallOff, 2), 0, 0, 0)
        EndIf
      EndIf
    Next
  Next
  ProcedureReturn *eikona
EndProcedure

Procedure ArtificialVignetting(*bgr.IplImage, maxAngle.f, vStyle, vSize)
  *lab.IplImage = cvCreateImage(*bgr\width, *bgr\height, #IPL_DEPTH_8U, 3)

  If vStyle
    *reference.IplImage = NaturalVignetting(*lab\width, *lab\height, maxAngle)
  Else
    *reference.IplImage = MechanicalVignetting(*lab\width, *lab\height, vSize)
  EndIf
  cvCvtColor(*bgr, *lab, #CV_BGR2Lab, 1)
  scalar1.CvScalar
  scalar2.CvScalar

  For i = 0 To *lab\height - 1
    For j = 0 To *lab\width - 1
      cvGet2D(@scalar1, *lab, i, j)
      cvGet2D(@scalar2, *reference, i, j)
      scalar1\val[0] * scalar2\val[0]
      cvSet2D(*lab, i, j, scalar1\val[0], scalar1\val[1], scalar1\val[2], scalar1\val[3])
    Next
  Next
  cvCvtColor(*lab, *bgr, #CV_Lab2BGR, 1)
 cvReleaseImage(@*reference)
 cvReleaseImage(@*lab)
EndProcedure

Procedure ProcessVignetting(*image.IplImage, degrees, vStyle, vSize)
  maxAngle.f = degrees * #PI / 180
  ArtificialVignetting(*image, maxAngle, vStyle, vSize)
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

    If *resize\width > 200 And *resize\height > 200 And *resize\nChannels = 3
      *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
      *param\Pointer1 = *resize
      *param\Value = window_handle
      cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

      Repeat
        cvShowImage(#CV_WINDOW_NAME, *resize)
        keyPressed = cvWaitKey(0)
      Until keyPressed = 27 Or keyPressed = 32 Or exitCV

      If keyPressed = 32
        *reset.IplImage = cvCloneImage(*resize)
        SetHSV(*resize, 0, 25, 0)
        SetBrightnessAndContrast(*resize, 0, 20)
        SetGammaCurves(*resize, 100, 138, 195, 175, 190, 205)
        ProcessVignetting(*resize, 30, 1, 0)

        Repeat
          If *resize
            cvShowImage(#CV_WINDOW_NAME, *resize)
            keyPressed = cvWaitKey(0)

            Select keyPressed
              Case 13
                lomo = 1
                cvReleaseImage(@*resize)
                *resize = cvCloneImage(*reset)
                *param\Pointer1 = *resize
              Case 32
                lomo = (lomo + 1) % 2
                cvReleaseImage(@*resize)
                *resize = cvCloneImage(*reset)

                Select lomo
                  Case 0
                    SetHSV(*resize, 0, 25, 0)
                    SetBrightnessAndContrast(*resize, 0, 20)
                    SetGammaCurves(*resize, 100, 138, 195, 175, 190, 205)
                    ProcessVignetting(*resize, 30, 1, 0)
                  Case 1
                    SetHSV(*resize, 0, 25, 0)
                    SetBrightnessAndContrast(*resize, 0, 20)
                    SetGammaCurves(*resize, 100, 138, 195, 175, 190, 205)
                    ProcessVignetting(*resize, 30, 0, 20)
                EndSelect
                *param\Pointer1 = *resize
            EndSelect
          EndIf
        Until keyPressed = 27 Or exitCV
        cvReleaseImage(@*reset)
      EndIf
      FreeMemory(*param)
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

OpenCV("images/seams1.jpg")
; IDE Options = PureBasic 5.31 Beta 1 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\