;https://www.academia.edu/15452637/Pure_Basic_-_A_Beginners_Guide
;다운로드 회원가입하라해서 안함

;EnableExplicit

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
Define Ccam_lib1, *capAddress

; Procedure rotate90(*MemoryTarget,W,H,size)
;              Protected X,Y,Target, Origin, *MemoryOrigin = AllocateMemory (size)
;              CopyMemory (*MemoryTarget,*MemoryOrigin,size)
;              For Y = 0 To H - 1
;                          For X = 0 To W - 1
;                                     Origin = (Y * W + X) << 2
;                                     Target = ((H - Y - 1) + (X * H)) << 2
;                                      PokeL (*MemoryTarget + Target, PeekL (*MemoryOrigin + Origin))
;                          Next
;              Next
;              FreeMemory (*MemoryOrigin)
; EndProcedure
; 
; 
; 
; Procedure greyScale(*Memory, memorysize )
;              Protected Counter, Color
;              For Counter = 0 To memorysize - 1 Step 4
;                         Color = PeekL (*Memory + Counter)
;                         Color = ( Red (Color) + Green (Color) + Blue (Color)) / 3
;                          PokeL (*Memory + Counter, RGB (Color, Color, Color))
;              Next
; EndProcedure



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
; CursorPosition = 87
; FirstLine = 78
; Folding = -
; EnableXP