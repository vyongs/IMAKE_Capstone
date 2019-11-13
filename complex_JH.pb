;Garden
Prototype.l appel_fonction1(titr$, type,type1,type2, type3, type4, id ,type5)
;$는 string

;{ CAP constants, avicap.dll을 사용하기 위한 변수
#WM_CAP_START = #WM_USER ;#WM_USER 초기값 1024, 0 through wm_user-1 are defined by the system
#WM_CAP_DRIVER_CONNECT = #WM_CAP_START + 10
#WM_CAP_DRIVER_DISCONNECT = #WM_CAP_START + 11
#WM_CAP_DRIVER_GET_CAPS = #WM_CAP_START + 14
#WM_CAP_EDIT_COPY = #WM_CAP_START + 30
#WM_CAP_SET_PREVIEW = #WM_CAP_START + 50
#WM_CAP_SET_PREVIEWRATE = #WM_CAP_START + 52
#WM_CAP_STOP = #WM_CAP_START + 68
#WM_CAP_SET_SCALE = #WM_CAP_START + 53
#WM_CAP_START = #WM_USER
#WM_CAP_DLG_VIDEOSOURCE = #WM_CAP_START + 42
;}

#Main =0
#camWidth = 640
#camHeight = 480
#w16 = 80
#h16 = 60
#ratioW = #camWidth / #w16
#ratioH = #camHeight / #h16
#squareSizeW=#ratioW-1
#squareSizeH=#ratioH-1

Structure avg
  r.l
  g.l
  b.l
EndStructure

Global hWndC

; EnableExplicit  ;이거 뭔지 모르지만 일단 없애야 돌아간다....

;Scene
Global Camera, Light

;Leaves
Structure NewLeave
  Mesh.i
  Entity.i
  x.f
  y.f
  z.f
  angle.f
EndStructure
Global Dim Leaves.NewLeave(200), LeavesMat, Index

;Window
Global myWindow

;EyeBall
Global EyeBall, EyeBallMesh, EyeBallTex, EyeBallMat

;Particle
Global Emitter, Particle, ParticleTex, ParticleMat 

;Mouse move
Global Pointer, UserX.f, UserY.f, UserZ.f

;Summary
Declare GameLoad()
Declare RenderGame3D()
Declare RenderGame2D() 
Declare Exit()

; Returns a random float in the interval [0.0, Maximum]
Macro RandomFloat(Maximum=1.0)
  ( Random(2147483647)*Maximum*4.6566128752457969241e-10 ) ; Random * 1/MaxRandom
EndMacro

; Returns a random sign {-1, 1}
Macro RandomSign()
  ( Random(1)*2-1 ) 
EndMacro
;-------------------------------------------------------MAIN----------------------------------------------------------
Define  Ccam_lib1, *capAddress

