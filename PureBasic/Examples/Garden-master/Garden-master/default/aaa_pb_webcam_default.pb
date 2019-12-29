IncludeFile "includes/cv_functions.pbi"

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "."

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
  *image.IplImage : pbImage = CreateImage(#PB_Any, FrameWidth, FrameHeight)

  If OpenWindow(0, 0, 0, FrameWidth, FrameHeight + 60, #CV_WINDOW_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ImageGadget(0, 0, 0, FrameWidth, FrameHeight, ImageID(pbImage))
    ButtonGadget(1, 10, FrameHeight + 10, FrameWidth - 20, 40, "Default", #PB_Button_Toggle)

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
            OpenCV2PBImage(*image, pbImage, FrameWidth, FrameHeight)
            SetGadgetState(0, ImageID(pbImage))
          EndIf
      EndSelect
    ForEver
  EndIf
  FreeImage(pbImage)
  cvReleaseCapture(@*capture)
Else
  MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
EndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 1
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\
; EnableXP
; UseIcon = binaries\icons\opencv.ico