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

#ifndef PB_GADGETCOMMON_H
#define PB_GADGETCOMMON_H

/* Gadget constants that are common to all OS
 */
  
#if defined(WINDOWS)
  #include <Gadget/Windows/Gadget.h>

#elif defined(PB_COCOA)
  #include <Gadget/Cocoa/Gadget.h>

#elif defined(QT)
  #include <Gadget/Qt/Gadget.h>
  
#elif defined(LINUX)
  #include <Gadget/Gtk/Gadget.h>

#endif

// -----------------------------------------------------------
// CanvasGadget
// -----------------------------------------------------------

// EventType for this gadget
//
// Note: This gadget also supports the Focus, LostFocus, Left/Right Click and
//   Left/RightDoubleClick EventTypes, so make sure they do not overlap with these
//
#define PB_Canvas_FirstEventType 0x10000

#define PB_EventType_MouseEnter        (PB_Canvas_FirstEventType + 1)
#define PB_EventType_MouseLeave        (PB_Canvas_FirstEventType + 2)
#define PB_EventType_MouseMove         (PB_Canvas_FirstEventType + 3)
#define PB_EventType_LeftButtonDown    (PB_Canvas_FirstEventType + 4)
#define PB_EventType_LeftButtonUp      (PB_Canvas_FirstEventType + 5)
#define PB_EventType_RightButtonDown   (PB_Canvas_FirstEventType + 6)
#define PB_EventType_RightButtonUp     (PB_Canvas_FirstEventType + 7)
#define PB_EventType_MiddleButtonDown  (PB_Canvas_FirstEventType + 8)
#define PB_EventType_MiddleButtonUp    (PB_Canvas_FirstEventType + 9)
#define PB_EventType_MouseWheel        (PB_Canvas_FirstEventType + 10)
#define PB_EventType_KeyDown           (PB_Canvas_FirstEventType + 11)
#define PB_EventType_KeyUp             (PB_Canvas_FirstEventType + 12)
#define PB_EventType_Input             (PB_Canvas_FirstEventType + 13)

// WebGadget events
#define PB_Web_FirstEventType 0x10050

#define PB_EventType_TitleChange      (PB_Web_FirstEventType + 1)
#define PB_EventType_StatusChange     (PB_Web_FirstEventType + 2)
#define PB_EventType_PopupWindow      (PB_Web_FirstEventType + 3)
#define PB_EventType_DownloadStart    (PB_Web_FirstEventType + 4)
#define PB_EventType_DownloadProgress (PB_Web_FirstEventType + 5)
#define PB_EventType_DownloadEnd      (PB_Web_FirstEventType + 6)
#define PB_EventType_PopupMenu        (PB_Web_FirstEventType + 7)



// Flags
//
#define PB_Canvas_Border      (1 << 0)
#define PB_Canvas_ClipMouse   (1 << 1)
#define PB_Canvas_Keyboard    (1 << 2)
#define PB_Canvas_DrawFocus   (1 << 3)
#define PB_Canvas_Transparent (1 << 4) // SpiderBasic only for now
#define PB_Canvas_Container   (1 << 5)

// Get/SetGadgetAttribute
//
#define PB_Canvas_Image        1
#define PB_Canvas_MouseX       2
#define PB_Canvas_MouseY       3
#define PB_Canvas_Buttons      4
#define PB_Canvas_Key          5
#define PB_Canvas_Modifiers    6
#define PB_Canvas_Cursor       7
#define PB_Canvas_WheelDelta   8
#define PB_Canvas_Input        9
#define PB_Canvas_Clip         10
#define PB_Canvas_CustomCursor 11

// for PB_Canvas_Modifiers
//
#define PB_Canvas_Shift        (1 << 0)
#define PB_Canvas_Alt          (1 << 1)
#define PB_Canvas_Control      (1 << 2)
#define PB_Canvas_Command      (1 << 3)

// for PB_Canvas_Buttons
//
#define PB_Canvas_LeftButton    (1 << 0)
#define PB_Canvas_RightButton   (1 << 1)
#define PB_Canvas_MiddleButton  (1 << 2)

// Flags
//
#define PB_OpenGL_Border     (1 << 0)
#define PB_OpenGL_ClipMouse  (1 << 1)
#define PB_OpenGL_Keyboard   (1 << 2)
#define PB_OpenGL_NoFlipSynchronization (1 << 3)
#define PB_OpenGL_FlipSynchronization   (1 << 4)
#define PB_OpenGL_NoDepthBuffer         (1 << 5)
#define PB_OpenGL_16BitDepthBuffer     (1 << 6)
#define PB_OpenGL_24BitDepthBuffer     (1 << 7)
#define PB_OpenGL_NoStencilBuffer       (1 << 8)
#define PB_OpenGL_8BitStencilBuffer    (1 << 9)
#define PB_OpenGL_NoAccumulationBuffer  (1 << 10)
#define PB_OpenGL_32BitAccumulationBuffer (1 << 11)
#define PB_OpenGL_64BitAccumulationBuffer (1 << 12)

