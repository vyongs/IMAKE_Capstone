IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc, hWnd_contours

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the contour areas." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust contour level."

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
      SendMessage_(hWnd_contours, #WM_CLOSE, 0, 0)
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
  keybd_event_(#VK_RETURN, 0, 0, 0)
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
cvResizeWindow(#CV_WINDOW_NAME, 500, 500)
*image.IplImage = cvCreateImage(500, 500, #IPL_DEPTH_8U, 3)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvCreateTrackbar("Level", #CV_WINDOW_NAME, @nLevel, 4, @CvTrackbarCallback())
cvNamedWindow(#CV_WINDOW_NAME + " - Contours", #CV_WINDOW_AUTOSIZE)
hWnd_contours = GetParent_(cvGetWindowHandle(#CV_WINDOW_NAME + " - Contours"))
SendMessage_(hWnd_contours, #WM_SETICON, 0, opencv)
wStyle = GetWindowLongPtr_(hWnd_contours, #GWL_STYLE)
SetWindowLongPtr_(hWnd_contours, #GWL_STYLE, wStyle & ~(#WS_SYSMENU | #WS_MAXIMIZEBOX | #WS_SIZEBOX))
cvResizeWindow(#CV_WINDOW_NAME + " - Contours", 500, 500)
cvMoveWindow(#CV_WINDOW_NAME + " - Contours", *image\width + 50, 20)
*contour.IplImage = cvCreateImage(500, 500, #IPL_DEPTH_8U, 1)
cvSetZero(*contour)

For i = 0 To 6 - 1
  dx = (i % 2) * 250 - 30
  dy = (i / 2) * 150

  If i = 0
    For j = 0 To 10 - 1
      angle.d = (j + 5) * #PI / 21
      x1 = Round(dx + 100 + j * 10 - 80 * Cos(angle), #PB_Round_Nearest)
      y1 = Round(dy + 100 - 90 * Sin(angle), #PB_Round_Nearest)
      x2 = Round(dx + 100 + j * 10 - 30 * Cos(angle), #PB_Round_Nearest)
      y2 = Round(dy + 100 - 30 * Sin(angle), #PB_Round_Nearest)
      cvLine(*contour, x1, y1, x2, y2, 255, 255, 255, 0, 1, #CV_AA, #Null)
    Next
  EndIf
  cvEllipse(*contour, dx + 150, dy + 100, 100, 70, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 115, dy + 70, 30, 20, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 185, dy + 70, 30, 20, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 115, dy + 70, 15, 15, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 185, dy + 70, 15, 15, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 115, dy + 70, 5, 5, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 185, dy + 70, 5, 5, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 150, dy + 100, 10, 5, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 150, dy + 150, 40, 10, 0, 0, 360, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 27, dy + 100, 20, 35, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
  cvEllipse(*contour, dx + 273, dy + 100, 20, 35, 0, 0, 360, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
Next
cvShowImage(#CV_WINDOW_NAME + " - Contours", *contour)
*storage.CvMemStorage = cvCreateMemStorage(0)
cvClearMemStorage(*storage)
*contours.CvSeq
cvFindContours(*contour, *storage, @*contours, SizeOf(CvContour), #CV_RETR_TREE, #CV_CHAIN_APPROX_SIMPLE, 0, 0)
*contours = cvApproxPoly(*contours, SizeOf(CvContour), *storage, #CV_POLY_APPROX_DP, 3, 1)
BringWindowToTop(hWnd)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvSetZero(*image)
    cvDrawContours(*image, *contours, 0, 0, 255, 0, 0, 255, 0, 0, nLevel, 3, #CV_AA, 0, 0)
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)
  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMemStorage(@*storage)
cvReleaseImage(@*contour)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\