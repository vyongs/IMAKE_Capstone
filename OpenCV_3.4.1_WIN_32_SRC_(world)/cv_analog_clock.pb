IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Creates an analog clock synchronized with the system time."

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
*image.IplImage = cvCreateImage(640, 640, #IPL_DEPTH_8U, 3) : cvSetZero(*image)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
Dim s1(60, 2) : Dim s2(60, 2) : Dim h1(12, 2) : Dim h2(12, 2)
s1(0, 0) = 320 : s1(0, 1) = 25 : s1(1, 0) = 351 : s1(1, 1) = 27 : s1(2, 0) = 381 : s1(2, 1) = 31
s1(3, 0) = 411 : s1(3, 1) = 39 : s1(4, 0) = 440 : s1(4, 1) = 51 : s1(5, 0) = 468 : s1(5, 1) = 65
s1(6, 0) = 493 : s1(6, 1) = 81 : s1(7, 0) = 517 : s1(7, 1) = 101 : s1(8, 0) = 539 : s1(8, 1) = 123
s1(9, 0) = 559 : s1(9, 1) = 147 : s1(10, 0) = 575 : s1(10, 1) = 173 : s1(11, 0) = 589 : s1(11, 1) = 200
s1(12, 0) = 601 : s1(12, 1) = 229 : s1(13, 0) = 609 : s1(13, 1) = 259 : s1(14, 0) = 613 : s1(14, 1) = 289
s1(15, 0) = 615 : s1(15, 1) = 320 : s1(16, 0) = 613 : s1(16, 1) = 351 : s1(17, 0) = 609 : s1(17, 1) = 381
s1(18, 0) = 601 : s1(18, 1) = 411 : s1(19, 0) = 589 : s1(19, 1) = 440 : s1(20, 0) = 575 : s1(20, 1) = 468
s1(21, 0) = 559 : s1(21, 1) = 493 : s1(22, 0) = 539 : s1(22, 1) = 517 : s1(23, 0) = 517 : s1(23, 1) = 539
s1(24, 0) = 493 : s1(24, 1) = 559 : s1(25, 0) = 468 : s1(25, 1) = 575 : s1(26, 0) = 440 : s1(26, 1) = 589
s1(27, 0) = 411 : s1(27, 1) = 601 : s1(28, 0) = 381 : s1(28, 1) = 609 : s1(29, 0) = 351 : s1(29, 1) = 613
s1(30, 0) = 320 : s1(30, 1) = 615 : s1(31, 0) = 289 : s1(31, 1) = 613 : s1(32, 0) = 259 : s1(32, 1) = 609
s1(33, 0) = 229 : s1(33, 1) = 601 : s1(34, 0) = 200 : s1(34, 1) = 589 : s1(35, 0) = 173 : s1(35, 1) = 575
s1(36, 0) = 147 : s1(36, 1) = 559 : s1(37, 0) = 123 : s1(37, 1) = 539 : s1(38, 0) = 101 : s1(38, 1) = 517
s1(39, 0) = 81 : s1(39, 1) = 493 : s1(40, 0) = 65 : s1(40, 1) = 468 : s1(41, 0) = 51 : s1(41, 1) = 440
s1(42, 0) = 39 : s1(42, 1) = 411 : s1(43, 0) = 31 : s1(43, 1) = 381 : s1(44, 0) = 27 : s1(44, 1) = 351
s1(45, 0) = 25 : s1(45, 1) = 320 : s1(46, 0) = 27 : s1(46, 1) = 289 : s1(47, 0) = 31 : s1(47, 1) = 259
s1(48, 0) = 39 : s1(48, 1) = 229 : s1(49, 0) = 51 : s1(49, 1) = 200 : s1(50, 0) = 65 : s1(50, 1) = 173
s1(51, 0) = 81 : s1(51, 1) = 147 : s1(52, 0) = 101 : s1(52, 1) = 123 : s1(53, 0) = 123 : s1(53, 1) = 101
s1(54, 0) = 147 : s1(54, 1) = 81 : s1(55, 0) = 172 : s1(55, 1) = 65 : s1(56, 0) = 200 : s1(56, 1) = 51
s1(57, 0) = 229 : s1(57, 1) = 39 : s1(58, 0) = 259 : s1(58, 1) = 31 : s1(59, 0) = 289 : s1(59, 1) = 27
s2(0, 0) = 320 : s2(0, 1) = 5 : s2(1, 0) = 353 : s2(1, 1) = 7 : s2(2, 0) = 385 : s2(2, 1) = 12
s2(3, 0) = 417 : s2(3, 1) = 20 : s2(4, 0) = 448 : s2(4, 1) = 32 : s2(5, 0) = 478 : s2(5, 1) = 47
s2(6, 0) = 505 : s2(6, 1) = 65 : s2(7, 0) = 531 : s2(7, 1) = 86 : s2(8, 0) = 554 : s2(8, 1) = 109
s2(9, 0) = 575 : s2(9, 1) = 135 : s2(10, 0) = 593 : s2(10, 1) = 163 : s2(11, 0) = 608 : s2(11, 1) = 192
s2(12, 0) = 620 : s2(12, 1) = 223 : s2(13, 0) = 628 : s2(13, 1) = 255 : s2(14, 0) = 633 : s2(14, 1) = 287
s2(15, 0) = 635 : s2(15, 1) = 320 : s2(16, 0) = 633 : s2(16, 1) = 353 : s2(17, 0) = 628 : s2(17, 1) = 385
s2(18, 0) = 620 : s2(18, 1) = 417 : s2(19, 0) = 608 : s2(19, 1) = 448 : s2(20, 0) = 593 : s2(20, 1) = 478
s2(21, 0) = 575 : s2(21, 1) = 505 : s2(22, 0) = 554 : s2(22, 1) = 531 : s2(23, 0) = 531 : s2(23, 1) = 554
s2(24, 0) = 505 : s2(24, 1) = 575 : s2(25, 0) = 478 : s2(25, 1) = 593 : s2(26, 0) = 448 : s2(26, 1) = 608
s2(27, 0) = 417 : s2(27, 1) = 620 : s2(28, 0) = 385 : s2(28, 1) = 628 : s2(29, 0) = 353 : s2(29, 1) = 633
s2(30, 0) = 320 : s2(30, 1) = 635 : s2(31, 0) = 287 : s2(31, 1) = 633 : s2(32, 0) = 255 : s2(32, 1) = 628
s2(33, 0) = 223 : s2(33, 1) = 620 : s2(34, 0) = 192 : s2(34, 1) = 608 : s2(35, 0) = 163 : s2(35, 1) = 593
s2(36, 0) = 135 : s2(36, 1) = 575 : s2(37, 0) = 109 : s2(37, 1) = 554 : s2(38, 0) = 86 : s2(38, 1) = 531
s2(39, 0) = 65 : s2(39, 1) = 505 : s2(40, 0) = 47 : s2(40, 1) = 478 : s2(41, 0) = 32 : s2(41, 1) = 448
s2(42, 0) = 20 : s2(42, 1) = 417 : s2(43, 0) = 12 : s2(43, 1) = 385 : s2(44, 0) = 7 : s2(44, 1) = 353
s2(45, 0) = 5 : s2(45, 1) = 320 : s2(46, 0) = 7 : s2(46, 1) = 287 : s2(47, 0) = 12 : s2(47, 1) = 255
s2(48, 0) = 20 : s2(48, 1) = 223 : s2(49, 0) = 32 : s2(49, 1) = 192 : s2(50, 0) = 47 : s2(50, 1) = 163
s2(51, 0) = 65 : s2(51, 1) = 135 : s2(52, 0) = 86 : s2(52, 1) = 109 : s2(53, 0) = 109 : s2(53, 1) = 86
s2(54, 0) = 135 : s2(54, 1) = 65 : s2(55, 0) = 162 : s2(55, 1) = 47 : s2(56, 0) = 192 : s2(56, 1) = 32
s2(57, 0) = 223 : s2(57, 1) = 20 : s2(58, 0) = 255 : s2(58, 1) = 12 : s2(59, 0) = 287 : s2(59, 1) = 7
h1(0, 0) = 320 : h1(0, 1)= 45 : h1(1, 0) = 458 : h1(1, 1) = 82 : h1(2, 0) = 558 : h1(2, 1) = 183
h1(3, 0) = 595 : h1(3, 1)= 320 : h1(4, 0) = 558 : h1(4, 1) = 458 : h1(5, 0) = 458 : h1(5, 1) = 558
h1(6, 0) = 320 : h1(6, 1)= 595 : h1(7, 0) = 183 : h1(7, 1) = 558 : h1(8, 0) = 82 : h1(8, 1) = 458
h1(9, 0) = 45 : h1(9, 1)= 320 : h1(10, 0) = 82 : h1(10, 1) = 183 : h1(11, 0) = 182 : h1(11, 1) = 82
h2(0, 0) = 320 : h2(0, 1)= 5 : h2(1, 0) = 478 : h2(1, 1) = 47 : h2(2, 0) = 593 : h2(2, 1) = 163
h2(3, 0) = 635 : h2(3, 1)= 320 : h2(4, 0) = 593 : h2(4, 1) = 478 : h2(5, 0) = 478 : h2(5, 1) = 593
h2(6, 0) = 320 : h2(6, 1)= 635 : h2(7, 0) = 163 : h2(7, 1) = 593 : h2(8, 0) = 47 : h2(8, 1) = 478
h2(9, 0) = 5 : h2(9, 1)= 320 : h2(10, 0) = 47 : h2(10, 1) = 163 : h2(11, 0) = 162 : h2(11, 1) = 47

For rtnCount = 0 To 60 - 1
  cvLine(*image, s1(rtnCount, 0), s1(rtnCount, 1), s2(rtnCount, 0), s2(rtnCount, 1), 0, 255, 0, 0, 1.5, #CV_AA, #Null)
Next

For rtnCount = 0 To 12 - 1
  cvLine(*image, h1(rtnCount, 0), h1(rtnCount, 1), h2(rtnCount, 0), h2(rtnCount, 1), 255, 255, 255, 0, 4, #CV_AA, #Null)
Next
cvCircle(*image, 320, 320, 320 - 5, 0, 0, 255, 0, 4, #CV_AA, #Null)
*reset.IplImage = cvCloneImage(*image)
LocalTime.SYSTEMTIME
hAngle.f = 210 : mAngle.f = 330 : sAngle.f = 270
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    GetLocalTime_(LocalTime)
    hour = LocalTime\wHour
    minute = LocalTime\wMinute
    second = LocalTime\wSecond

    If hour > 12 : hour - 12 : EndIf

    hAngle = (hour * 30) + (minute * 0.5) + 270
    minute + second / 60
    mAngle = minute * 6 + 270
    sAngle = second * 6 + 270

    If hAngle > 360 : hAngle - 360 : EndIf
    If mAngle > 360 : mAngle - 360 : EndIf
    If sAngle > 360 : sAngle - 360 : EndIf

    pX = Round(320 + (320 - 75) * Cos(hAngle * #PI / 180), #PB_Round_Nearest)
    pY = Round(320 + (320 - 75) * Sin(hAngle * #PI / 180), #PB_Round_Nearest)
    cvLine(*image, 320, 320, pX, pY, 255, 0, 0, 0, 8, #CV_AA, #Null)
    pX = Round(320 + (320 - 50) * Cos(mAngle * #PI / 180), #PB_Round_Nearest)
    pY = Round(320 + (320 - 50) * Sin(mAngle * #PI / 180), #PB_Round_Nearest)
    cvLine(*image, 320, 320, pX, pY, 255, 255, 0, 0, 4, #CV_AA, #Null)
    pX = Round(320 + (320 - 30) * Cos(sAngle * #PI / 180), #PB_Round_Nearest)
    pY = Round(320 + (320 - 30) * Sin(sAngle * #PI / 180), #PB_Round_Nearest)
    cvLine(*image, 320, 320, pX, pY, 0, 255, 255, 0, 1.5, #CV_AA, #Null)
    cvCircle(*image, 320, 320, 3, 0, 0, 255, 0, 5, #CV_AA, #Null)
    cvCircle(*image, 320, 320, 2, 0, 0, 0, 0, 5, #CV_AA, #Null)
    cvShowImage(#CV_WINDOW_NAME, *image)

    If tX <> pX
      sndPlaySound_("sounds/tick.wav" + Chr(0), #SND_NODEFAULT + #SND_ASYNC + #SND_FILENAME)
      tX = pX
    EndIf
    keyPressed = cvWaitKey(10)
    cvReleaseImage(@*image)
    *image = cvCloneImage(*reset)
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*reset)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\