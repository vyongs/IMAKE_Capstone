CompilerIf #PB_Compiler_Version >= 530
  IncludeFile "includes/cv_functions.pbi"

  #CV_WINDOW_NAME = "PureBasic Interface to OpenCV"
  #CV_DESCRIPTION = "Using OpenGL and textures, multiple images are displayed onto the surfaces of rotating shapes." + #LF$ + #LF$ +
                    "SPACEBAR    " + #TAB$ + ": Toggle shapes."

  FrameWidth = 640
  FrameHeight = 480
  Dim *image.IplImage(6)
  *image(1) = cvLoadImage("images/enhance1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *image(2) = cvLoadImage("images/enhance2.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *image(3) = cvLoadImage("images/baboon.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *image(4) = cvLoadImage("images/fruits.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *image(5) = cvLoadImage("images/sketch1.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)
  *image(6) = cvLoadImage("images/starrynight.jpg", #CV_LOAD_IMAGE_ANYDEPTH | #CV_LOAD_IMAGE_ANYCOLOR)

  If OpenWindow(0, 0, 0, FrameWidth, FrameHeight, #CV_WINDOW_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    OpenGLGadget(0, 0, 0, FrameWidth, FrameHeight)

    If CreatePopupImageMenu(0, #PB_Menu_ModernLook)
      MenuItem(10, "Exit")
    EndIf
    AddKeyboardShortcut(0, #PB_Shortcut_Space, 0)
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
    Dim texturePTR(6)

    For rtnCount = 1 To 6
      glGenTextures_(1, @texturePTR(rtnCount))
      glBindTexture_(#GL_TEXTURE_2D, texturePTR(rtnCount))
      glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_WRAP_S, #GL_REPEAT)
      glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_WRAP_T, #GL_REPEAT)
      glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_MIN_FILTER, #GL_NEAREST)
      glTexParameteri_(#GL_TEXTURE_2D, #GL_TEXTURE_MAG_FILTER, #GL_NEAREST)
      gluBuild2DMipmaps_(#GL_TEXTURE_2D, #GL_RGB, *image(rtnCount)\width, *image(rtnCount)\height, #GL_BGR_EXT, #GL_UNSIGNED_BYTE, *image(rtnCount)\imageData)
    Next

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
            Case 0 : nShape ! #True
            Case 10 : Break
          EndSelect
        Case #PB_Event_CloseWindow : Break
        Default
          xRotation.f + 1.5
          yRotation.f - 2.5
          zRotation.f + 3.5
          glClear_(#GL_COLOR_BUFFER_BIT | #GL_DEPTH_BUFFER_BIT)
          glLoadIdentity_()
          glTranslatef_(0, 0, -7.5)

          If nShape
            glRotatef_(yRotation, 0, 1, 0)
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(2))
            glBegin_(#GL_TRIANGLES)
              glTexCoord2f_(0, 0) : glVertex3f_(0, 1, 0)
              glTexCoord2f_(1, 0) : glVertex3f_(-1, -1, 1)
              glTexCoord2f_(0, 1) : glVertex3f_(1, -1, 1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(4))
            glBegin_(#GL_TRIANGLES)
              glTexCoord2f_(0, 0) : glVertex3f_(0, 1, 0)
              glTexCoord2f_(1, 0) : glVertex3f_(1, -1, 1)
              glTexCoord2f_(0, 1) : glVertex3f_(1, -1, -1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(5))
            glBegin_(#GL_TRIANGLES)
              glTexCoord2f_(0, 0) : glVertex3f_(0, 1, 0)
              glTexCoord2f_(1, 0) : glVertex3f_(1, -1, -1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1, -1, -1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(6))
            glBegin_(#GL_TRIANGLES)
              glTexCoord2f_(0, 0) : glVertex3f_(0, 1, 0)
              glTexCoord2f_(1, 0) : glVertex3f_(-1,-1,-1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1,-1, 1)
            glEnd_()
          Else
            glRotatef_(xRotation, 1, 0, 0)
            glRotatef_(yRotation, 0, 1, 0)
            glRotatef_(zRotation, 0, 0, 1)
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(1, 1, -1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1, 1, -1)
              glTexCoord2f_(0, 0) : glVertex3f_(-1, 1, 1)
              glTexCoord2f_(1, 0) : glVertex3f_(1, 1, 1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(2))
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(-1, 1, 1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1, 1, -1)
              glTexCoord2f_(0, 0) : glVertex3f_(-1, -1, -1)
              glTexCoord2f_(1, 0) : glVertex3f_(-1, -1, 1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(3))
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(1, 1, 1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1, 1, 1)
              glTexCoord2f_(0, 0) : glVertex3f_(-1, -1, 1)
              glTexCoord2f_(1, 0) : glVertex3f_(1, -1, 1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(4))
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(-1, 1, -1)
              glTexCoord2f_(0, 1) : glVertex3f_(1, 1, -1)
              glTexCoord2f_(0, 0) : glVertex3f_(1, -1, -1)
              glTexCoord2f_(1, 0) : glVertex3f_(-1, -1, -1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(5))
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(1, 1, -1)
              glTexCoord2f_(0, 1) : glVertex3f_(1, 1, 1)
              glTexCoord2f_(0, 0) : glVertex3f_(1, -1, 1)
              glTexCoord2f_(1, 0) : glVertex3f_(1, -1, -1)
            glEnd_()
            glBindTexture_(#GL_TEXTURE_2D, texturePTR(6))
            glBegin_(#GL_QUADS)
              glTexCoord2f_(1, 1) : glVertex3f_(1, -1, 1)
              glTexCoord2f_(0, 1) : glVertex3f_(-1, -1, 1)
              glTexCoord2f_(0, 0) : glVertex3f_(-1, -1, -1)
              glTexCoord2f_(1, 0) : glVertex3f_(1, -1, -1)
            glEnd_()
          EndIf
          SetGadgetAttribute(0, #PB_OpenGL_FlipBuffers, #True)
      EndSelect
    ForEver

    For rtnCount = 1 To 6
      glDeleteTextures_(1, @texturePTR(rtnCount))
    Next
  EndIf

  For rtnCount = 1 To 6
    cvReleaseImage(@*image(rtnCount))
  Next
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