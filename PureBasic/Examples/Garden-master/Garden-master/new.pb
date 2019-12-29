;Motion Capture
Declare appel_fonction1(titr$, type,type1,type2, type3, type4, id ,type5)
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
;https://docs.microsoft.com/en-us/windows/win32/multimedia/multimedia-messages
;reference to wm_sth constants
#Main =0
#camWidth = 640
#camHeight = 480
; #w16=320
; #h16=240
; #w16 = 40
; #h16 = 30
#w16 = 80
#h16 = 60
; #w16=160
; #h16=120
#ratioW = #camWidth / #w16 ;8 
#ratioH = #camHeight / #h16 ;8
#squareSizeW=#ratioW-1
#squareSizeH=#ratioH-1

Structure avg
  r.l
  g.l
  b.l
EndStructure

Global hWndC, Xpavg, Ypavg
Define Ccam_lib1, *capAddress


;--------------------------------------------------------

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
Declare captureImage(dumm)
Declare captureWindow()

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
      
     
      Debug WindowMouseX(myWindow)  + WindowMouseY(myWindow)
      
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

;--------------------------------------------------------------------

Procedure captureImage(dummy)
  Protected image, bmp.BITMAP, imageid , imageSize, *bits, pos
  Protected Dim prev.avg( #w16 , #h16 )
  Protected X,Y,yy,xx, avg.avg, Color, diff
  
  Repeat
    SendMessage_ (hWndC, #WM_CAP_EDIT_COPY ,0,0) ;copy the content of the video frame buffer
    image = GetClipboardImage ( #PB_Any ,32) ;create new image from the clipboard image data, #PB_ANY는 이미지 번호 자동 생성
    If image<>0
      imageid = ImageID (image) ;maybe flip it first, returns image ID of the image
      
      GetObject_ ( imageid , SizeOf (BITMAP),@bmp.BITMAP) ;bmp포인터에 객체 크기 리턴
                                                          ;여기서는 @가 C의 &임
      ;by using \ it can access any memory address in structured way
      imageSize = bmp\bmWidthBytes * bmp\bmHeight
      *bits = bmp\bmBits
      ;https://m.blog.naver.com/PostView.nhn?blogId=tipsware&logNo=220983334717&proxyReferer=https%3A%2F%2Fwww.google.com%2F
      ;infos about BITMAP structure
      
;       Debug bmp\bmBits ;about memory addr
;       Debug bmp\bmHeight ;about size of height in pixel
;       Debug bmp\bmWidthBytes ;about size of width in bytes
;       Debug bmp\bmWidth ;about size of width in pixels

      StartDrawing ( WindowOutput (0)) ;change the current drawing output 
      ;to the specified output, StopDrawing()과 같이 사용해야함
      
      ;draws an image to the current drawing output, current drawing output is set by startDrawing
      DrawImage (imageid ,0,0) ;____________________________________________ici
      ;imageid of the image to draw
      ;x,y is position of image drawing output
      
      DrawingMode ( #PB_2DDrawing_Default );behavior for further drawing options
                                            ;PB_2DDrawing_Default/Transparent/XOr/Outlined
                                            ;/AlphaBlend/AlphaClip/AlphaChannel/AllChannels
                                            ;/Gradient/CustomFilter이 존재

      For X=0 To #w16-1 ;80
        For Y=0 To #h16-1 ;60
          avg\r = 0: avg\g=0: avg\b=0
          For xx=X*#ratioW To X*#ratioW+#ratioW-1 ;bmHeight가 480, bmWidth가 640이라서 다 방문하려고
            For yy=Y*#ratioH To Y*#ratioH+#ratioH-1
              pos = (yy * bmp\bmWidth + xx) << 2 ;shift 연산자...이건 왜인지는 모르겠엄
              Color = PeekL (*bits+pos) ;reads a long(4bytes)number from the memory addr
              
              avg\r + Red (Color) ;returns the red component of a color value
              ;왜인지 모르지만 +=안해도 avg\r값에 Red(Color)더함
              avg\g + Green (Color)
              avg\b + Blue (Color)
              ;Plot(xx,479-yy,color)
            Next ;end of yy
          Next   ;end of xx
          
          avg\r = avg\r / 256
          avg\g = avg\g / 256
          avg\b = avg\b / 256
          ; Box(X*16,Y*16,16,16,RGB(avg\r,avg\g,avg\b))
          
          diff = 0
          ;prev(X,Y)가 뭐하는건지 모르겠음..뭔가 주소값이긴한데
          diff + Abs (prev(X,Y)\r - avg\r)
          diff + Abs (prev(X,Y)\g - avg\g)
          diff + Abs (prev(X,Y)\b - avg\b)
          ;어쨌든 뭔가 이 prev로 이전과 차이를 계산함
          
          If diff > 20 ;40  ;차이가 20보다 크면 그 위치에 초록박스그림
            Box (X*#ratioW,#camHeight-Y*#ratioH,#squareSizeW,#squareSizeH, #Red ) ;x,y,Width,Height, Color 원래는 464
                                                                                  ; Circle(X*16+8,464-Y*16+8,8,#Green) ;Or circleIfif you want
            Xpavg + X
            Ypavg + Y            
          EndIf
          prev(X,Y)\r = avg\r ;여기서 prev를 저장해줌 그치만 prev가 뭔지는 모르겠다
          prev(X,Y)\g = avg\g
          prev(X,Y)\b = avg\b
        Next ;end of Y
      Next ;end of X
      
      ; DrawImage(imageID,0,0)
      StopDrawing ()
      FreeImage (image)
    EndIf ;image <>0 end
    
    ;Delay(2000)
  ForEver ;endless loop
EndProcedure  ;end of procedure


If OpenWindow ( #Main ,0,0,#camWidth,#camHeight, "Motion Detection 2019 DSCHO " , #PB_Window_ScreenCentered|#PB_Window_SystemMenu )  ;non zero if window is created
  Ccam_lib1 = OpenLibrary ( #PB_Any , "avicap32.dll" )                                                                  ;non zero if library is opened
  If Ccam_lib1  
    appel_fonction1.appel_fonction1 = GetFunction (Ccam_lib1, "capCreateCaptureWindowA" ) ;returns function pointer in previous opened library
    hWndC= appel_fonction1( "Motion Detection 2019 DSCHO" , #WS_CHILD | #WS_VISIBLE,0,0,1,1, WindowID(#Main),0)
    
    SendMessage_ (hWndC, #WM_CAP_DRIVER_CONNECT , 0, 0)  ;장치선택
    SendMessage_ (hWndC, #WM_CAP_SET_OVERLAY , #True , 0);overlay모드 선택
                                                         ;??true는 overlay mode:video is displayed using hardware overlay
    SendMessage_ (hWndC, #WM_CAP_SET_PREVIEW , #True , 0) ;display여부
    SendMessage_ (hWndC, #WM_CAP_SET_PREVIEWRATE , 1, 0) 
    ;set frame display rate, 수치는 milliseconds, 소수점은 인식 못하는듯
  EndIf
EndIf


CreateThread (@captureImage(),0)

Repeat
  Delay (10)
Until WaitWindowEvent () = #PB_Event_CloseWindow  ;window close까지 반복

SendMessage_ (hWndC, #WM_CAP_STOP ,0,0)
SendMessage_ (hWndC, #WM_CAP_DRIVER_DISCONNECT ,0,0)
DestroyWindow_ (hWndC)
CloseLibrary (Ccam_lib1)



; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 2
; Folding = v-
; EnableXP