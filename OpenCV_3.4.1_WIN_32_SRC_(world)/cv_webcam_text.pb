IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Draws moving text of various styles."

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
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
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
  x1 = 40
  x2 = 40
  x3 = 40
  font1.CvFont : cvInitFont(@font1, #CV_FONT_HERSHEY_SCRIPT_COMPLEX, 1.5, 1.5, #Null, 1, #CV_AA)
  font2.CvFont : cvInitFont(@font2, #CV_FONT_HERSHEY_SIMPLEX, 1.5, 1.5, #Null, 1, #CV_AA)
  font3.CvFont : cvInitFont(@font3, #CV_FONT_HERSHEY_TRIPLEX | #CV_FONT_ITALIC, 1.5, 1.5, #Null, 1, #CV_AA)
  *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      If x1 = 40 : adjust1.b = #True : ElseIf x1 > *image\width - 240 : adjust1 = #False : EndIf
      If adjust1 : x1 + 20 : Else : x1 - 20 : EndIf
      If x2 = 40 : adjust2.b = #True : ElseIf x2 > *image\width - 240 : adjust2 = #False : EndIf
      If adjust2 : x2 + 10 : Else : x2 - 10 : EndIf
      If x3 = 40 : adjust3.b = #True : ElseIf x3 > *image\width - 240 : adjust3 = #False : EndIf
      If adjust3 : x3 + 30 : Else : x3 - 30 : EndIf

      cvPutText(*image, "JHPJHP", x1, 50, @font1, 0, 0, 255, 0)
      cvPutText(*image, "JHPJHP", x2, 100, @font2, 0, 255, 0, 0)
      cvPutText(*image, "JHPJHP", x3, 150, @font3, 255, 0, 0, 0)
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(100)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\