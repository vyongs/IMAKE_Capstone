IncludeFile "includes/cv_functions.pbi"

Global lpPrevWndFunc

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Detect scene changes using similarity measurements between frames." + #LF$ + #LF$ +
                  "SPACEBAR    " + #TAB$ + ": Start / Stop video."

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

Procedure.d GetPSNR(*I1.IplImage, *I2.IplImage)
  *s1.IplImage = cvCreateImage(*I1\width, *I1\height, #IPL_DEPTH_8U, 3)
  cvAbsDiff(*I1, *I2, *s1)
  *s132.IplImage = cvCreateImage(*I1\width, *I1\height, #IPL_DEPTH_32F, 3)
  cvConvertScale(*s1, *s132, 1, 0)
  cvMul(*s132, *s132, *s132, 1)
  sum.CvScalar : cvSum(@sum, *s132)
  sse.d = sum\val[0] + sum\val[1] + sum\val[2]

  If sse <= 1e-10 : ProcedureReturn 0 : EndIf

  mse.d = sse / *I1\imageSize
  psnr.d = 10 * Log10(255 * 255 / mse)
  cvReleaseImage(@*s132)
  cvReleaseImage(@*s1)
  ProcedureReturn psnr
EndProcedure

Procedure MergeFrames(*m1.IplImage, *m2.IplImage, *result.IplImage, changeNum)
  cvSetImageROI(*result, 0, 0, *m1\width, *m1\height)
  cvCopy(*m1, *result, #Null)
  cvResetImageROI(*result)
  cvSetImageROI(*result, *m1\width, 0, *m2\width, *m2\height)
  cvCopy(*m2, *result, #Null)
  cvResetImageROI(*result)
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_COMPLEX_SMALL, 1, 1, #Null, 1, #CV_AA)
  cvPutText(*result, "Normal Video", 30, 30, @font, 250, 200, 200, 0)
  cvPutText(*result, "Scene Change Detected: Frame " + Str(changeNum), *m1\width + 30, 30, @font, 250, 200, 200, 0)
EndProcedure

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateFileCapture("videos/megamind.avi")
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
  cvMoveWindow(#CV_WINDOW_NAME, 20, 20)
  ToolTip(window_handle, #CV_DESCRIPTION)
  #CHANGE_DETECT_RATIO = 15
  *result.IplImage = cvCreateImage(FrameWidth * 2, FrameHeight, #IPL_DEPTH_8U, 3)
  *prevFrame.IplImage : *changeFrame.IplImage : *image.IplImage
  *param.CvUserData = AllocateMemory(SizeOf(CvUserData))
  *param\Value = window_handle
  cvSetMouseCallback(*window_name, @CvMouseCallback(), *param)

  Repeat
    *image = cvQueryFrame(*capture)

    If *image
      If frameNum < 1
        *prevFrame = cvCloneImage(*image)
        *changeFrame = cvCloneImage(*image)
      Else
        If Not nWait
          psnrV.d = GetPSNR(*prevFrame, *image)

          If psnrV < #CHANGE_DETECT_RATIO
            cvReleaseImage(@*changeFrame)
            *changeFrame = cvCloneImage(*image)
            changeNum = frameNum
          EndIf
          MergeFrames(*image, *changeFrame, *result, changeNum)
        EndIf
        cvShowImage(#CV_WINDOW_NAME, *result)

        If nWait : keyPressed = cvWaitKey(0) : Else : keyPressed = cvWaitKey(20) : EndIf
        If keyPressed = 32 : nWait ! #True : EndIf

        If frameNum %2 = 0
          cvReleaseImage(@*prevFrame)
          *prevFrame = cvCloneImage(*image)
        EndIf
      EndIf
      frameNum + 1
    Else
      frameNum = 0
      cvReleaseImage(@*changeFrame)
      cvReleaseImage(@*prevFrame)
      cvSetCaptureProperty(*capture, #CV_CAP_PROP_POS_AVI_RATIO, 0)
    EndIf
  Until keyPressed = 27 Or exitCV
  FreeMemory(*param)
  cvReleaseImage(@*changeFrame)
  cvReleaseImage(@*prevFrame)
  cvReleaseImage(@*result)
  cvDestroyAllWindows()
  cvReleaseCapture(@*capture)
 Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to open video - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.60 (Windows - x86)
; CursorPosition = 1
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\