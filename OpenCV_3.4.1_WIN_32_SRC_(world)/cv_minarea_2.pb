IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Finds the minimal area of a point set wrapping it in a triangle and a circle." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Create a new point set."

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
*image.IplImage = cvCreateImage(500, 500, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
rng = cvRNG(Random(2147483647))
*points.CvPoint
*pointMat.CvMat
*triangle.CvMat = cvCreateMat(3, 1, CV_MAKETYPE(#CV_32F, 2))
pt1.CvPoint
pt2.CvPoint
center.CvPoint2D32f
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    count = UnsignedLong(cvRandInt(rng)) % 100 + 1

    If count < 6 : count = 6 : EndIf

    *points = AllocateMemory(count * SizeOf(CvPoint))
    *pointMat = cvMat(1, count, CV_MAKETYPE(#CV_32S, 2), *points)

    For i = 0 To count - 1
      pt1\x = Random(*image\width - 175, 175)
      pt1\y = Random(*image\height - 175, 175)
      PokeL(@*points\x + i * 8, pt1\x)
      PokeL(@*points\y + i * 8, pt1\y)
    Next
    cvMinEnclosingTriangle(*pointMat, *triangle, @area.d)
    cvMinEnclosingCircle(*pointMat, @center, @radius.f)
    cvSetZero(*image)
    x = Round(center\x, #PB_Round_Nearest)
    y = Round(center\y, #PB_Round_Nearest)
    cvCircle(*image, x, y, Round(radius, #PB_Round_Nearest), 0, 255, 0, 0, 1, #CV_AA, #Null)

    For i = 0 To 3 - 1
      x1 = PeekF(@*triangle\fl\f + i * *triangle\Step + 0)
      y1 = PeekF(@*triangle\fl\f + i * *triangle\Step + 4)
      x2 = PeekF(@*triangle\fl\f + ((i + 1) % 3) * *triangle\Step + 0)
      y2 = PeekF(@*triangle\fl\f + ((i + 1) % 3) * *triangle\Step + 4)
      cvLine(*image, x1, y1, x2, y2, 0, 255, 255, 0, 2, #CV_AA, #Null)
    Next

    For i = 0 To count - 1
      pt1\x = PeekL(@*points\x + i * 8)
      pt1\y = PeekL(@*points\y + i * 8)
      cvCircle(*image, pt1\x, pt1\y, 3, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
    Next
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)
    FreeMemory(*points)
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.31 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\