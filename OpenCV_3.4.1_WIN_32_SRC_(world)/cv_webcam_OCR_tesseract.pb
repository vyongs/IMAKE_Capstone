IncludeFile "includes/cv_functions.pbi"
IncludeFile "includes/pb_tesseract.pbi"

Global lpPrevWndFunc, *image.IplImage, select_object

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using Tesseract OCR (Optical Character Recognition) a section of a webcam frame is translated to text." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Highlight / Select area." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Execute OCR." + #LF$ +
                  "ENTER       " + #TAB$ + ": Reset the webcam."

Procedure WindowCallback(hWnd, uMsg, wParam, lParam)
  Shared exitCV

  Select uMsg
    Case #WM_COMMAND
      Select wParam
        Case 10
          exitCV = #True
      EndSelect
    Case #WM_DESTROY
      exitCV = #True
  EndSelect
  ProcedureReturn CallWindowProc_(lpPrevWndFunc, hWnd, uMsg, wParam, lParam)
EndProcedure

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Shared selection.CvRect
  Shared origin.CvPoint

  If select_object > 0
    selection\x = origin\x
    selection\y = origin\y
    CV_MIN(selection\x, x)
    CV_MIN(selection\y, y)
    selection\width = selection\x + CV_IABS(x - origin\x)
    selection\height = selection\y + CV_IABS(y - origin\y)
    CV_MAX(selection\x, 0)
    CV_MAX(selection\y, 0)
    CV_MIN(selection\width, *image\width)
    CV_MIN(selection\height, *image\height)
    selection\width - selection\x
    selection\height - selection\y
  EndIf

  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      origin\x = x
      origin\y = y
      selection\x = x
      selection\y = y
      selection\width = 0
      selection\height = 0
      select_object = 1
    Case #CV_EVENT_LBUTTONUP
      If selection\width > 5 And selection\height > 5 : select_object = -1 : Else : select_object = 0 : EndIf
  EndSelect
EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
Until nCreate = 99 Or *capture

If *capture
  cvNamedWindow(#CV_WINDOW_NAME, #CV_WINDOW_AUTOSIZE)
  window_handle = cvGetWindowHandle(#CV_WINDOW_NAME)
  *window_name = cvGetWindowName(window_handle)
  lpPrevWndFunc = SetWindowLongPtr_(window_handle, #GWL_WNDPROC, @WindowCallback())

  If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
    MenuItem(10, "Exit")
  EndIf
  hWnd = GetParent_(window_handle)
  iconCV = LoadImage_(GetModuleHandle_(#Null), @"icons/opencv.ico", #IMAGE_ICON, 35, 32, #LR_LOADFROMFILE)
  SendMessage_(hWnd, #WM_SETICON, 0, iconCV)
  wStyle = GetWindowLongPtr_(hWnd, #GWL_STYLE)
  SetWindowLongPtr_(hWnd, #GWL_STYLE, wStyle & ~(#WS_MAXIMIZEBOX | #WS_MINIMIZEBOX | #WS_SIZEBOX))
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)

  If FrameWidth > 640
    nRatio.d = 640 / FrameWidth
    FrameWidth * nRatio : FrameHeight * nRatio
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH, FrameWidth)
    cvSetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT, FrameHeight)
  EndIf
  FrameWidth = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_WIDTH)
  FrameHeight = cvGetCaptureProperty(*capture, #CV_CAP_PROP_FRAME_HEIGHT)
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  *overlay.IplImage
  opacity.d = 0.4
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      Select select_object
        Case -1
          If keyPressed = 13 : select_object = 0 : EndIf

          cvRectangle(*image, selection\x, selection\y, selection\x + selection\width, selection\y + selection\height, 0, 0, 255, 0, 2, #CV_AA, #Null)
        Case 1
          cvSetImageROI(*image, selection\x, selection\y, selection\width, selection\height)
          cvXorS(*image, 255, 255, 255, 0, *image, #Null)
          cvResetImageROI(*image)
      EndSelect
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(10)

      If keyPressed = 32 And select_object = -1
        hAPI = TesseractInit(#PSM_AUTO, #OEM_TESSERACT_ONLY, #PB_Compiler_FilePath + "binaries/tesseract/tessdata", "eng", #Null$)

        If hAPI
          *tesseract.IplImage = cvCreateImage(selection\width - 4, selection\height - 4, #IPL_DEPTH_8U, 3)
          cvSetImageROI(*image, selection\x + 2, selection\y + 2, selection\width - 4, selection\height - 4)
          cvCopy(*image, *tesseract, #Null)
          cvResetImageROI(*image)
          textOCR.s = OpenCVImage2TextOCR(hAPI, *tesseract)

          If textOCR : MessageRequester(#CV_WINDOW_NAME, textOCR, #MB_ICONINFORMATION) : textOCR = #Null$ : EndIf

          cvReleaseImage(@*tesseract)
        EndIf
      EndIf
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\