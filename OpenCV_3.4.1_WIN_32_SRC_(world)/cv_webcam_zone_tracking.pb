IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Calculates the weighted sum of the input image and the accumulator creating a silhouette effect, " +
                  "detecting objects found within one or more zones." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Toggle views." + #LF$ +
                  "MOUSE       " + #TAB$ + ": Toggle zones." + #LF$ + #LF$ +
                  "[ < ] KEY   " + #TAB$ + ": Remove rows (hold SHIFT for columns)." + #LF$ +
                  "[ > ] KEY   " + #TAB$ + ": Add rows (hold SHIFT for columns)." + #LF$ +
                  "[ A ] KEY   " + #TAB$ + ": Toggle alarm." + #LF$ +
                  "[ G ] KEY   " + #TAB$ + ": Toggle grid." + #LF$ +
                  "[ T ] KEY   " + #TAB$ + ": Toggle tracking." + #LF$ +
                  "[ V ] KEY   " + #TAB$ + ": Change PIP view." + #LF$ +
                  "[ Z ] KEY   " + #TAB$ + ": Toggle all zones."

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

Structure ZONE_RECT
  xBegin.l
  xEnd.l
  yBegin.l
  yEnd.l
  status.l
EndStructure

Global nRows, nColumns, Dim guardZone.ZONE_RECT(0), Dim zoneSelected(0)

Procedure CvMouseCallback(event, x.l, y.l, flags, *param.CvUserData)
  Select event
    Case #CV_EVENT_RBUTTONDOWN
      DisplayPopupMenu(0, *param\Value)
    Case #CV_EVENT_LBUTTONDOWN
      Dim zoneSelected(ArraySize(guardZone()))

      For zoneN = 1 To nRows * nColumns
        If Not zoneSelected(zoneN)
          If guardZone(zoneN)\xBegin < x And guardZone(zoneN)\xEnd > x And
             guardZone(zoneN)\yBegin < y And guardZone(zoneN)\yEnd > y

            If guardZone(zoneN)\status : guardZone(zoneN)\status = 0 : Else : guardZone(zoneN)\status = 1 : EndIf

            zoneSelected(zoneN) = 1
          EndIf
        EndIf
      Next
    Case #CV_EVENT_LBUTTONUP
      Dim zoneSelected(0)
    Case #CV_EVENT_MOUSEMOVE
      If ArraySize(zoneSelected())
        For zoneN = 1 To nRows * nColumns
          If Not zoneSelected(zoneN)
            If guardZone(zoneN)\xBegin < x And guardZone(zoneN)\xEnd > x And
               guardZone(zoneN)\yBegin < y And guardZone(zoneN)\yEnd > y

              If guardZone(zoneN)\status : guardZone(zoneN)\status = 0 : Else : guardZone(zoneN)\status = 1 : EndIf

              zoneSelected(zoneN) = 1
            EndIf
          EndIf
        Next
      EndIf
  EndSelect
EndProcedure

Structure SOUND_INFO
  PlayFile.l
  FileName.s
  QuitSound.l
EndStructure