// Get/SetGadgetAttribute
//
#define PB_OpenGL_MouseX       PB_Canvas_MouseX
#define PB_OpenGL_MouseY       PB_Canvas_MouseY
#define PB_OpenGL_Buttons      PB_Canvas_Buttons
#define PB_OpenGL_Key          PB_Canvas_Key
#define PB_OpenGL_Modifiers    PB_Canvas_Modifiers
#define PB_OpenGL_Cursor       PB_Canvas_Cursor
#define PB_OpenGL_WheelDelta   PB_Canvas_WheelDelta
#define PB_OpenGL_Input        PB_Canvas_Input
#define PB_OpenGL_Clip         PB_Canvas_Clip
#define PB_OpenGL_CustomCursor PB_Canvas_CustomCursor
#define PB_OpenGL_SwapBuffer   12
#define PB_OpenGL_SetContext   13

// for PB_OpenGL_Modifiers
//
#define PB_OpenGL_Shift        PB_Canvas_Shift
#define PB_OpenGL_Alt          PB_Canvas_Alt
#define PB_OpenGL_Control      PB_Canvas_Control
#define PB_OpenGL_Command      PB_Canvas_Command

// for PB_OpenGL_Buttons
//
#define PB_OpenGL_LeftButton    PB_Canvas_LeftButton
#define PB_OpenGL_RightButton   PB_Canvas_RightButton
#define PB_OpenGL_MiddleButton  PB_Canvas_MiddleButton


// For GadgetX/Y
#define PB_Gadget_ContainerCoordinate 0 // default
#define PB_Gadget_ScreenCoordinate    (1 << 0)
#define PB_Gadget_WindowCoordinate    (1 << 1)

// StringGadget() Attribute
#define PB_String_MaximumLength 1

// For GadgetWidth() and GadgetHeight()
#define PB_Gadget_ActualSize    0
#define PB_Gadget_RequiredSize 1

// ProgressBarGadget
#define PB_ProgressBar_Unknown (-1)

// constants for PB_Canvas_Cursor and PB_OpenGL_Cursor
//
enum
{
  PB_Cursor_Default,   // default arrow cursor
  PB_Cursor_Cross,     // crosshair
  PB_Cursor_IBeam,     // I text cursor
  PB_Cursor_Hand,      // hand cursor
  PB_Cursor_Busy,      // hourglass/watch cursor
  PB_Cursor_Denied,    // slashed circle/ X cursor (not available in Cocoa)
  PB_Cursor_Arrows,    // arrows in all directions (not available in Cocoa)
  PB_Cursor_LeftRight, // <-> arrow
  PB_Cursor_UpDown,    // up/down arrow  
  PB_Cursor_LeftUpDownRight, // diagonal arrows 1
  PB_Cursor_LeftDownUpRight, // diagonal arrows 2
  PB_Cursor_Invisible, // invisible cursor  
  
  PB_Cursor_Last = PB_Cursor_Invisible // just for internal use
};

// Public functions (used by the Dialog library)
M_PBFUNCTION(integer) PB_AddGadgetItem(integer GadgetID, int Position, const TCHAR *Text);
M_PBFUNCTION(integer) PB_AddGadgetItem2(integer GadgetID, int Position, const TCHAR *Text, void *ImageID);
M_PBFUNCTION(integer) PB_AddGadgetItem3(integer GadgetID, int Position, const TCHAR *Text, void *ImageID, int Flags);
M_PBFUNCTION(void)    PB_AddGadgetColumn(integer GadgetID, int Position, const TCHAR *Title, int Width);
M_PBFUNCTION(integer) PB_BindGadgetEvent2(integer GadgetID, void *Callback, integer EventType);
M_PBFUNCTION(integer) PB_BindGadgetEvent(integer GadgetID, void *Callback);
M_PBFUNCTION(void)    PB_CloseGadgetList(void);
M_PBFUNCTION(void)    PB_DisableGadget(integer GadgetID, int State);
M_PBFUNCTION(void *)  PB_GadgetID(integer GadgetID);
M_PBFUNCTION(integer) PB_GadgetHeight2(integer GadgetID, int Mode);
M_PBFUNCTION(integer) PB_GadgetType(integer GadgetID); // debugging
M_PBFUNCTION(integer) PB_GetGadgetAttribute(integer GadgetID, int Attribute);
M_PBFUNCTION(integer) PB_GetGadgetState(integer GadgetID);
M_PBFUNCTION(void)    PB_HideGadget(integer GadgetID, int State);
M_PBFUNCTION(void)    PB_OpenGadgetList2(integer GadgetID, int Item);
M_PBFUNCTION(void)    PB_OpenGadgetList(integer GadgetID);
M_PBFUNCTION(void)    PB_RemoveGadgetColumn(integer GadgetID, int Position);
M_PBFUNCTION(void)    PB_ResizeGadget(integer GadgetID, int x, int y, int Width, int Height);
M_PBFUNCTION(void)    PB_SetGadgetAttribute(integer GadgetID, int Attribute, integer Value);
M_PBFUNCTION(void)    PB_SetGadgetText(integer GadgetID, const TCHAR *Text);
M_PBFUNCTION(void)    PB_SetGadgetState(integer GadgetID, integer State);
M_PBFUNCTION(void)    PB_SetGadgetItemText(integer GadgetID, int Item, const TCHAR *Text);
M_PBFUNCTION(void)    PB_SetGadgetItemText2(integer GadgetID, int Item, const TCHAR *Text, int Column);
M_PBFUNCTION(integer) PB_UnbindGadgetEvent2(integer GadgetID, void *Callback, integer EventType);
M_PBFUNCTION(integer) PB_UnbindGadgetEvent(integer GadgetID, void *Callback);

