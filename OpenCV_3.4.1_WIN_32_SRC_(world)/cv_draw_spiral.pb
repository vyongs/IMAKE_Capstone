IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draw a circular or square spiral." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle spiral shape."

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

Procedure DrawSpiral(*image.IplImage, nSpiral)
  cvSetZero(*image) : nB = Random(255, 50) : nG = Random(255, 50) : nR = Random(255, 50)

  If nSpiral
    x1 = 250 : y1 = 250 : nStep2 = 1

    While x1 < 500 And x1 > 10
      nCount + 1

      If nCount % 2
        nStep1 + 1 : y2 = y1

        If nStep1 % 2 : x2 = x1 + 5 * nCount : Else : x2 = x1 - 5 * nCount : EndIf

      Else
        nStep2 + 1 : x2 = x1

        If nStep2 % 2 = 0 : y2 = y1 + 5 * nCount : Else : y2 = y1 - 5 * nCount : EndIf

      EndIf
      cvLine(*image, x1, y1, x2, y2, nB, nG, nR, 0, 2, #CV_AA, #Null)
      x1 = x2 : y1 = y2
      cvShowImage(#CV_WINDOW_NAME, *image)
      cvWaitKey(10)
    Wend
  Else
    nStep = 5

    For rtnCount = nStep To 250 Step 5
      If rtnCount % (2 * nStep)
        cvEllipse(*image, 255 + nStep, 250, rtnCount, rtnCount, 180, 180, 0, nB, nG, nR, 0, 2, #CV_AA, #Null)
      Else
        cvEllipse(*image, 255, 250, rtnCount, rtnCount, 0, 0, 180, nB, nG, nR, 0, 2, #CV_AA, #Null)
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *image)
      cvWaitKey(10)
    Next
  EndIf
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
*image.IplImage = cvCreateImage(510, 505, #IPL_DEPTH_8U, 3)
cvResizeWindow(#CV_WINDOW_NAME, *image\width, *image\height)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
DrawSpiral(*image, 0)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)

    If keyPressed = 32 : nSpiral ! #True : DrawSpiral(*image, nSpiral) : EndIf

  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseImage(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\