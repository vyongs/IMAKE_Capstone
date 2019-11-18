;Garden

#CameraSpeed = 0.5

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

;Mouse move
Global Pointer, UserX.f, UserY.f, UserZ.f
; Global Dim prevX.l(10)
; Global Dim prevY.l(10)
Global Dim prevX.l(100)
Global Dim prevY.l(100)
Global Dim vecX.l(100)
Global Dim vecY.l(100)

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
  Define.f KeyX, KeyY, MouseX, MouseY
    
  If InitEngine3D() And  InitKeyboard() And InitSprite() And InitMouse() And InitSound()
    
    myWindow = OpenWindow(#PB_Any, 0, 0, 720, 480, "Title", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    
    SetWindowColor(myWindow, 0)
    OpenWindowedScreen(WindowID(myWindow),0, 0, WindowWidth(myWindow) , WindowHeight(myWindow))    
    KeyboardMode(#PB_Keyboard_International)  
    UsePNGImageDecoder()
    
    Add3DArchive("assets/image", #PB_3DArchive_FileSystem)
    Add3DArchive("assets/sound", #PB_3DArchive_FileSystem)
    
    UsePNGImageDecoder()
    Pointer = LoadSprite(#PB_Any, "assets/image/particle.png", #PB_Sprite_AlphaBlending )
    arrow = LoadSprite(#PB_Any, "assets/image/arrow4.png", #PB_Sprite_AlphaBlending )
    ZoomSprite(Pointer, 50, 50)
    
   ZoomSprite(arrow, 10, 10)
    
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

    CreateNode(0, 0, 0, 0)
    PointerTex = LoadTexture(#PB_Any, "particle.png") 
    PointerMat = CreateMaterial(#PB_Any, TextureID(PointerTex)) ;Result = CreateMaterial(#Material, TextureID)
    
    ribbon=CreateRibbonEffect(#PB_Any, MaterialID(PointerMat), 10, 80, 1000)
    RibbonEffectColor(ribbon, 0, RGBA(255, 0, 0, 255), RGBA(0, 0, 255,255))
    RibbonEffectWidth(ribbon, 4, 100, 30)
    AttachRibbonEffect(ribbon, NodeID(0))
    
    
    Camera = CreateCamera(#PB_Any, 0, 0, 100, 100)
    CameraBackColor(Camera, RGB(255,255,255))

    MoveCamera(Camera, 0, 0, -10)
    CameraLookAt(Camera, 0, 0, 0)
    
    MouseLocate (ScreenWidth()/2, ScreenHeight()/2)
    MoveCamera(Camera, 0, 0, 0, #PB_Absolute) 
    ;-Loop

    While #True
      
      Repeat : Until WindowEvent() = 0

      If ExamineKeyboard()
        If KeyboardPushed(#PB_Key_Left)
          KeyX = -#CameraSpeed
        ElseIf KeyboardPushed(#PB_Key_Right)
          KeyX = #CameraSpeed
        Else
          KeyX * 0.85
        EndIf
        
        If KeyboardPushed(#PB_Key_Up)
          KeyY = -#CameraSpeed
        ElseIf KeyboardPushed(#PB_Key_Down)
          KeyY = #CameraSpeed
        Else
          KeyY * 0.9
        EndIf
      EndIf
      MoveCamera(Camera, KeyX, 0, KeyY,#PB_Local)
      
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
EndProcedure

Procedure RenderGame2D()
  
  Repeat : Until WindowEvent()=0
      mouseX=WindowMouseX(myWindow)
      mouseY=WindowMouseY(myWindow)
      DisplayTransparentSprite(Pointer, mouseX-25, mouseY-25)
      
      For k=0 To 5
        prevX(k+1)=prevX(k)
        prevY(k+1)=prevY(k)
      Next
      
      vecX=mouseX-prevX(5)
      vecY=mouseY-prevY(5)
      
      For k=1 To 8
        DisplayTransparentSprite(Pointer, mouseX-vecX*k-25, mouseY-vecY*k-25)
;         DisplayTransparentSprite(Pointer, mouseX-vecX*3-25-k, mouseY-vecY*3-25-k)
      Next
      prevX(0)=mouseX
      prevY(0)=mouseY
 
EndProcedure
; Procedure RenderGame2D()
;   
;   Repeat : Until WindowEvent()=0
;       mouseX=WindowMouseX(myWindow)
;       mouseY=WindowMouseY(myWindow)
;       DisplayTransparentSprite(Pointer, mouseX-25, mouseY-25)
;       
;       For k=0 To 99
;         prevX(k+1)=prevX(k)
;         prevY(k+1)=prevY(k)
;       Next
;       prevX(0)=mouseX
;       prevY(0)=mouseY
;       
;       For k=0 To 99
;         vecX(k)=prevX(k+1)-prevX(k)
;         vecY(k)=prevY(k+1)-prevY(k)
;       Next
;       
;       
;       For k=0 To 5
;         For j=0 To 7
;           DisplayTransparentSprite(Pointer, prevX(k)+vecX(k)*j-25, prevY(k)+vecY(k)*j-25)
;           DisplayTransparentSprite(Pointer, prevX(k)+vecX(k)*j-25+j, prevY(k)+vecY(k)*j-25)
;           DisplayTransparentSprite(Pointer, prevX(k)+vecX(k)*j-25+j, prevY(k)+vecY(k)*j-25+j)
;           DisplayTransparentSprite(Pointer, prevX(k)+vecX(k)*j-25, prevY(k)+vecY(k)*j-25+j)
;         Next
;       Next
;  
; EndProcedure

Procedure Exit()
  End
EndProcedure
; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 170
; FirstLine = 142
; Folding = 4-
; EnableXP
; DisableDebugger