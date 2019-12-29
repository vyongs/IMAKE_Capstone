IncludeFile "includes/cv_functions.pbi"

#CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
#CV_DESCRIPTION = "Setting 1: Calculates the per-element bit-wise conjunction." + #LF$ + #LF$ +
                  "Setting 2: Calculates the per-element bit-wise exclusive Or operation."

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
  font.CvFont : cvInitFont(@font, #CV_FONT_HERSHEY_SIMPLEX, 1.0, 1.0, #Null, 2, #CV_AA)
  *AND.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  cvRectangleR(*AND, ptLeft, ptTop, FrameWidth, FrameHeight, 255, 255, 255, 0, #CV_FILLED, #CV_AA, #Null)
  cvLine(*AND, 120, 240, 295, 240, 255, 0, 0, 0, 8, #CV_AA, #Null)
  cvLine(*AND, 345, 240, 520, 240, 0, 0, 255, 0, 8, #CV_AA, #Null)
  cvLine(*AND, 320, 040, 320, 215, 0, 255, 255, 0, 8, #CV_AA, #Null)
  cvLine(*AND, 320, 265, 320, 440, 0, 255, 0, 0, 8, #CV_AA, #Null)
  cvCircle(*AND, 320, 240, 100, 0, 0, 0, 0, 8, #CV_AA, #Null)
  cvCircle(*AND, 320, 240, 200, 0, 0, 0, 0, 8, #CV_AA, #Null)
  cvPutText(*AND, "AND Effect", 10, 40, @font, 0, 0, 0, 0)
  cvPutText(*AND, "AND Effect", 7, 37, @font, 0, 0, 255, 0)
  *XOR.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  cvRectangleR(*XOR, ptLeft, ptTop, FrameWidth, FrameHeight, 0, 0, 0, 0, #CV_FILLED, #CV_AA, #Null)
  cvLine(*XOR, 120, 240, 295, 240, 0, 255, 255, 0, 8, #CV_AA, #Null)
  cvLine(*XOR, 345, 240, 520, 240, 255, 255, 0, 0, 8, #CV_AA, #Null)
  cvLine(*XOR, 320, 040, 320, 215, 255, 0, 0, 0, 8, #CV_AA, #Null)
  cvLine(*XOR, 320, 265, 320, 440, 255, 0, 255, 0, 8, #CV_AA, #Null)
  cvCircle(*XOR, 320, 240, 100, 255, 255, 255, 0, 8, #CV_AA, #Null)
  cvCircle(*XOR, 320, 240, 200, 255, 255, 255, 0, 8, #CV_AA, #Null)
  cvPutText(*XOR, "XOR Effect", 10, 40, @font, 255, 255, 255, 0)
  cvPutText(*XOR, "XOR Effect", 7, 37, @font, 255, 0, 255, 0)
  *logical.IplImage = cvCreateImage(FrameWidth, FrameHeight, #IPL_DEPTH_8U, 3)
  *image.IplImage : pbImage = CreateImage(#PB_Any, FrameWidth, FrameHeight)

  If OpenWindow(0, 0, 0, FrameWidth, FrameHeight + 60, #CV_WINDOW_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ImageGadget(0, 0, 0, FrameWidth, FrameHeight, ImageID(pbImage))
    ButtonGadget(1, 10, FrameHeight + 10, FrameWidth - 20, 40, "Toggle this button to change the webcam view between the Logical AND effect and the Logical XOR effect", #PB_Button_Toggle)

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

            If GetGadgetState(1) : cvXor(*image, *XOR, *logical, #Null) : Else : cvAnd(*image, *AND, *logical, #Null) : EndIf

            OpenCV2PBImage(*logical, pbImage, FrameWidth, FrameHeight)
            SetGadgetState(0, ImageID(pbImage))
          EndIf
      EndSelect
    ForEver
  EndIf
  FreeImage(pbImage)
  cvReleaseImage(@*logical)
  cvReleaseImage(@*XOR)
  cvReleaseImage(@*AND)
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