// All gadgets
M_PBFUNCTION(integer) PB_ButtonGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Flags);
M_PBFUNCTION(integer) PB_ButtonImageGadget2(integer GadgetID, int x, int y, int Width, int Height, void *Image, int Flags);
M_PBFUNCTION(integer) PB_CalendarGadget3(integer GadgetID, int x, int y, int Width, int Height, int Date, int Flags);
M_PBFUNCTION(integer) PB_CanvasGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_CheckBoxGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Flags);
M_PBFUNCTION(integer) PB_ComboBoxGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_ContainerGadget(integer GadgetID, int x, int y, int Width, int Height);
M_PBFUNCTION(integer) PB_ContainerGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_DateGadget4(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Format, int Date, int Flags);
M_PBFUNCTION(integer) PB_EditorGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_ExplorerComboGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Directory, int Flags);
M_PBFUNCTION(integer) PB_ExplorerListGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Directory, int Flags);
M_PBFUNCTION(integer) PB_ExplorerTreeGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Directory, int Flags);
M_PBFUNCTION(integer) PB_FrameGadget(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text);
M_PBFUNCTION(integer) PB_FrameGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Flags);
M_PBFUNCTION(integer) PB_HyperLinkGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Color, int Flags);
M_PBFUNCTION(integer) PB_ImageGadget2(integer GadgetID, int x, int y, int Width, int Height, void *Image, int Flags);
M_PBFUNCTION(integer) PB_IPAddressGadget(integer GadgetID, int x, int y, int Width, int Height);
M_PBFUNCTION(integer) PB_ListIconGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Title, int ColumnWidth, int Flags);
M_PBFUNCTION(integer) PB_ListViewGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_MDIGadget2(integer GadgetID, int x, int y, int Width, int Height, int SubMenu, int FirstMenuItem, int Flags);
M_PBFUNCTION(integer) PB_OptionGadget(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text);
M_PBFUNCTION(integer) PB_PanelGadget(integer GadgetID, int x, int y, int Width, int Height);
M_PBFUNCTION(integer) PB_ProgressBarGadget2(integer GadgetID, int x, int y, int Width, int Height, int Min, int Max, int Flags);
M_PBFUNCTION(integer) PB_ScintillaGadget(integer GadgetID, int x, int y, int Width, int Height, void *Callback);
M_PBFUNCTION(integer) PB_ScrollAreaGadget3(integer GadgetID, int x, int y, int Width, int Height, int ScrollAreaWidth, int ScrollAreaHeight, int ScrollStep, int Flags);
M_PBFUNCTION(integer) PB_ScrollBarGadget2(integer GadgetID, int x, int y, int Width, int Height, int Min, int Max, int Page, int Flags);
M_PBFUNCTION(integer) PB_ShortcutGadget(integer GadgetID, int x, int y, int Width, int Height, int Shortcut);
M_PBFUNCTION(integer) PB_SpinGadget2(integer GadgetID, int x, int y, int Width, int Height, int Min, int Max, int Flags);
M_PBFUNCTION(integer) PB_SplitterGadget2(integer GadgetID, int x, int y, int Width, int Height, integer GadgetID1, integer GadgetID2, int Flags);
M_PBFUNCTION(integer) PB_StringGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Flags);
M_PBFUNCTION(integer) PB_TextGadget(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text);
M_PBFUNCTION(integer) PB_TextGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Text, int Flags);
M_PBFUNCTION(integer) PB_TrackBarGadget2(integer GadgetID, int x, int y, int Width, int Height, int Min, int Max, int Flags);
M_PBFUNCTION(integer) PB_TreeGadget2(integer GadgetID, int x, int y, int Width, int Height, int Flags);
M_PBFUNCTION(integer) PB_WebGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *URL, int Flags);


M_PBFUNCTION(void) PB_Gadget_GetRequiredSize(PB_Gadget *Gadget, int *Width, int *Height);

#endif
