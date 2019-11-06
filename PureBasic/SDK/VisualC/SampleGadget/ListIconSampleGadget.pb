
Enumeration
  #GADGET_ListIconSample
EndEnumeration

If OpenWindow(0, 0, 0, 640, 480, #PB_Window_ScreenCentered | #PB_Window_SystemMenu, "Hello")
  CreateGadgetList(WindowID(0))
    ListIconSampleGadget(#GADGET_ListIconSample, 0, 0, 200, 250, "Hello", 100, 0)

  AddGadgetItem(#GADGET_ListIconSample, -1, "Hello")
  GetGadgetColor(#GADGET_ListIconSample, 0)

  Repeat
    Event = WaitWindowEvent()
  
  Until Event = #PB_Event_CloseWindow
  
EndIf