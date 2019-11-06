/* === Copyright Notice ===
 *
 *
 *                  PureBasic source code file
 *
 *
 * This file is part of the PureBasic Software package. It may not
 * be distributed or published in source code or binary form without
 * the expressed permission by Fantaisie Software.
 *
 * By contributing modifications or additions to this file, you grant
 * Fantaisie Software the rights to use, modify and distribute your
 * work in the PureBasic package.
 *
 *
 * Copyright (C) 2000-2010 Fantaisie Software - all rights reserved
 *
 */

#ifndef PB_EVENT_H
#define PB_EVENT_H

typedef void (*EventDataFreeFunction)(void *Data);

// Gtk is UTF8 based, so we don't need 16bits strings routines at all
#define NO_UNICODE_ALIASES


#define PB_Event_Init M_UnicodeFunction(PB_Event_Init)
#define PB_Event_Free M_UnicodeFunction(PB_Event_Free)
#define PB_PostEvent  M_UnicodeFunction(PB_PostEvent)
#define PB_PostEvent2 M_UnicodeFunction(PB_PostEvent2)
#define PB_PostEvent3 M_UnicodeFunction(PB_PostEvent3)
#define PB_PostEvent4 M_UnicodeFunction(PB_PostEvent4)

#define PB_USE_CFSTRING
#include <PureLibrary.h>
#include <Object/Object.h>
#include <Map/Map.h>

#if defined(PB_COCOA)
  #include <Cocoa/CocoaHeader.h>
  extern NSImage *PB_Event_DragImage;

#elif defined(LINUX) && !defined(PB_MACOS) && !defined(QT)
  #include <GtkBase/GtkBase.h>
  
#endif


#if defined(WINDOWS)

  #define GET_X_LPARAM(lp)	((int)(short)LOWORD(lp))
  #define GET_Y_LPARAM(lp)	((int)(short)HIWORD(lp))
  
  // Note: On Windows, every thread that creates a window must have a separate event loop,
  //   so we also have to keep thread-specific event queues to keep events separate.
  //   This is different on the other OS, as there we can have only one main event loop, so
  //   separation is not needed. The Window lib on Windows is already threadsafe otherwise.
  //
  //   Thread separation is done if this macro is defined (through the Object lib, so no 
  //   separate _THREAD versions needed)
  //
  // As some user uses threaded window, we keep it enabled
  //
  #define PB_EVENT_THREADEDQUEUES

  // Internal events
  #define PB_Event_SystrayInternal 12501

  // Public events
  #define PB_Event_Gadget         13100
  #define PB_Event_Menu           13101
  #define PB_Event_Systray        13102
  #define PB_Event_ActivateWindow 13104
  #define PB_Event_WindowDrop     13105
  #define PB_Event_GadgetDrop     13106
  //#define MSG_DirrectoryChange 13120 // for ExplorerListGadget
  #define PB_Event_MinimizeWindow  13107
  #define PB_Event_MaximizeWindow  13108
  #define PB_Event_RestoreWindow   13109
  #define PB_Event_Timer           13110 // do not just reuse WM_TIMER as event, as the WebGadget fires that too for example!
  #define PB_Event_RightClick      13111
  #define PB_Event_LeftClick       13112
  #define PB_Event_LeftDoubleClick 13113
  #define PB_Event_DeactivateWindow 13114
  #define PB_Event_Repaint        13115
  #define PB_Event_CloseWindow    13116
  #define PB_Event_MoveWindow     13117
  #define PB_Event_SizeWindow     13118

  // Special object ID to identify a toolbar event
  #define PB_Event_ToolBarObjectID -10000
  
  #define PB_Event_TimeOut         0 // stay with 0, or it can cause hard to find bug while migrating code
  
  extern UINT  PB_Event_PostEventID;  // For PostEvent()
  extern HWND  PB_Event_PostEventWindow; // For PostEvent()

