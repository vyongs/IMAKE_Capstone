IncludeFile "includes/cv_functions.pbi"

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Setting 1: Applies a fixed-level threshold to each array element." + #LF$ + #LF$ +
                  "Setting 2: Finds edges in an image using the [Canny86] algorithm."

Repeat
  nCreate + 1
  *capture.CvCapture = cvCreateCameraCapture(nCreate)
Until nCreate = 99 Or *capture

If *capture
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
  *gray.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 1)
  *image.IplImage : pbImage = CreateImage(#PB_Any, FrameWidth, FrameHeight)

  If OpenWindow(0, 0, 0, FrameWidth, FrameHeight + 60, #CV_WINDOW_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ImageGadget(0, 0, 0, FrameWidth, FrameHeight, ImageID(pbImage))
    ButtonGadget(1, 10, FrameHeight + 10, FrameWidth - 20, 40, "Toggle the webcam view between the Threshold effect with and without the Canny86 algorithm", #PB_Button_Toggle)

    If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
      MenuItem(10, "Exit")
    EndIf
    AddKeyboardShortcut(0, #PB_Shortcut_Escape, 10)
    ToolTip(GadgetID(0), #CV_DESCRIPTION)

    Repeat
      Event = WindowEvent()

      Select Event
        Case #PB_Event_Gadget
          Select EventGadget()
            Case 0
              Select EventType()
                Case #PB_EventType_RightClick : DisplayPopupMenu(0, WindowID(0))
              EndSelect
          EndSelect
        Case #PB_Event_Menu
          Select EventMenu()
            Case 10 : Break
          EndSelect
        Case #PB_Event_CloseWindow : Break
        Default
          *image = cvQueryFrame(*capture)

          If *image
            cvFlip(*image, #Null, 1)
            cvCvtColor(*image, *gray, #CV_BGR2GRAY, 1)
            threshold.d = cvThreshold(*gray, *gray, 0, 255, #CV_THRESH_BINARY | #CV_THRESH_OTSU)

            If GetGadgetState(1) : cvCanny(*image, *gray, threshold * 0.5, threshold, 3, #False) : EndIf

            OpenCV2PBImage(*gray, pbImage, FrameWidth, FrameHeight)
            SetGadgetState(0, ImageID(pbImage))
          EndIf
      EndSelect
    ForEver
  EndIf
  FreeImage(pbImage)
  cvReleaseImage(@*gray)
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS beta 1 (Windows - x86)
; CursorPosition = 1
; EnableXP
; UseIcon = binaries\icons\opencv.ico
; DisableDebugger
; CurrentDirectory = binaries\