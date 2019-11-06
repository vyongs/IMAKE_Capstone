UseJPEGImageEncoder()
UseJPEGImageDecoder()
Enumeration
 
  #Window_0
  #Button_0
  #Button_1
  #Button_2
  #Button_4
  #viewer1
  #gadget1
  #counter
  #counter1
  #name
  #takebut
  #viewbut
  #quitbut
EndEnumeration
#WM_CAP_START = #WM_USER
#WM_CAP_DRIVER_CONNECT = #WM_CAP_START + 10
#WM_CAP_DRIVER_DISCONNECT = #WM_CAP_START + 11
#WM_CAP_DRIVER_GET_CAPS = #WM_CAP_START + 14
#WM_CAP_EDIT_COPY = #WM_CAP_START + 30
#WM_CAP_SET_PREVIEW = #WM_CAP_START + 50
#WM_CAP_SET_PREVIEWRATE = #WM_CAP_START + 52
#WM_CAP_STOP = #WM_CAP_START + 68
#WM_CAP_SET_SCALE = #WM_CAP_START + 53
#WM_CAP_DLG_VIDEOSOURCE = #WM_CAP_START + 42

Dim snapshot.l(50)
i=1
If OpenWindow(#Window_0, 100, 100, 408, 338, "Little Camera", #PB_Window_SystemMenu |  #PB_Window_MinimizeGadget     )
  If UseGadgetList(WindowID(#Window_0))
   
    ButtonGadget(#Button_0, 150, 280, 50, 25, "Capture")
    ButtonGadget(#Button_1, 250, 280, 50, 25, "Quit")
    ButtonGadget(#Button_2, 200, 280, 50, 25, "Show")
    EndIf
   
   
   
  EndIf
 
  If OpenLibrary(0, "avicap32.dll")
    *capAddress = GetFunction(0, "capCreateCaptureWindowA")
   
    hWndC.l = CallFunctionFast(*capAddress, @"My Capture Window", #WS_CHILD | #WS_VISIBLE, 50,38, 310, 230, WindowID(0),0)
    
    SendMessage_(hWndC, #WM_CAP_DLG_VIDEOSOURCE, 1, 0)
    SendMessage_(hWndC, #WM_CAP_DRIVER_CONNECT, 0, 0)
    SendMessage_(hWndC, #WM_CAP_SET_PREVIEW, #True, 0)
    SendMessage_(hWndC, #WM_CAP_SET_PREVIEWRATE, 1, 0)
    SendMessage_(hWndC, #WM_CAP_SET_SCALE, #True, 0)
    

   
   
   
  EndIf



Repeat
  Event=WaitWindowEvent(10)
  Select Event
   
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_0
          SendMessage_(hWndC, #WM_CAP_EDIT_COPY, 0, 0)
          snapshot(i) = GetClipboardImage(#PB_Any)
          If snapshot(i)
             
            saver$="snapshot"+Str(i)+".jpg"
            SaveImage(snapshot(i),saver$,#PB_ImagePlugin_JPEG,10)
            FreeImage(snapshot(i))
           
            i=i+1
            If i=51
              i=0
            EndIf
          EndIf
        Case #Button_1
          SendMessage_(hWndC, #WM_CAP_STOP, 0, 0)
          SendMessage_(hWndC, #WM_CAP_DRIVER_DISCONNECT, 0, 0)
          DestroyWindow_(hWndC)
           CloseLibrary(0)
          End
         
        Case #Button_2
         
          If OpenWindow(#viewer1, 10, 10, 340, 270, "ImageGadget", #PB_Window_ScreenCentered|#PB_Window_BorderLess    )
            StickyWindow(#viewer1, 1)
            If UseGadgetList((WindowID(#viewer1)))
             
               
              existimage=  LoadImage(0, saver$)     ;Path/filename of the image
              If existimage
              ImageGadget(#gadget1,  10, 10, 310, 230, ImageID(0),#PB_Image_Border)                      ; imagegadget standard
            Else
              ResizeWindow(#viewer1,#PB_Ignore ,#PB_Ignore ,10,10)
             
              MessageRequester("No Image", "image doesn,t exist",#PB_MessageRequester_Ok)
              CloseWindow(#viewer1)
              quit=1
              EndIf
             
             
            EndIf
            Repeat
              event2=WaitWindowEvent()
              bugger=EventType()
              Select bugger
                Case #PB_EventType_RightClick
                  CloseWindow(#viewer1)
                  quit=1
                 
              EndSelect
            Until quit=1
          EndIf
          quit=0
       
      EndSelect
  EndSelect
 
 
 
Until Event = #PB_Event_CloseWindow

SendMessage_(hWndC, #WM_CAP_STOP, 0, 0)
SendMessage_(hWndC, #WM_CAP_DRIVER_DISCONNECT, 0, 0)
DestroyWindow_(hWndC)
CloseLibrary(0)

End

; IDE Options = PureBasic 5.70 LTS (Windows - x86)
; CursorPosition = 42
; FirstLine = 20
; EnableXP