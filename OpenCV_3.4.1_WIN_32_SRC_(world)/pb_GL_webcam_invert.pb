CompilerIf #PB_Compiler_Version >= 530
  IncludeFile "includes/cv_functions.pbi"

  #CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
  #CV_DESCRIPTION = "Using OpenGL and textures, the webcam interface is displayed onto the front and inverted onto the back of a revolving rectangle."

  Procedure ConvertIplToTexture(*image.IplImage)
    glGenTextures_(1, @texturePTR)
    glBindTexture_(#GL_TEXTURE_2D, texturePTR)
    glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_WRAP_S, #GL_REPEAT)
    glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_WRAP_T, #GL_REPEAT)
    glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_MIN_FILTER, #GL_NEAREST)
    glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_MAG_FILTER, #GL_NEAREST)
    gluBuild2DMipmaps_(#GL_TEXTURE_2D, 3, *image\width, *image\height, #GL_BGR_EXT, #GL_UNSIGNED_BYTE, *image\imageData)
    ProcedureReturn texturePTR
  EndProcedure

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
    *image.IplImage

    If OpenWindow(0, 0, 0, FrameWidth, FrameHeight, #CV_WINDOW_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
      OpenGLGadget(0, 0, 0, FrameWidth, FrameHeight)

      If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
        MenuItem(10, "Exit")
      EndIf
      AddKeyboardShortcut(0, #PB_Shortcut_Escape, 10)
      ToolTip(GadgetID(0), #CV_DESCRIPTION)
      gluPerspective_(25, FrameWidth / FrameHeight, 1, 60)
      glMatrixMode_(#GL_MODELVIEW)
      glClearColor_(0, 0, 0, 1)
      glClearDepth_(1)
      glEnable_(#GL_DEPTH_TEST)
      glDepthFunc_(#GL_LEQUAL)
      glHint_(#GL_PERSPECTIVE_CORRECTION_HINT, #GL_NICEST)
      glShadeModel_(#GL_SMOOTH)
      glDisable_(#GL_DITHER)
      glEnable_(#GL_CULL_FACE)
      glCullFace_(#GL_BACK)
      glEnable_(#GL_TEXTURE_2D)
      Dim matrix.f(16)

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
              glClear_(#GL_COLOR_BUFFER_BIT | #GL_DEPTH_BUFFER_BIT)
              glLoadIdentity_()
              glTranslatef_(0, 0, -6.5)
              glRotatef_(yRotation.f, 0, 1, 0)

              If matrix(0) > 0
                texturePTR = ConvertIplToTexture(*image)
                glBindTexture_(#GL_TEXTURE_2D, texturePTR)
                glBegin_(#GL_QUADS)
                  glTexCoord2f_(1, 0) : glVertex3f_(1.5, 1, 1)
                  glTexCoord2f_(0, 0) : glVertex3f_(-1.5, 1, 1)
                  glTexCoord2f_(0, 1) : glVertex3f_(-1.5, -1, 1)
                  glTexCoord2f_(1, 1) : glVertex3f_(1.5, -1, 1)
                glEnd_()
              Else
                cvXorS(*image, 255, 255, 255, 0, *image, #Null)
                texturePTR = ConvertIplToTexture(*image)
                glBindTexture_(#GL_TEXTURE_2D, texturePTR)
                glBegin_(#GL_QUADS)
                  glTexCoord2f_(1, 1) : glVertex3f_(1.5, -1, 1)
                  glTexCoord2f_(0, 1) : glVertex3f_(-1.5, -1, 1)
                  glTexCoord2f_(0, 0) : glVertex3f_(-1.5, 1, 1)
                  glTexCoord2f_(1, 0) : glVertex3f_(1.5, 1, 1)
                glEnd_()
              EndIf
              SetGadgetAttribute(0, #PB_OpenGL_FlipBuffers, #True)
              glGetFloatv_(#GL_MODELVIEW_MATRIX, @matrix(0))
              glDeleteTextures_(1, @texturePTR)
              yRotation + 3.5
            EndIf
        EndSelect
      ForEver
    EndIf
    cvReleaseCapture(@*capture)
  Else
    MessageRequester(#CV_WINDOW_NAME, "Unable to connect webcam - operation cancelled.", #MB_ICONERROR)
  EndIf
CompilerElse
  MessageRequester(#CV_WINDOW_NAME, "Process Cancelled..." + #LF$ + #LF$ + "This example can only run in PureBasic 5.30 or greater.", #MB_ICONERROR)
CompilerEndIf
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 2
; Folding = -
; EnableXP
; DisableDebugger
; CurrentDirectory = binaries\
; EnableXP
; UseIcon = binaries\icons\opencv.ico