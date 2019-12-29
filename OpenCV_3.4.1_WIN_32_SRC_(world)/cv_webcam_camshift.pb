IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc, *image.IplImage

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Using the Camshift algorithm, color information is used to track an object along an image sequence." + #LF$ + #LF$ +
                  "MOUSE       " + #TAB$ + ": Select a rectangle centered tightly on your face." + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Show / Hide Histogram." + #LF$ +
                  "ENTER       " + #TAB$ + ": Clear the selected object." + #LF$ + #LF$ +
                  "[ P ] KEY   " + #TAB$ + ": Toggle Projection Mode."

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
  Shared select_object
  Shared track_object

  If select_object
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
      select_object = 0

      If selection\width > 0 And selection\height > 0 : track_object = -1 : EndIf

  EndSelect
EndProcedure

Procedure HSV2RGB(hue.f)
  Dim color(3)
  Dim sector_data(6, 3)
  sector_data(0, 0) = 0
  sector_data(0, 1) = 2
  sector_data(0, 2) = 1
  sector_data(1, 0) = 1
  sector_data(1, 1) = 2
  sector_data(1, 2) = 0
  sector_data(2, 0) = 1
  sector_data(2, 1) = 0
  sector_data(2, 2) = 2
  sector_data(3, 0) = 2
  sector_data(3, 1) = 0
  sector_data(3, 2) = 1
  sector_data(4, 0) = 2
  sector_data(4, 1) = 1
  sector_data(4, 2) = 0
  sector_data(5, 0) = 0
  sector_data(5, 1) = 1
  sector_data(5, 2) = 2
  hue * 0.0333333333333333333
  sector = cvFloor(hue)
  p = Round(255 * (hue - sector), #PB_Round_Nearest)

  If sector & 1 : p ! 255 : Else : p ! 0 : EndIf

  color(sector_data(sector, 0)) = 255
  color(sector_data(sector, 1)) = 0
  color(sector_data(sector, 2)) = p
  ProcedureReturn cvScalar(color(2), color(1), color(0), 0)
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
  *frame.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *hsv.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *hue.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *mask.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *projection.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  iRatio.d = 150 / FrameWidth
  iWidth = FrameWidth * iRatio
  iHeight = FrameHeight * iRatio
  *hist.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
  cvSetZero(*hist)
  smin = 30 : vmin = 10 : vmax = 255
  bins = 16
  Dim range.f(2) : range(0) = 0 : range(1) = 180
  *ranges.FLOAT : PokeL(@*ranges, @range())
  *histogram.CvHistogram = cvCreateHist(1, @bins, #CV_HIST_ARRAY, @*ranges, #True)
  *color.CvScalar
  window.CvRect
  comp.CvConnectedComp
  box.CvBox2D
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SCRIPT_COMPLEX, 1, 1, #Null, 1, #CV_AA)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvCopy(*image, *frame, #Null)
      cvCvtColor(*frame, *hsv, #CV_BGR2HSV, 1)

      If track_object
        cvInRangeS(*hsv, 0, smin, vmin, 0, 180, 256, vmax, 0, *mask)
        cvSplit(*hsv, *hue, #Null, #Null, #Null)

        If track_object < 0
          cvSetImageROI(*hue, selection\x, selection\y, selection\width, selection\height)
          cvSetImageROI(*mask, selection\x, selection\y, selection\width, selection\height)
          cvCalcHist(@*hue, *histogram, #False, *mask)
          cvGetMinMaxHistValue(*histogram, #Null, @max_value.f, #Null, #Null)

          If max_value : scale.d = 255 / max_value : Else : scale.d = 0 : EndIf

          cvConvertScale(*histogram\bins, *histogram\bins, scale, 0)
          cvResetImageROI(*mask)
          cvResetImageROI(*hue)
          cvSetZero(*hist)
          bin_width = *hist\width / bins

          For i = 0 To bins - 1
            real = Round(cvGetReal1D(*histogram\bins, i) * *hist\height / 255, #PB_Round_Nearest)
            *color = HSV2RGB(i * 180 / bins)
            cvRectangle(*hist, i * bin_width, *hist\height, (i + 1) * bin_width, *hist\height - real, *color\val[0], *color\val[1], *color\val[2], *color\val[3], #CV_FILLED, #CV_AA, #Null)
          Next
          window = selection
          track_object = 1
        EndIf
        cvCalcBackProject(@*hue, *projection, *histogram)
        cvAnd(*projection, *mask, *projection, #Null)
        cvCamShift(*projection, window\x, window\y, window\width, window\height, #CV_TERMCRIT_ITER | #CV_TERMCRIT_EPS, 10, 1, @comp, @box)

        If comp\rect\width And comp\rect\height : window = comp\rect : EndIf
        If projection_mode : cvCvtColor(*projection, *frame, #CV_GRAY2BGR, 1) : EndIf

        cvEllipseBox(*frame, box\center\x, box\center\y, box\size\width, box\size\height, box\angle, 0, 0, 255, 0, 3, #CV_AA, #Null)
      EndIf

      If select_object And selection\width > 0 And selection\height > 0
        cvSetImageROI(*frame, selection\x, selection\y, selection\width, selection\height)
        cvXorS(*frame, 255, 255, 255, 0, *frame, #Null)
        cvResetImageROI(*frame)
      EndIf

      If show_histogram
        cvSetImageROI(*frame, 20, 20, iWidth, iHeight)
        cvAdd(*frame, *hist, *frame, #Null)
        cvResetImageROI(*frame)
        cvRectangleR(*frame, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
      EndIf

      If Not track_object
        If projection_mode : cvPutText(*frame, "Projection Mode", 400, 40, @font, 0, 255, 255, 0) : EndIf
      EndIf
      cvShowImage(#CV_WINDOW_NAME, *frame)
      keyPressed = cvWaitKey(10)

      Select keyPressed
        Case 13
          track_object = 0
          cvSetZero(*hist)
        Case 32
          show_histogram ! #True
        Case 80, 112
          projection_mode ! #True
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseHist(@*histogram)
  cvReleaseImage(@*hist)
  cvReleaseImage(@*mask)
  cvReleaseImage(@*hue)
  cvReleaseImage(@*hsv)
  cvReleaseImage(@*frame)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.42 LTS (Windows - x64)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\