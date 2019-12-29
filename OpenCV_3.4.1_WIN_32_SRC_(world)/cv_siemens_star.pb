IncludeFile "includes/cv_functions.pbi"

Global *save.IplImage, exitCV, lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Siemens Star: A pattern used to test the resolution of optical instruments, printers and displays." + #LF$ + #LF$ +
                  "TRACKBAR    " + #TAB$ + ": Adjust setting."

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

ProcedureC CvTrackbarCallback(pos)
  keybd_event_(#VK_RETURN, 0, 0, 0)
EndProcedure

Procedure SiemensStar(*image.CvMat, nRadius, nPieces)
  cvSet(*image, 255, 255, 255, 0, #Null)

  Select nPieces
    Case 0 : nPieces = -2
    Case 1 : nPieces = -1
    Case 2 : nPieces = 0
    Case 3 : nPieces = 1
    Case 4 : nPieces = 4
    Case 5 : nPieces = 5
    Case 6 : nPieces = 7
    Case 7 : nPieces = 8
    Case 8 : nPieces = 10
    Case 9 : nPieces = 13
    Case 10 : nPieces = 15
    Case 11 : nPieces = 25
    Case 12 : nPieces = 32
    Case 13 : nPieces = 56
    Case 14 : nPieces = 86
  EndSelect
  nAngle = 360 / (2 * (nPieces + 5))

  Repeat
    cvEllipse(*image, nRadius + 10, nRadius + 10, nRadius, nRadius, 0, nCount, nCount + nAngle, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
    nCount + (2 * nAngle)
  Until nCount >= 360
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
nRadius = 256 : *image.CvMat = cvCreateMat(2 * nRadius + 20, 2 * nRadius + 20, CV_MAKETYPE(#CV_8U, 1))
cvResizeWindow(#CV_WINDOW_NAME, *image\cols, *image\rows + 48)
cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
ToolTip(window_handle, #CV_DESCRIPTION)
cvCreateTrackbar("Setting", #CV_WINDOW_NAME, @nPieces, 14, @CvTrackbarCallback())
SiemensStar(*image, nRadius, 0)
*param.CvUserData = AllocateMemory(SizeOf(CvUserData))
*param\Pointer1 = *image
*param\Value = window_handle
cvSetMouseCallback(*window_name, @cvMouseCallback(), *param)

Repeat
  If *image
    cvShowImage(#CV_WINDOW_NAME, *image)
    keyPressed = cvWaitKey(0)

    If keyPressed = 13 : SiemensStar(*image, nRadius, nPieces) : EndIf

  EndIf
Until keyPressed = 27 Or exitCV
FreeMemory(*param)
cvReleaseMat(@*image)
cvDestroyAllWindows()
; IDE Options = PureBasic 5.42 LTS (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\