#else

  #define PB_Event_Menu              1
  #define PB_Event_CloseWindow       2
  #define PB_Event_Gadget            3
  #define PB_Event_MoveWindow        5
  #define PB_Event_Repaint           4
  #define PB_Event_SizeWindow        6
  #define PB_Event_ActivateWindow    7
  #define PB_Event_DeactivateWindow  8
  #define PB_Event_SysTray           9
  #define PB_Event_WindowDrop       10
  #define PB_Event_GadgetDrop       11
  #define PB_Event_MinimizeWindow   12
  #define PB_Event_MaximizeWindow   13
  #define PB_Event_RestoreWindow    14
  #define PB_Event_Timer            15
  #define PB_Event_RightClick       16
  #define PB_Event_LeftClick        17
  #define PB_Event_LeftDoubleClick  18
  #define PB_Event_TimeOut          0 // stay with 0, or it can cause hard to find bug while migrating code

  
  #define PB_Event_MouseButtonDown        20
  #define PB_Event_MouseButtonUp          21
  #define PB_Event_MouseButtonDoubleClick 22
  #define PB_Event_MouseButtonTripleClick 23
  #define PB_Event_MouseMove              24
  
  /* Event type
   */
  #define PB_EventType_Change           0x300
  #define PB_EventType_Focus            0x100
  #define PB_EventType_LeftClick        0
  #define PB_EventType_LeftDoubleClick  2
  #define PB_EventType_LostFocus        0x200
  #define PB_EventType_ReturnKey        0x501
  #define PB_EventType_RightClick       1
  #define PB_EventType_RightDoubleClick 3
  #define PB_EventType_DragStart        0x800
  #define PB_EventType_Resize           6
    
  #define PB_EventType_SizeItem  0xFFFE
  #define PB_EventType_CloseItem 0xFFFF
#endif

#define PB_Event_User (1 << 16)

// event flags
#define PB_EventFlag_Force            (1 << 0)  // Add the event, even if it is a duplicate
#define PB_EventFlag_DelayBindedCalls (1 << 1)  // Call binded callbacks only in the main thread (when PB_Event_Get() is called)
#define PB_EventFlag_PostEvent        (1 << 2)  // Add the event for a threaded PostEvent()


typedef struct PB_EventStruct
{
  struct PB_EventStruct *Next; // we only need a single link here
  
	int ID;
  int Flags;  
  integer ObjectID;
  integer WindowID;
  integer Type;
  
  void *Data;
  EventDataFreeFunction FreeData;      
} PB_EventStruct;


#ifdef PB_EVENT_THREADEDQUEUES

  // access goes through the Object lib  
  //
  typedef struct
  {
    PB_BlockAlloc  *Allocator;
    PB_EventStruct *Head;
    PB_EventStruct *Tail;
    int            LockCount;
    int            EventID;
    integer        EventWindow;
    integer        EventObject;
    integer        EventType;
    void *         EventData;
    EventDataFreeFunction FreeEventData;
    
  } PB_EventGlobals;  
  
  extern integer PB_Event_Globals;
  #define PB_Event_GetGlobals() PB_EventGlobals *Globals = (PB_EventGlobals *)PB_Object_GetThreadMemory(PB_Event_Globals)
  
  extern PB_EventGlobals *PB_Event_MainThreadGlobals; // needed for PostEvent()
  
  #define PB_Event_LockCount  (Globals->LockCount)
  #define PB_Event_Allocator  (Globals->Allocator)
  #define PB_Event_Head       (Globals->Head)
  #define PB_Event_Tail       (Globals->Tail)

  #define PB_Event_EventID       (Globals->EventID)
  #define PB_Event_EventWindow   (Globals->EventWindow)
  #define PB_Event_EventObject   (Globals->EventObject)
  #define PB_Event_EventType     (Globals->EventType)
  #define PB_Event_EventData     (Globals->EventData)
  #define PB_Event_FreeEventData (Globals->FreeEventData)

#else

  // no need for the object lib here
  #define PB_Event_GetGlobals()
  
  extern int             PB_Event_LockCount;
  extern PB_BlockAlloc  *PB_Event_Allocator;
  extern PB_EventStruct *PB_Event_Head; // read here
  extern PB_EventStruct *PB_Event_Tail; // add here
  
  extern int     PB_Event_EventID;
  extern integer PB_Event_EventWindow;
  extern integer PB_Event_EventObject;
  extern integer PB_Event_EventType;
  extern void *  PB_Event_EventData;
  extern EventDataFreeFunction PB_Event_FreeEventData;
  
