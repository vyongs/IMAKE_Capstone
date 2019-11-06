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
    
    
    Window = OpenWindow(#PB_Any, 0, 0, 0, 0, "", #PB_Window_Maximize | #PB_Window_BorderLess)
    ;OpenWindow (#Window, x, y, InnerWidth, InnerHeight, Title $ [, Flags [, ParentWindowID]])
        ; #PB_Any(새 창을 식별하기 위한 숫자, #PB_Any는 자동으로 숫자 생성해줌), x, y,(윈도우의 초기 위치 (픽셀 단위) (x'또는 'y'가 #PB_Ignore 로 설정된 경우 OS는 창의 위치를 ​​선택합니다.)
        ; InnerWidth, InnerHeight (필요한 클라이언트 영역을 픽셀 단위로 표시합니다 (테두리 및 창 장식 없음).)
        ; Title (새로 만든 창의 제목입니다.)
        ; flag는 선택사항 -- #PB_Window_Maximize (최대화 된 창) | #PB_Window_BorderLess (테두리 없이)
        ; https://www.purebasic.com/documentation/window/openwindow.html
    
    SetWindowColor(Window, 0)
    ;SetWindowColor(#Window, Color)
        ;#Window (윈도우 이름), Color (배경색깔이며 다양하게 설정가능 자세한 사항 밑에 링크)
        ;https://www.purebasic.com/documentation/window/setwindowcolor.html
    
    ;-[Screen]
    OpenWindowedScreen(WindowID(Window),0, 0, WindowWidth(Window) , WindowHeight(Window))    
    ;Result = OpenWindowedScreen(WindowID, x, y, Width, Height [, AutoStretch, RightOffset, BottomOffset [, FlipMode]])
        ;https://www.purebasic.com/documentation/screen/openwindowedscreen.html
    
    KeyboardMode(#PB_Keyboard_International)  
    ;KeyboardMode(Flags)
        ;#PB_Keyboard_International  : The keyboard uses the default language layout to map the keys (can be useful for non QWERTY keyboards).
        ;https://www.purebasic.com/documentation/keyboard/keyboardmode.html

    ;-[2D]
    ;Arrow
    UsePNGImageDecoder()
        ;CatchImage () , LoadImage () , CatchSprite () 및 LoadSprite () 함수에 대한 PNG (Portable Network Graphic) 이미지 지원을 활성화합니다.
        ;https://www.purebasic.com/documentation/imageplugin/usepngimagedecoder.html
   Pointer = LoadSprite(#PB_Any, "assets/image/arrow4.png", #PB_Sprite_AlphaBlending )
    ; Result = LoadSprite (#Sprite, Filename $ [, Mode])
        ; #Sprite (새로로드 된 스프라이트를 식별하기위한 숫자입니다. #PB_Any 를 사용하여이 번호를 자동 생성 할 수 있습니다.)
        ; https://www.purebasic.com/documentation/sprite/loadsprite.html
   ZoomSprite(Pointer, 50, 50)
       ; Sprite를 확대, 축소
       ;https://www.purebasic.com/documentation/sprite/zoomsprite.html

    ;-[3D]
    Add3DArchive("assets/image", #PB_3DArchive_FileSystem)
    Add3DArchive("assets/sound", #PB_3DArchive_FileSystem)
    ;Result = Add3DArchive(Path$, Type)
        ;#PB_3DArchive_FileSystem : Standard directory //  #PB_3DArchive_Zip : Compressed zip file
        ;zip파일 아니니까 #PB_3DArchive_FileSystem 선택됨.
        ;https://www.purebasic.com/documentation/engine3d/add3darchive.html
            
    ;-Camera
    Camera = CreateCamera(#PB_Any, 0, 0, 100, 100)
    ;Result = CreateCamera(#Camera, x, y, Width, Height [, VisibilityMask])
        ;#Camera (카메라 식별 번호)
        ;지정된 치수로 x, y 위치에서 현재 세계에 새 카메라를 만듭니다. 이 위치와 크기는 세계 카메라 위치와 크기가 아니라 화면의 디스플레이 위치와 크기입니다. 다른 그래픽 관련 기능과 달리이 좌표 및 치수는 0에서 100까지의 백분율로 표시됩니다.
        ;https://www.purebasic.com/documentation/camera/createcamera.html
    
    CameraBackColor(Camera, RGB(0, 0, 0))

    MoveCamera(Camera, 0, 0, -10)
    ;MoveCamera(#Camera, x, y, z [, Mode]) 카메라를 지정 위치로 움직임
       ; x,y,z (	The new position of the camera.)
       ; https://www.purebasic.com/documentation/camera/movecamera.html
    
    CameraLookAt(Camera, 0, 0, 0)
    ;CameraLookAt(#Camera, x, y, z)
        ;x,y,z (카메라를 가리키는 위치 (세계 단위)입니다.)
        ;https://www.purebasic.com/documentation/camera/cameralookat.html
    
    ;-Light
    Light = CreateLight(#PB_Any, RGB(255, 255, 255), 0, 0, 0, #PB_Light_Point)
    ;Result = CreateLight(#Light, Color [, x, y, z [, Flags]])
        ;#PB_Light_Point       : Creates a point light (the light is emitted in all directions) (Default)
        ;https://www.purebasic.com/documentation/light/createlight.html
    SetLightColor(Light, #PB_Light_SpecularColor, RGB(255, 255, 255))
    SetLightColor(Light, #PB_Light_DiffuseColor, RGB(225, 225, 255))
    
    ;-Sound
    SoundCentral = LoadSound3D(#PB_Any, "ambiance.wav")    
    SoundLeft = LoadSound3D(#PB_Any, "gong.wav")
    SoundRight = LoadSound3D(#PB_Any, "drum.wav")
    ;Result = LoadSound3D(#Sound3D, Filename$ [, Flags])
        ;https://www.purebasic.com/documentation/sound3d/loadsound3d.html
    
    
    ;Sound Hub
    HubCentral = CreateNode(#PB_Any, 0, 0, 10)
    ;Result = CreateNode(#Node [, x, y, z])
        ;https://www.purebasic.com/documentation/node/createnode.html
    
    AttachNodeObject(HubCentral, SoundID3D(SoundCentral))
        ; Attachs an existing object to a node.
        ; Returns the unique system identifier of the sound.
        ; ** https://www.purebasic.com/documentation/node/attachnodeobject.html
    SoundRange3D(SoundCentral, 1, 40)
    ;SoundRange3D(#Sound3D, Minimum, Maximum)
        ; Minimum (사운드 볼륨이 페이딩되기 시작할 때 사운드 위치로부터의 거리입니다.)
        ; Maximum (이 거리 이상에서는 사운드 재생이 중지됩니다.)
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
        ;TextureID : The texture to use. A valid 'TextureID' can be easily obtained with TextureID().
        ;https://www.purebasic.com/documentation/material/creatematerial.html    
    DisableMaterialLighting(ParticleMat, #True) ;DisableMaterialLighting(#Material, State)
        ;동적 #Material 조명을 활성화 또는 비활성화합니다. 이 머티리얼을 사용할 오브젝트는 CreateLight () 함수로 생성 된 동적 라이트의 영향을받지 않습니다 . 재질을 만들 때 기본적으로 동적 조명이 활성화됩니다.
        ;#True : dynamic lighting is disabled. / #False: dynamic lighting is enabled.

    MaterialBlendingMode(ParticleMat, #PB_Material_Add) ;MaterialBlendingMode(#Material, Mode)
    ;  #PB_Material_Add        : 장면에 대해 픽셀 '추가'작업을 수행합니다 (검정색은 투명합니다).
    ;  #PB_Material_AlphaBlend : 텍스처의 AlphaChannel 레이어 (TGA 또는 PNG 여야 함)를 사용하여 씬과 블렌드합니다.
    ;  #PB_Material_Color      : 재질을 장면과 혼합 할 때 텍스처 투명 색상 값을 사용합니다.
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
    ;-Loop
    While #True
      
      Repeat

      Until Event = #PB_Event_CloseWindow
      
      FlipBuffers()  
      RenderGame3D()
      RenderWorld()
      RenderGame2D()
    Wend
  Else
    
  EndIf 
EndProcedure

Procedure RenderGame3D()  
  ;Protected x.f = CameraX(Camera) + ((UserX * -10) - CameraX(Camera)) * 0.05  
  ;Protected z.f = CameraZ(Camera) + ((UserY * -10) - CameraZ(Camera)) * 0.05  
  Protected x.f = CameraX(Camera) + (UserX * 10)
  Protected z.f = CameraZ(Camera) + (UserY * 10) 
  
  
  If ExamineKeyboard()
    If KeyboardReleased(#PB_Key_Escape)
      Exit()
    EndIf  
  EndIf
  
  ;If ExamineMouse() ; ExamineMouse()- Return value is Nonzero if the mouse state has been updated, zero otherwise.
    ;UserX =  -1 + (MouseX()/ScreenWidth())*2 ; 범위 -1 ~ 1
    ;UserY =  -1 + (MouseY()/ScreenWidth())*2
    
 
  ;EndIf
  
  For Index = 0 To 199
    With Leaves(Index)
      RotateEntity(\Entity, 0, \angle, 0, #PB_Relative)
    EndWith
  Next  
  
  
  ;SoundListenerLocate(CameraX(Camera), CameraY(Camera), CameraZ(Camera))
   
  ;Eye follow camera
  ;EntityLookAt(EyeBall, x, 0, z) 
 
EndProcedure

Procedure RenderGame2D()
  ;25 = Pointer width  / 2
  DisplayTransparentSprite(Pointer, UserX, UserY)
EndProcedure

Procedure Exit()
  End
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 220
; FirstLine = 208
; Folding = --
; EnableXP