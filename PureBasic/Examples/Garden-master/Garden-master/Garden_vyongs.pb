IncludePath "C:\Users\Administrator.DESKTOP-78MI24B\Documents\GitHub\IMAKE_Capstone\OpenCV_3.4.1_WIN_32_SRC_(world)"
IncludeFile "cv_webcam_detect_hand.pb"
;Garden

EnableExplicit

;Scene
Global Camera, Light, Window

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

;Sounds
Global SoundLeft, SoundCentral, SoundRight
Global HubCentral, HubLeft, HubRight

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

GameLoad()




;-------------------------------------------------------------------------------------------------------------

Procedure GameLoad() ; 함수 정의
  Protected Window 
    
  If InitEngine3D() And  InitKeyboard() And InitSprite() And InitMouse() And InitSound()
    ; InitEngine3D 
    
    
    myWindow = OpenWindow(#PB_Any, 0, 0, 720, 480, "Title", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ;윈도우는 0번
        ; https://www.purebasic.com/documentation/window/openwindow.html
    
    SetWindowColor(myWindow, 0)
        ;https://www.purebasic.com/documentation/window/setwindowcolor.html
    
    ;-[Screen]
    OpenWindowedScreen(WindowID(myWindow),0, 0, WindowWidth(myWindow) , WindowHeight(myWindow))    
        ;https://www.purebasic.com/documentation/screen/openwindowedscreen.html
    
    KeyboardMode(#PB_Keyboard_International)  
        ;https://www.purebasic.com/documentation/keyboard/keyboardmode.html

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
        ;https://www.purebasic.com/documentation/camera/createcamera.html
    
    CameraBackColor(Camera, RGB(0, 0, 0))

    MoveCamera(Camera, 0, 0, -10)
       ; https://www.purebasic.com/documentation/camera/movecamera.html
    
    CameraLookAt(Camera, 0, 0, 0)
        ;https://www.purebasic.com/documentation/camera/cameralookat.html
    
    ;-Light
    Light = CreateLight(#PB_Any, RGB(255, 255, 255), 0, 0, 0, #PB_Light_Point)
        ;https://www.purebasic.com/documentation/light/createlight.html
    SetLightColor(Light, #PB_Light_SpecularColor, RGB(255, 255, 255))
    SetLightColor(Light, #PB_Light_DiffuseColor, RGB(225, 225, 255))
    
    ;-Sound
    SoundCentral = LoadSound3D(#PB_Any, "ambiance.wav")    
    SoundLeft = LoadSound3D(#PB_Any, "gong.wav")
    SoundRight = LoadSound3D(#PB_Any, "drum.wav")
        ;https://www.purebasic.com/documentation/sound3d/loadsound3d.html
    
    
    ;Sound Hub
    HubCentral = CreateNode(#PB_Any, 0, 0, 10)
        ;https://www.purebasic.com/documentation/node/createnode.html
    
    AttachNodeObject(HubCentral, SoundID3D(SoundCentral))
        ; ** https://www.purebasic.com/documentation/node/attachnodeobject.html
    SoundRange3D(SoundCentral, 1, 40)
        ;https://www.purebasic.com/documentation/sound3d/soundrange3d.html
    PlaySound3D(SoundCentral, #PB_Sound3D_Loop)
    ; 사운드를 실행. #PB_Sound3D_Loop은 소리 계속 실행시킬것인가. 
    
    
    HubLeft = CreateNode(#PB_Any, 30, 0, 10)
    AttachNodeObject(HubLeft, SoundID3D(SoundLeft))
    SoundRange3D(SoundLeft, 1, 40)
    PlaySound3D(SoundLeft, #PB_Sound3D_Loop)
    
    HubRight = CreateNode(#PB_Any, -30, 0, 10)
    AttachNodeObject(HubRight, SoundID3D(SoundRight))
    SoundRange3D(SoundRight, 1, 40)
    PlaySound3D(SoundRight, #PB_Sound3D_Loop)
           
    ;-Particle
    ParticleTex = LoadTexture(#PB_Any, "particle.png") 
    ParticleMat = CreateMaterial(#PB_Any, TextureID(ParticleTex)) ;Result = CreateMaterial(#Material, TextureID)
        ;https://www.purebasic.com/documentation/material/creatematerial.html    
    DisableMaterialLighting(ParticleMat, #True) ;DisableMaterialLighting(#Material, State)

    MaterialBlendingMode(ParticleMat, #PB_Material_Add) ;MaterialBlendingMode(#Material, Mode)
    ; ** https://www.purebasic.com/documentation/material/materialblendingmode.html
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
        \Entity = CreateEntity(#PB_Any, MeshID(\Mesh), MaterialID(LeavesMat)) ;Result = CreateEntity(#Entity, MeshID, MaterialID, [x, y, z [, PickMask [, VisibilityMask]])
           ;https://www.purebasic.com/documentation/entity/createentity.html
        \x = Random(15) * RandomSign()
        \y = Random(2) * RandomSign()        
        \z = Random(30) * RandomSign()
        \angle = RandomFloat(0.1) * RandomSign()
        MoveEntity(\Entity, \x, \y, \z)  ;MoveEntity(#Entity, x, y, z [, Mode])
        RotateEntity(\Entity, 270, 0, 0)   ;RotateEntity(#Entity, x, y, z [, Mode])
      EndWith
      ;with 설명 : https://www.purebasic.com/documentation/reference/with_endwith.html 
    Next  
    
    ;-Eye Ball
    EyeBallMesh = CreateSphere(#PB_Any, 4)  ;Result = CreateSphere(#Mesh, Radius.f [, NbSegments, NbRings])
    EyeBallTex = LoadTexture(-1, "Earth.png")
    EyeBallMat = CreateMaterial(#PB_Any, TextureID(EyeBallTex))
    ScaleMaterial(EyeBallMat, 0.5, 1)
    EyeBall = CreateEntity(-1, MeshID(EyeBallMesh), MaterialID(EyeBallMat), 0, 0, 20) ;(좌표 0,0,20)
    
    
    MouseLocate (ScreenWidth()/2, ScreenHeight()/2)
    MoveCamera(Camera, 0, 0, 0, #PB_Absolute) 
    ;-Loop
    While #True
      Repeat : Until WindowEvent() = 0
      UserX = (ScreenWidth()/2 - WindowMouseX(myWindow) )*30/360
      UserY = (ScreenWidth()/2 - WindowMouseY(myWindow) )*30/240
      ; WindowMouseX(myWindow)/ScreenWidth() <- 정 가운데 점. 
      ; X 범위 -360 ~ 360  , Y 범위 -240 ~ 240

      MoveCamera(Camera, UserX, 0, UserY,#PB_Absolute);
      ; x-왼쪽, 오른쪽 이동 / z -앞, 뒤 이동 
      
     
      ;Debug WindowMouseX(myWindow)  + WindowMouseY(myWindow)
      
      FlipBuffers()  
      RenderGame3D()
      RenderWorld()
      RenderGame2D()
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
  
  SoundListenerLocate(CameraX(Camera), CameraY(Camera), CameraZ(Camera))
   
  ;Eye follow camera (나를 따라서 구가 회전)
  EntityLookAt(EyeBall, Userx, 0, UserY)
 
EndProcedure

Procedure RenderGame2D()
  ;25 = Pointer width  / 2
  DisplayTransparentSprite(Pointer, DesktopMouseX()-25, DesktopMouseY()-25)
EndProcedure

Procedure Exit()
  End
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 84
; FirstLine = 57
; Folding = --
; EnableXP