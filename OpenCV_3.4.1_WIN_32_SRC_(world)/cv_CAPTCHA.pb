IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "CAPTCHA: Completely Automated Public Turing test to tell Computers and Humans Apart." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Generate new CAPTCHA."

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

#CHAR_WIDTH = 160
#CHAR_HEIGHT = 140
#CAPTCHA_LENGTH = 8

Procedure Transform(*image.CvMat)
  Dim srcPoint.CvPoint2D32f(4)
  Dim dstPoint.CvPoint2D32f(4)
  srcPoint(0)\x = 0
  srcPoint(0)\y = 0
  srcPoint(1)\x = 0
  srcPoint(1)\y = #CHAR_HEIGHT
  srcPoint(2)\x = #CHAR_WIDTH
  srcPoint(2)\y = 0
  srcPoint(3)\x = #CHAR_WIDTH
  srcPoint(3)\y = #CHAR_HEIGHT
  dstPoint(0)\x = 0
  dstPoint(0)\y = 0
  dstPoint(1)\x = 0
  dstPoint(1)\y = #CHAR_HEIGHT
  dstPoint(2)\x = #CHAR_WIDTH
  dstPoint(2)\y = 0
  varWidth = #CHAR_WIDTH / Random(4, 2)
  varHeight = #CHAR_HEIGHT / Random(4, 2)
  widthWarp = #CHAR_WIDTH - varWidth + Random(32767) % varWidth
  heightWarp = #CHAR_HEIGHT - varHeight + Random(32767) % varHeight
  dstPoint(3)\x = widthWarp
  dstPoint(3)\y = heightWarp
  *perspective.CvMat = cvCreateMat(3, 3, CV_MAKETYPE(#CV_32F, 1))
  cvGetPerspectiveTransform(@srcPoint(), @dstPoint(), *perspective)
  cvWarpPerspective(*image, *image, *perspective, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 255, 255, 255, 0)
  cvReleaseMat(@*perspective)
EndProcedure

Procedure Rotate(*input.CvMat)
  sign = Random(32767) % 2

  If sign = 0 : sign = -1 : EndIf

  angle = Random(32767) % 45 * sign
  *rotate.CvMat = cvCreateMat(2, 3, CV_MAKETYPE(#CV_32F, 1))
  cv2DRotationMatrix(*input\cols / 2, *input\rows / 2, angle, 1, *rotate)
  cvWarpAffine(*input, *input, *rotate, #CV_INTER_LINEAR | #CV_WARP_FILL_OUTLIERS, 255, 255, 255, 0)
EndProcedure

Procedure Scale(*input.CvMat, height.f, width.f)
  h = Random(32767) % 20 * -1
  w = Random(32767) % 20 * -1
  height = h + height
  width = w + width
  *output.CvMat = cvCreateMat(height, width, CV_MAKETYPE(#CV_8U, 3))
  cvResize(*input, *output, #CV_INTER_AREA)
  ProcedureReturn *output
EndProcedure

Procedure AddLines(*image.IplImage)
  For rtnCount = 0 To #CAPTCHA_LENGTH
    startX = Random(32767) % *image\width
    endX = Random(32767) % *image\width
    startY = Random(32767) % *image\height
    endY = Random(32767) % *image\height
    cvLine(*image, startX, startY, endX, endY, Random(255), Random(255), Random(255), 0, Random(3, 1), #CV_AA, #Null)
  Next
EndProcedure

Procedure AddNoise(*image.IplImage)
  For rtnCount = 0 To 250
    x = Random(32767) % *image\width
    y = Random(32767) % *image\height

    If rtnCount % 20
      cvCircle(*image, x, y, Random(3, 1), Random(255), Random(255), Random(255), 0, #CV_FILLED, #CV_AA, #Null)
    Else
      cvCircle(*image, x, y, Random(50, 10), Random(255), Random(255), Random(255), 0, 1, #CV_AA, #Null)
    EndIf
  Next
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
*image.IplImage = cvCreateImage(#CHAR_WIDTH * #CAPTCHA_LENGTH, #CHAR_HEIGHT, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, #CHAR_WIDTH * #CAPTCHA_LENGTH, #CHAR_HEIGHT)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
Dim arrChar.s(44)
arrChar(0) = "a" : arrChar(1) = "A" : arrChar(2) = "b" : arrChar(3) = "B" : arrChar(4) = "c" : arrChar(5) = "C"
arrChar(6) = "d" : arrChar(7) = "D" : arrChar(8) = "e" : arrChar(9) = "E" : arrChar(10) = "f" : arrChar(11) = "F"
arrChar(12) = "g" : arrChar(13) = "G" : arrChar(14) = "h" : arrChar(15) = "H" : arrChar(16) = "j" : arrChar(17) = "J"
arrChar(18) = "k" : arrChar(19) = "K" : arrChar(20) = "m" : arrChar(21) = "M" : arrChar(22) = "n" : arrChar(23) = "N"
arrChar(24) = "q" : arrChar(25) = "Q" : arrChar(26) = "R" : arrChar(27) = "t" : arrChar(28) = "T" : arrChar(29) = "w"
arrChar(30) = "W" : arrChar(31) = "x" : arrChar(32) = "X" : arrChar(33) = "y" : arrChar(34) = "Y" : arrChar(35) = "1"
arrChar(36) = "2" : arrChar(37) = "3" : arrChar(38) = "4" : arrChar(39) = "5" : arrChar(40) = "6" : arrChar(41) = "7"
arrChar(42) = "8" : arrChar(43) = "9"
*resize.IplImage = cvCreateImage(#CHAR_WIDTH * #CAPTCHA_LENGTH / 2 - 50, #CHAR_HEIGHT - 50, #IPL_DEPTH_8U, 3)
*char.CvMat = cvCreateMat(#CHAR_HEIGHT, #CHAR_WIDTH, CV_MAKETYPE(#CV_8U, 3))
*temp.IplImage
temp.IplImage
font.CvFont
keybd_event_(#VK_SPACE, 0, 0, 0)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *resize
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *resize
    cvShowImage(#CV_WINDOW_NAME, *resize)
    keyPressed = cvWaitKey(0)

    If keyPressed = 32
      cvSet(*image, 255, 255, 255, 0, #Null)

      For rtnCount = 0 To #CAPTCHA_LENGTH - 1
        char.s = arrChar(Random(43))
        cvSet(*char, 255, 255, 255, 0, #Null)
        cvInitFont(@font, Random(5, 2), Random(4, 3), Random(4, 3), #Null, Random(5, 2), #CV_AA)
        cvPutText(*char, char, 30, #CHAR_HEIGHT - 30, @font, Random(100), Random(100), Random(100), 0)
        Transform(*char)
        Rotate(*char)
        *scale.CvMat = Scale(*char, #CHAR_HEIGHT, #CHAR_WIDTH)
        *temp = cvGetImage(*scale, @temp)
        cvSetImageROI(*image, #CHAR_WIDTH * rtnCount, 0, *scale\cols, *scale\rows)
        cvCopy(*temp, *image, #Null)
        cvResetImageROI(*image)
        cvReleaseMat(@*scale)
      Next
      AddLines(*image)
      AddNoise(*image)
      cvResize(*image, *resize, #Null)
    EndIf
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMat(@*scale)
cvReleaseMat(@*char)
cvReleaseImage(@*resize)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\