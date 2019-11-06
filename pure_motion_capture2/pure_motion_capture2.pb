

;EnableExplicit

Prototype.l appel_fonction1(titr$, type,type1,type2, type3, type4, id ,type5)

;{ CAP constants
#WM_CAP_START = #WM_USER
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
; #w16 = 40
; #h16 = 30
#w16 = 80
#h16 = 60

Structure avg
            r.l
            g.l
            b.l
EndStructure

Global hWndC
Define Ccam_lib1, *capAddress

Procedure rotate90(*MemoryTarget,W,H,size)
             Protected X,Y,Target, Origin, *MemoryOrigin = AllocateMemory (size)
             CopyMemory (*MemoryTarget,*MemoryOrigin,size)
             For Y = 0 To H - 1
                         For X = 0 To W - 1
                                    Origin = (Y * W + X) << 2
                                    Target = ((H - Y - 1) + (X * H)) << 2
                                     PokeL (*MemoryTarget + Target, PeekL (*MemoryOrigin + Origin))
                         Next
             Next
             FreeMemory (*MemoryOrigin)
EndProcedure



Procedure greyScale(*Memory, memorysize )
             Protected Counter, Color
             For Counter = 0 To memorysize - 1 Step 4
                        Color = PeekL (*Memory + Counter)
                        Color = ( Red (Color) + Green (Color) + Blue (Color)) / 3
                         PokeL (*Memory + Counter, RGB (Color, Color, Color))
             Next
EndProcedure



Procedure captureImage(dummy)
             Protected image, bmp.BITMAP, imageid , imageSize, *bits, pos
             Protected Dim prev.avg( #w16 , #h16 )
             Protected X,Y,yy,xx, avg.avg, Color, diff
            
             Repeat
                         SendMessage_ (hWndC, #WM_CAP_EDIT_COPY ,0,0)
                        image = GetClipboardImage ( #PB_Any ,32)
                         If image<>0
                                     imageid = ImageID (image) ;maybe flip it first
                                    
                                     GetObject_ ( imageid , SizeOf (BITMAP),@bmp.BITMAP)
                                    imageSize = bmp\bmWidthBytes * bmp\bmHeight
                                    *bits = bmp\bmBits
                                    
                                     StartDrawing ( WindowOutput (0))
                                                 DrawImage ( imageid ,0,0) ;____________________________________________ici
                                                 DrawingMode ( #PB_2DDrawing_Outlined )
                                                
                                                 For X=0 To #w16 -1
                                                             For Y=0 To #h16 -1
                                                                        avg\r = 0: avg\g=0: avg\b=0
                                                                         For xx=X*8 To X*8+8-1
                                                                                     For yy=Y*8 To Y*8+8-1
                                                                                                pos = (yy * bmp\bmWidth + xx) << 2
                                                                                                Color = PeekL (*bits+pos)
                                                                                                avg\r + Red (Color)
                                                                                                avg\g + Green (Color)
                                                                                                avg\b + Blue (Color)
                                                                                                 ;Plot(xx,479-yy,color)
                                                                                     Next
                                                                         Next
                                                                        avg\r = avg\r / 256
                                                                        avg\g = avg\g / 256
                                                                        avg\b = avg\b / 256
                                                                 ; Box(X*16,Y*16,16,16,RGB(avg\r,avg\g,avg\b))
                                                                        diff = 0
                                                                        diff + Abs (prev(X,Y)\r - avg\r)
                                                                        diff + Abs (prev(X,Y)\g - avg\g)
                                                                        diff + Abs (prev(X,Y)\b - avg\b)
                                                                         If diff > 20 ;40
                                                                                     Box (X*8,464-Y*8,7,7, #Green )
                                                                             ; Circle(X*16+8,464-Y*16+8,8,#Green) ;Or circleIfif you want
                                                                         EndIf
                                                                        prev(X,Y)\r = avg\r
                                                                        prev(X,Y)\g = avg\g
                                                                        prev(X,Y)\b = avg\b
                                                             Next
                                                 Next
                                                
                                     ; DrawImage(imageID,0,0)
                                     StopDrawing ()
                                     FreeImage (image)
                         EndIf
                        
                         ;Delay(2000)
             ForEver
EndProcedure



If OpenWindow ( #Main ,0,0,640,480, "Motion Detection 2019 DSCHO " , #PB_Window_ScreenCentered|#PB_Window_SystemMenu )
            Ccam_lib1 = OpenLibrary ( #PB_Any , "avicap32.dll" )
             If Ccam_lib1
                        appel_fonction1.appel_fonction1 = GetFunction (Ccam_lib1, "capCreateCaptureWindowA" )
                        hWndC= appel_fonction1( "My Capture Window" , #WS_CHILD | #WS_VISIBLE , 0,0, 1 , 1, WindowID ( #Main ),0)
                         SendMessage_ (hWndC, #WM_CAP_DRIVER_CONNECT , 0, 0)
                         SendMessage_ (hWndC, #WM_CAP_SET_OVERLAY , #True , 0)
                         SendMessage_ (hWndC, #WM_CAP_SET_PREVIEW , #True , 0)
                         SendMessage_ (hWndC, #WM_CAP_SET_PREVIEWRATE , 1, 0)
             EndIf
EndIf


CreateThread (@captureImage(),0)

Repeat
             Delay (10)
Until WaitWindowEvent () = #PB_Event_CloseWindow

SendMessage_ (hWndC, #WM_CAP_STOP ,0,0)
SendMessage_ (hWndC, #WM_CAP_DRIVER_DISCONNECT ,0,0)
DestroyWindow_ (hWndC)
CloseLibrary (Ccam_lib1)


; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 91
; FirstLine = 71
; Folding = -
; EnableXP