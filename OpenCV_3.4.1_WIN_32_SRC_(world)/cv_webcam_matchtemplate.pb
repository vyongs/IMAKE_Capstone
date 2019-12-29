IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, *image.IplImage, select_object

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Object recognition using the template matching algorithm." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Highlight / Select area." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Select object/Reset area." + #LF$ +
                  "ENTER       " + #TAB$ + ": Remove selected area." + #LF$ + #LF$ +
                  "[ M ] KEY   " + #TAB$ + ": Set template method." + #LF$ +
                  "[ S ] KEY   " + #TAB$ + ": Show / Hide match-image."

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
  *match.IplImage : *result.IplImage : *overlay.IplImage
  min_loc.CvPoint : max_loc.CvPoint : opacity.d = 0.4 : Method.s = "CV_TM_SQDIFF" : nShow = #True
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 0.5, 0.5, #Null, 1, #CV_AA)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)

      Select select_object
        Case -1
          Select keyPressed
            Case 13
              select_object = 0 : nMethod = 0 : Method = "CV_TM_SQDIFF" : nShow = #True
            Case 32
              nOutline ! #True

              If nOutline
                cvReleaseImage(@*result)
                cvReleaseImage(@*match)
                *match = cvCreateImage(selection\width, selection\height, #IPL_DEPTH_8U, 3)
                cvSetImageROI(*image, selection\x, selection\y, selection\width, selection\height)
                cvCopy(*image, *match, #Null)
                cvResetImageROI(*image)
                *result = cvCreateImage(*image\width - *match\width + 1, *image\height - *match\height + 1, #IPL_DEPTH_32F, 1)
              EndIf
            Case 77, 109
              If nOutline
                nMethod = (nMethod + 1) % 6

                Select nMethod
                  Case 0
                    Method = "CV_TM_SQDIFF"
                  Case 1
                    Method = "CV_TM_SQDIFF_NORMED"
                  Case 2
                    Method = "CV_TM_CCORR"
                  Case 3
                    Method = "CV_TM_CCORR_NORMED"
                  Case 4
                    Method = "CV_TM_CCOEFF"
                  Case 5
                    Method = "CV_TM_CCOEFF_NORMED"
                EndSelect
              EndIf
            Case 83, 115
              If nOutline : nShow ! #True : EndIf
          EndSelect

          If nOutline
            cvMatchTemplate(*image, *match, *result, nMethod)
            cvNormalize(*result, *result, 0, 1, #NORM_MINMAX, #Null)
            cvMinMaxLoc(*result, @min_val.d, @max_val.d, @min_loc, @max_loc, #Null)

            If nMethod < 2
              cvRectangle(*image, min_loc\x, min_loc\y, min_loc\x + *match\width, min_loc\y + *match\height, 0, 0, 255, 0, 2, #CV_AA, #Null)
            Else
              cvRectangle(*image, max_loc\x, max_loc\y, max_loc\x + *match\width, max_loc\y + *match\height, 0, 0, 255, 0, 2, #CV_AA, #Null)
            EndIf

            If nShow And *match\width + 20 < *image\width And *match\height + 20 < *image\height
              cvPutText(*image, Method, 12, 16, @font, 0, 0, 0, 0)
              cvPutText(*image, Method, 10, 14, @font, 255, 255, 255, 0)
              cvSetImageROI(*image, 10, 20, *match\width, *match\height)
              cvAndS(*image, 0, 0, 0, 0, *image, #Null)
              cvAdd(*image, *match, *image, #Null)
              cvResetImageROI(*image)
              cvRectangleR(*image, 10, 20, *match\width, *match\height, 0, 255, 255, 0, 1, #CV_AA, #Null)
            EndIf
          Else
            cvReleaseImage(@*overlay)
            *overlay = cvCloneImage(*image)
            cvRectangle(*image, selection\x, selection\y, selection\x + selection\width, selection\y + selection\height, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
            cvAddWeighted(*image, opacity, *overlay, 1 - opacity, 0, *image)
          EndIf
        Case 1
          cvSetImageROI(*image, selection\x, selection\y, selection\width, selection\height)
          cvXorS(*image, 255, 255, 255, 0, *image, #Null)
          cvResetImageROI(*image)
        Default
          nOutline = #False
      EndSelect
      cvShowImage(#CV_WINDOW_NAME, *image)
      keyPressed = cvWaitKey(10)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*overlay)
  cvReleaseImage(@*result)
  cvReleaseImage(@*match)
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