Procedure PlayWAVFile(*sound.SOUND_INFO)
  Repeat
    If *sound\PlayFile : sndPlaySound_(*sound\FileName + Chr(0), #SND_NODEFAULT + #SND_NOSTOP + #SND_FILENAME) : Else : Delay(100) : EndIf
  Until *sound\QuitSound
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
  INIT_TIME = 50 : BG_RATIO.d = 0.02 : OBJ_RATIO.d = 0.005
  zeta.d = 10 : opacity.d = 0.1
  PIP = 2 : grid = 1 : zone = 1 : frames = 1
  nRows = 3 : nColumns = 3
  *imgAverage.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgSgm.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgTmp.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *img_lower.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *img_upper.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_32F, 3)
  *imgSilhouette.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *imgResult.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  iRatio.d = 150 / FrameWidth
  iWidth = FrameWidth * iRatio
  iHeight = FrameHeight * iRatio
  *PIP.IplImage = cvCreateImage(iWidth, iHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage
  cvSetZero(*imgAverage)
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)
  *sound.SOUND_INFO = AllocateMemory(SizeOf(SOUND_INFO))
  *sound\FileName = "sounds/alarm.wav"
  nThread = CreateThread(@PlayWAVFile(), *sound)
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX | #CV_FONT_ITALIC, 1, 1, #Null, 1, #CV_AA)
  cvPutText(*imgAverage, "Initializing Zones...", 20, 40, @font, 0, 255, 255, 0)
  cvShowImage(#CV_WINDOW_NAME, *imgAverage)
  cvWaitKey(100)

  For rtnCount = 0 To INIT_TIME
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvAcc(*image, *imgAverage, #Null)
    EndIf
  Next
  cvConvertScale(*imgAverage, *imgAverage, 1.0 / INIT_TIME, 0)
  cvSetZero(*imgSgm)

  For rtnCount = 0 To INIT_TIME
    *image = cvQueryFrame(*capture)

    If *image
      cvFlip(*image, #Null, 1)
      cvConvert(*image, *imgTmp)
      cvSub(*imgTmp, *imgAverage, *imgTmp, #Null)
      cvPow(*imgTmp, *imgTmp, 2)
      cvConvertScale(*imgTmp, *imgTmp, 2, 0)
      cvPow(*imgTmp, *imgTmp, 0.5)
      cvAcc(*imgTmp, *imgSgm, #Null)
    EndIf
  Next
  cvConvertScale(*imgSgm, *imgSgm, 1.0 / INIT_TIME, 0)
  *kernel.IplConvKernel = cvCreateStructuringElementEx(3, 3, 1, 1, #CV_SHAPE_RECT, #Null)
  *storage.CvMemStorage = cvCreateMemStorage(0)
  *contours.CvContour

  Repeat
    *image = cvQueryFrame(*capture)
    *sound\PlayFile = #False

    If *image
      cvFlip(*image, #Null, 1)
      cvConvert(*image, *imgTmp)
      cvSub(*imgAverage, *imgSgm, *img_lower, #Null)
      cvSubS(*img_lower, zeta, zeta, zeta, zeta, *img_lower, #Null)
      cvAdd(*imgAverage, *imgSgm, *img_upper, #Null)
      cvAddS(*img_upper, zeta, zeta, zeta, zeta, *img_upper, #Null)
      cvInRange(*imgTmp, *img_lower, *img_upper, *imgSilhouette)
      cvSub(*imgTmp, *imgAverage, *imgTmp, #Null)
      cvPow(*imgTmp, *imgTmp, 2)
      cvConvertScale(*imgTmp, *imgTmp, 2, 0)
      cvPow(*imgTmp, *imgTmp, 0.5)
      cvRunningAvg(*image, *imgAverage, BG_RATIO, *imgSilhouette)
      cvRunningAvg(*imgTmp, *imgSgm, BG_RATIO, *imgSilhouette)
      cvNot(*imgSilhouette, *imgSilhouette)
      cvRunningAvg(*imgTmp, *imgSgm, OBJ_RATIO, *imgSilhouette)
      cvErode(*imgSilhouette, *imgSilhouette, *kernel, 1)
      cvDilate(*imgSilhouette, *imgSilhouette, *kernel, 2)
      cvErode(*imgSilhouette, *imgSilhouette, *kernel, 1)
      cvMerge(*imgSilhouette, *imgSilhouette, *imgSilhouette, #Null, *imgResult)

      If frames
        Dim guardZone.ZONE_RECT(nRows * nColumns)
        zoneW = FrameWidth / nColumns
        zoneH = FrameHeight / nRows

        For y = 0 To nRows - 1
          For x = 0 To nColumns - 1
            xy + 1
            guardZone(xy)\xBegin = zoneW * x + 2
            guardZone(xy)\xEnd = guardZone(xy)\xBegin + zoneW - 2
            guardZone(xy)\yBegin = zoneH * y + 2
            guardZone(xy)\yEnd = guardZone(xy)\yBegin + zoneH - 2
            guardZone(xy)\status = 1
          Next
        Next
        frames = 0 : xy = 0
      EndIf

      For zoneN = 1 To nRows * nColumns
        If zoneN = 1
          If alarm
            cvRectangle(*image, 1, 1, *image\width - 3, *image\height - 3, 255, 0, 255, 0, 2, #CV_AA, #Null)
          Else
            cvRectangle(*image, 1, 1, *image\width - 3, *image\height - 3, 255, 0, 0, 0, 2, #CV_AA, #Null)
          EndIf
        EndIf

        If grid
          If alarm
            cvRectangle(*image, guardZone(zoneN)\xBegin, guardZone(zoneN)\yBegin, guardZone(zoneN)\xEnd, guardZone(zoneN)\yEnd, 255, 0, 255, 0, 1, #CV_AA, #Null)
          Else
            cvRectangle(*image, guardZone(zoneN)\xBegin, guardZone(zoneN)\yBegin, guardZone(zoneN)\xEnd, guardZone(zoneN)\yEnd, 255, 0, 0, 0, 1, #CV_AA, #Null)
          EndIf
        EndIf

        If guardZone(zoneN)\status = 0
          *select.IplImage = cvCloneImage(*image)
          cvRectangle(*image, guardZone(zoneN)\xBegin, guardZone(zoneN)\yBegin, guardZone(zoneN)\xEnd, guardZone(zoneN)\yEnd, 0, 0, 255, 0, #CV_FILLED, #CV_AA, #Null)
          cvAddWeighted(*image, opacity, *select, 1 - opacity, 0, *image)
          cvReleaseImage(@*select)
        EndIf
      Next
      cvClearMemStorage(*storage)
      nContours = cvFindContours(*imgSilhouette, *storage, @*contours, SizeOf(CvContour), #CV_RETR_EXTERNAL, #CV_CHAIN_APPROX_NONE, 0, 0)

      If nContours
        For rtnCount = 0 To nContours - 1
          area.d = cvContourArea(*contours, 0, #CV_WHOLE_SEQ_END_INDEX, 0)

          If area >= 500
            For zoneN = 1 To nRows * nColumns
              If guardZone(zoneN)\status
                If guardZone(zoneN)\xBegin <= *contours\rect\x + *contours\rect\width And guardZone(zoneN)\xEnd >= *contours\rect\x And
                   guardZone(zoneN)\yBegin <= *contours\rect\y + *contours\rect\height And guardZone(zoneN)\yEnd >= *contours\rect\y
                  cvDrawContours(*imgResult, *contours, 255, 155, 0, 0, 155, 255, 0, 0, 0, #CV_FILLED, #CV_AA, 0, 0)
                  *select.IplImage = cvCloneImage(*image)
                  cvRectangle(*image, guardZone(zoneN)\xBegin, guardZone(zoneN)\yBegin, guardZone(zoneN)\xEnd, guardZone(zoneN)\yEnd, 0, 255, 0, 0, #CV_FILLED, #CV_AA, #Null)
                  cvAddWeighted(*image, opacity, *select, 1 - opacity, 0, *image)
                  cvReleaseImage(@*select)

                  If alarm : *sound\PlayFile = #True : EndIf

                  If tracking
                    cvRectangleR(*image, *contours\rect\x, *contours\rect\y, *contours\rect\width, *contours\rect\height, 0, 255, 255, 0, 1, #CV_AA, #Null)
                  EndIf
                EndIf
              EndIf
            Next
          EndIf
          *contours = *contours\h_next
        Next
      EndIf

      Select PIP
        Case 0
          If foreground
            cvResize(*image, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*imgResult, 20, 20, iWidth, iHeight)
            cvAndS(*imgResult, 0, 0, 0, 0, *imgResult, #Null)
            cvAdd(*imgResult, *PIP, *imgResult, #Null)
            cvResetImageROI(*imgResult)
            cvRectangleR(*imgResult, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *imgResult)
          Else
            cvResize(*imgResult, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*image, 20, 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, 19, 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *image)
          EndIf
        Case 1
          If foreground
            cvResize(*image, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*imgResult, *image\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*imgResult, 0, 0, 0, 0, *imgResult, #Null)
            cvAdd(*imgResult, *PIP, *imgResult, #Null)
            cvResetImageROI(*imgResult)
            cvRectangleR(*imgResult, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *imgResult)
          Else
            cvResize(*imgResult, *PIP, #CV_INTER_AREA)
            cvSetImageROI(*image, *image\width - (150 + 20), 20, iWidth, iHeight)
            cvAndS(*image, 0, 0, 0, 0, *image, #Null)
            cvAdd(*image, *PIP, *image, #Null)
            cvResetImageROI(*image)
            cvRectangleR(*image, *image\width - (150 + 21), 19, iWidth + 2, iHeight + 2, 0, 255, 255, 0, 1, #CV_AA, #Null)
            cvShowImage(#CV_WINDOW_NAME, *image)
          EndIf
        Case 2
          If foreground : cvShowImage(#CV_WINDOW_NAME, *imgResult) : Else : cvShowImage(#CV_WINDOW_NAME, *image) : EndIf
      EndSelect
      keyPressed = cvWaitKey(1)

      Select keyPressed
        Case 32
          foreground ! #True
        Case 44, 60
          If keyPressed = 44
            If nRows > 1 : nRows - 1 : frames = 1 : EndIf
          Else
            If nColumns > 1 : nColumns - 1 : frames = 1 : EndIf
          EndIf
        Case 46, 62
          If keyPressed = 46
            If nRows < 10 : nRows + 1 : frames = 1 : EndIf
          Else
            If nColumns < 10 : nColumns + 1 : frames = 1 : EndIf
          EndIf
        Case 65, 97
          alarm ! #True
        Case 71, 103
          grid ! #True
        Case 84, 116
          tracking ! #True
        Case 86, 118
          PIP = (PIP + 1) % 3
        Case 90, 122
          For zoneN = 1 To nRows * nColumns
            If (zone And guardZone(zoneN)\status) Or (zone = 0 And guardZone(zoneN)\status = 0) : status + 1 : EndIf
          Next

          If status : zone ! #True : status = 0 : EndIf

          For zoneN = 1 To nRows * nColumns
            guardZone(zoneN)\status = zone
          Next
      EndSelect
    EndIf
  Until keyPressed = 27 Or exitCV
  *sound\QuitSound = #True : Delay(100)
  ClearStructure(*sound, SOUND_INFO)
  FreeMemory(*sound)
  FreeMemory(*param)
  cvReleaseMemStorage(@*storage)
  cvReleaseStructuringElement(@*kernel)
  cvReleaseImage(@*PIP)
  cvReleaseImage(@*imgResult)
  cvReleaseImage(@*imgSilhouette)
  cvReleaseImage(@*img_upper)
  cvReleaseImage(@*img_lower)
  cvReleaseImage(@*imgTmp)
  cvReleaseImage(@*imgSgm)
  cvReleaseImage(@*imgAverage)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.62 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableThread; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\