Ccam_lib1 = OpenLibrary ( #PB_Any , "avicap32.dll" )        
myWindow = OpenWindow(#PB_Any, 0, 0, #camWidth, #camHeight, "garden_Motion Detection", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
SetWindowColor(myWindow, 0)

If Ccam_lib1  
  appel_fonction1.appel_fonction1 = GetFunction (Ccam_lib1, "capCreateCaptureWindowA" ) ;returns function pointer in previous opened library
  hWndC= appel_fonction1( "Motion Detection" , #WS_CHILD | #WS_VISIBLE,0,0,1,1, WindowID(myWindow),0)
  SendMessage_ (hWndC, #WM_CAP_DRIVER_CONNECT , 0, 0)
  SendMessage_ (hWndC, #WM_CAP_SET_OVERLAY , #True , 0)
  SendMessage_ (hWndC, #WM_CAP_SET_PREVIEW , #True , 0) 
  SendMessage_ (hWndC, #WM_CAP_SET_PREVIEWRATE , 1, 0) 
EndIf

GameLoad()
;-------------------------------------------------------------------------------------------------------------

Procedure GameLoad() ; 함수 정의

  If InitEngine3D() And  InitKeyboard() And InitSprite() And InitMouse() And InitSound()

    OpenWindowedScreen(WindowID(myWindow),0, 0, WindowWidth(myWindow) , WindowHeight(myWindow))    
    KeyboardMode(#PB_Keyboard_International)  
    ;-[2D]
    ;Arrow
    UsePNGImageDecoder()
        ;https://www.purebasic.com/documentation/imageplugin/usepngimagedecoder.html
   Pointer = LoadSprite(#PB_Any, "assets/image/arrow4.png", #PB_Sprite_AlphaBlending )
        ; https://www.purebasic.com/documentation/sprite/loadsprite.html
   ZoomSprite(Pointer, 50, 50)
       ;https://www.purebasic.com/documentation/sprite/zoomsprite.html

    ;-[3D]
    Add3DArchive("assets/image", #PB_3DArchive_FileSystem)
    Add3DArchive("assets/sound", #PB_3DArchive_FileSystem)
        ;https://www.purebasic.com/documentation/engine3d/add3darchive.html
            
    ;-Camera
    Camera = CreateCamera(#PB_Any, 0, 0, 100, 100)
    CameraBackColor(Camera, RGB(0, 0, 0))
    MoveCamera(Camera, 0, 0, -10)
    CameraLookAt(Camera, 0, 0, 0)
    
    ;-Light
    Light = CreateLight(#PB_Any, RGB(255, 255, 255), 0, 0, 0, #PB_Light_Point)
    SetLightColor(Light, #PB_Light_SpecularColor, RGB(255, 255, 255))
    SetLightColor(Light, #PB_Light_DiffuseColor, RGB(225, 225, 255))
           
    ;-Particle
    ParticleTex = LoadTexture(#PB_Any, "particle.png") 
    ParticleMat = CreateMaterial(#PB_Any, TextureID(ParticleTex))   
    DisableMaterialLighting(ParticleMat, #True) 

    MaterialBlendingMode(ParticleMat, #PB_Material_Add)
    Emitter = CreateParticleEmitter(#PB_Any, 100, 100, 100, #PB_Particle_Box) ;CreateParticleEmitter(#ParticleEmitter, emitte size_Width, Height, Depth, Type, [, initial position_x.f, y.f, z.f])
    ParticleMaterial(Emitter, MaterialID(ParticleMat))
    ParticleTimeToLive(Emitter, 1, 3)
    ParticleEmissionRate(Emitter, 200) ;ParticleEmissionRate(#ParticleEmitter, Rate-The new particle emission rate, in particles per second.)
    ParticleSize(Emitter, 1, 1) ;ParticleTimeToLive(#ParticleEmitter, MinimumTime, MaximumTime)
    
    ;-Leaves
    Global LeavesTex = LoadTexture(#PB_Any, "viny_leaves.png")
    LeavesMat = CreateMaterial(#PB_Any, TextureID(LeavesTex))   
    MaterialBlendingMode(LeavesMat, #PB_Material_AlphaBlend)
    
    For Index = 0 To 199
      With Leaves(Index)
        \Mesh = CreatePlane(#PB_Any, 4, 4, 1, 1, 1, 1)  ;CreatePlane (#Mesh, TileSizeX, TileSizeZ, TileCountX, TileCountZ, TextureRepeatCountX, TextureRepeatCountZ)
        \Entity = CreateEntity(#PB_Any, MeshID(\Mesh), MaterialID(LeavesMat)) 
        \x = Random(15) * RandomSign()
        \y = Random(2) * RandomSign()        
        \z = Random(30) * RandomSign()
        \angle = RandomFloat(0.1) * RandomSign()
        MoveEntity(\Entity, \x, \y, \z) 
        RotateEntity(\Entity, 270, 0, 0)  
      EndWith
    Next  
    
    EyeBallMesh = CreateSphere(#PB_Any, 4) 
    EyeBallTex = LoadTexture(-1, "EYE.png")
    EyeBallMat = CreateMaterial(#PB_Any, TextureID(EyeBallTex))
    ScaleMaterial(EyeBallMat, 0.5, 1)
    EyeBall = CreateEntity(-1, MeshID(EyeBallMesh), MaterialID(EyeBallMat), 0, 0, 20) ;(좌표 0,0,20)
    MouseLocate (ScreenWidth()/2, ScreenHeight()/2)
    MoveCamera(Camera, 0, 0, 0, #PB_Absolute) 
    ;-Loop
    Global done
    ;     done = #False
    Protected image, bmp.BITMAP, imageid , imageSize, *bits, pos
    Protected Dim prev.avg( #w16 , #h16 )
    Protected X,Y,yy,xx, avg.avg, Color, diff
    
    While #True
      Repeat : Until WindowEvent() = 0
      
      UserX = (ScreenWidth()/2 - WindowMouseX(myWindow) )*30/360
      UserY = (ScreenWidth()/2 - WindowMouseY(myWindow) )*30/240
      MoveCamera(Camera, UserX, 0, UserY,#PB_Absolute)
      FlipBuffers()  
      RenderGame3D()
      RenderWorld()
      RenderGame2D()
      
      SendMessage_ (hWndC, #WM_CAP_EDIT_COPY ,0,0)
      image = GetClipboardImage ( #PB_Any ,32) 
      If image<>0
        imageid = ImageID (image) 
        GetObject_ ( imageid , SizeOf (BITMAP),@bmp.BITMAP) 
        imageSize = bmp\bmWidthBytes * bmp\bmHeight
        *bits = bmp\bmBits
        StartDrawing ( WindowOutput(myWindow)) 
        DrawingMode ( #PB_2DDrawing_Default )
  
        For X=0 To #w16-1
          For Y=0 To #h16-1 
            avg\r = 0: avg\g=0: avg\b=0
            For xx=X*#ratioW To X*#ratioW+#ratioW-1 
              For yy=Y*#ratioH To Y*#ratioH+#ratioH-1
                pos = (yy * bmp\bmWidth + xx) << 2 
                Color = PeekL (*bits+pos)
                avg\r + Red (Color) 
                avg\g + Green (Color)
                avg\b + Blue (Color)
              Next
            Next
            
            avg\r = avg\r / 256
            avg\g = avg\g / 256
            avg\b = avg\b / 256
            diff = 0
            diff + Abs (prev(X,Y)\r - avg\r)
            diff + Abs (prev(X,Y)\g - avg\g)
            diff + Abs (prev(X,Y)\b - avg\b)
            
            If diff > 20 ;40 
              Box (X*#ratioW,#camHeight-Y*#ratioH,#squareSizeW,#squareSizeH, #Red) 
            EndIf
            prev(X,Y)\r = avg\r 
            prev(X,Y)\g = avg\g
            prev(X,Y)\b = avg\b
          Next 
        Next
        StopDrawing ()
        FreeImage (image)
      EndIf 
    Wend
    
    Else
    
    EndIf 
EndProcedure

Procedure RenderGame3D()  
  
  If ExamineKeyboard()
    If KeyboardReleased(#PB_Key_Escape)
      Exit()
    EndIf  
  EndIf

  For Index = 0 To 199
    With Leaves(Index)
      RotateEntity(\Entity, 0, \angle, 0, #PB_Relative)
    EndWith
  Next  
;   SoundListenerLocate(CameraX(Camera), CameraY(Camera), CameraZ(Camera))
 
EndProcedure

Procedure RenderGame2D()
  DisplayTransparentSprite(Pointer, WindowMouseX(myWindow)-25, WindowMouseY(myWindow)-25)
EndProcedure

Procedure Exit()
  SendMessage_ (hWndC, #WM_CAP_STOP ,0,0)
  SendMessage_ (hWndC, #WM_CAP_DRIVER_DISCONNECT ,0,0)
  DestroyWindow_ (hWndC)
  CloseLibrary (Ccam_lib1)
  End
EndProcedure

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 88
; FirstLine = 74
; Folding = H+
; EnableXP