#endif

//#define PB_Event_Add   M_ThreadFunction(PB_Event_Add)
//#define PB_Event_Get   M_ThreadFunction(PB_Event_Get)
//#define PB_Event_Init  M_ThreadFunction(PB_Event_Init)

// When using PB_Event_AddWithData, the caller of PB_Event_Get must ensure that
// the FreeData function is called when it received a non-zero free function pointer
  
M_PBFUNCTION(void) PB_Event_Add(int ID, integer ObjectID, integer WindowID, integer Type);
M_PBFUNCTION(void) PB_Event_AddWithData(int ID, integer ObjectID, integer WindowID, integer Type, void *Data, EventDataFreeFunction FreeData);
M_PBFUNCTION(void) PB_Event_AddWithFlags(int EventID, integer ObjectID, integer WindowID, integer EventType, void *Data, EventDataFreeFunction FreeData, int Flags);
M_PBFUNCTION(int)  PB_Event_Get();
M_PBFUNCTION(int)  PB_Event_PeekID();
M_PBFUNCTION(int)  PB_Event_Peek(integer *ObjectID, integer *WindowID, integer *Type);
M_PBFUNCTION(void) PB_Event_Lock();
M_PBFUNCTION(void) PB_Event_Unlock();
M_PBFUNCTION(void) PB_Event_ClearAll(integer WindowID);
M_PBFUNCTION(void) PB_Event_UnbindAll(integer WindowID);
M_PBFUNCTION(void) PB_Event_Clear(int ID, integer ObjectID, integer WindowID, integer Type);


M_PBFUNCTION(integer) PB_BindEvent(int EventID, void *Callback);
M_PBFUNCTION(integer) PB_BindEvent2(int EventID, void *Callback, integer WindowID);
M_PBFUNCTION(integer) PB_BindEvent3(int EventID, void *Callback, integer WindowID, integer ObjectID);
M_PBFUNCTION(integer) PB_BindEvent4(int EventID, void *Callback, integer WindowID, integer ObjectID, integer EventType);
M_PBFUNCTION(integer) PB_UnbindEvent(int EventID, void *Callback);
M_PBFUNCTION(integer) PB_UnbindEvent2(int EventID, void *Callback, integer WindowID);
M_PBFUNCTION(integer) PB_UnbindEvent3(int EventID, void *Callback, integer WindowID, integer ObjectID);
M_PBFUNCTION(integer) PB_UnbindEvent4(int EventID, void *Callback, integer WindowID, integer ObjectID, integer EventType);
M_PBFUNCTION(integer) PB_Event(void);
M_PBFUNCTION(integer) PB_EventGadget(void);
M_PBFUNCTION(integer) PB_EventWindow(void);
M_PBFUNCTION(integer) PB_EventType(void);
M_PBFUNCTION(void *)  PB_EventData(void);

extern PB_Map *BindedEvents;
extern M_MUTEX PB_Event_Mutex;


typedef void (*BindedEventCallbackType)();

typedef struct PB_BindedCallback
{
  struct PB_BindedCallback *Next;
  BindedEventCallbackType Callback;
} PB_BindedCallback;

typedef struct PB_BindedEvent
{
  PB_BindedCallback *Callbacks;
  integer WindowID;
} PB_BindedEvent;

// We can't use M_INTEGER here, as we need to use the macro TEXT() as well
//
#ifdef X64
  #ifdef WINDOWS
    #define PB_Event_MaskKey L"%d:%I64d:%I64d:%I64d"
  #else
    #define PB_Event_MaskKey L"%d:%lld:%lld:%lld"
  #endif
  
  #define MAX_EVENT_KEY_SIZE 128
#else
  #define MAX_EVENT_KEY_SIZE 64
  #define PB_Event_MaskKey L"%d:%d:%d:%d"
#endif

#define PB_Event_MakeBindKey(Output, Event, WindowID, ObjectID, EventType) swprintf(Output, PB_Event_MaskKey, Event, WindowID, ObjectID, EventType)

#endif
