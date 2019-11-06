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

#ifndef PB_GADGET_H
#define PB_GADGET_H

#undef _WIN32_IE
#define _WIN32_IE  0x0500

#undef WINVER                // Allow use of features specific to Windows 95 and Windows NT 4 or later.
#define WINVER 0x0501        // Change this to the appropriate value to target Windows 98 and Windows 2000 or later.

#undef _WIN32_WINNT        // Allow use of features specific to Windows NT 4 or later.
#define _WIN32_WINNT 0x0501        // Change this to the appropriate value to target Windows 98 and Windows 2000 or later.

#undef _WIN32_WINDOWS        // Allow use of features specific to Windows 98 or later.
#define _WIN32_WINDOWS 0x0501 // Change this to the appropriate value to target Windows Me or later.


#define COBJMACROS
#define CINTERFACE

#ifdef VISUALC
	#pragma warning (disable: 4028)
#endif


#include <PureLibrary.h>
#include <Object/Object.h>
#include <Event/Event.h>
#include <CommCtrl.h>
#include <Window/Windows/Window.h>

// Not declared in windows.h
#ifndef TVM_SETEXTENDEDSTYLE
  #define TVM_SETEXTENDEDSTYLE (TV_FIRST + 44)
#endif

#ifndef TVS_EX_DOUBLEBUFFER
  #define TVS_EX_DOUBLEBUFFER 0x0004
#endif


#define MSG_DirectoryChange 13120 // to check


#ifndef PB_EventNotProcessed
  #define PB_EventNotProcessed      (-0x2F2F2F2F)
#endif

// EventType
#define PB_EventType_Focus              14000
#define PB_EventType_LostFocus          14001
#define PB_EventType_ReturnKey          1281
#define PB_EventType_Change             768
#define PB_EventType_LeftClick          0
#define PB_EventType_RightClick         1
#define PB_EventType_LeftDoubleClick    2
#define PB_EventType_RightDoubleClick   3
#define PB_EventType_DragStart          14002
#define PB_EventType_Up                4 // Used by SpinGadget()
#define PB_EventType_Down              5 // Used by SpinGadget()
#define PB_EventType_Resize             6



/* Gadget Coloring options:
 */
#define PB_Gadget_FrontColor      1
#define PB_Gadget_BackColor       2
#define PB_Gadget_LineColor       3
#define PB_Gadget_TitleFrontColor 4
#define PB_Gadget_TitleBackColor  5
#define PB_Gadget_GreyTextColor   6

/* Gadget flags 
 */

// Button
#define PB_Button_Right     512
#define PB_Button_Left      256
#define PB_Button_Default   1
#define PB_Button_MultiLine 0x2000
#define PB_Button_Toggle    (3 | 4096) // (#BS_DEFPUSHBUTTON | #BS_CHECKBOX | #BS_PUSHLIKE)

// Calendar
#define PB_Calendar_Borderless (0x800000) // ; WS_BORDER

// Checkbox
#define PB_CheckBox_Right      512
#define PB_CheckBox_Center     0x300
#define PB_CheckBox_ThreeState 5    // #BS_3STATE

// Combobox
#define PB_ComboBox_Editable  (2 | 64)     //  #CBS_DROPDOWN | #CBS_AUTOHSCROLL
#define PB_ComboBox_LowerCase (0x4000)     // #CBS_LOWERCASE
#define PB_ComboBox_UpperCase (0x2000)     // #CBS_UPPERCASE 
#define PB_ComboBox_Image     (0x10000000) // #WS_VISIBLE (reused for this flag)

// ContainerGadget()
#define PB_Container_BorderLess 0
#define PB_Container_Flat       1
#define PB_Container_Raised     2
#define PB_Container_Single     4
#define PB_Container_Double     8

// Date
#define PB_Date_UpDown   0x1 // DTS_UPDOWN 
#define PB_Date_CheckBox 0x2 // DTS_SHOWNONE

// Editor
#define PB_Editor_ReadOnly 0x800      // ES_READONLY
#define PB_Editor_WordWrap 0x10000000 // WS_VISIBLE

// ExplorerCombo
#define PB_Explorer_DrivesOnly    0x00000080
#define PB_Explorer_Editable      0x00000100
#define PB_Explorer_NoMyDocuments 0x00000200

// ExplorerList
#define PB_Explorer_NoFiles             0x00000001
#define PB_Explorer_NoParentFolder      0x00000002
#define PB_Explorer_NoFolders           0x00000004
#define PB_Explorer_NoDirectoryChange   0x00000008
#define PB_Explorer_NoDriveRequester    0x00000010
#define PB_Explorer_NoSort              0x00000020
#define PB_Explorer_AutoSort            0x00000040
#define PB_Explorer_NoMyDocuments       0x00000200

#define PB_Explorer_BorderLess          0x00100000
#define PB_Explorer_MultiSelect         0x00200000
#define PB_Explorer_GridLines           0x00400000
#define PB_Explorer_HeaderDragDrop      0x00800000
#define PB_Explorer_AlwaysShowSelection 0x01000000
#define PB_Explorer_FullRowSelect       0x02000000

// ExplorerTree
#define PB_Explorer_NoFiles             0x00000001
#define PB_Explorer_NoDriveRequester    0x00000010
#define PB_Explorer_AutoSort            0x00000040
#define PB_Explorer_NoMyDocuments       0x00000200

#define PB_Explorer_BorderLess          0x00100000
#define PB_Explorer_AlwaysShowSelection 0x01000000
#define PB_Explorer_NoLines             0x04000000
#define PB_Explorer_NoButtons           0x08000000

// Frame
#define PB_Frame_Double 1
#define PB_Frame_Single 2
#define PB_Frame_Flat   3

// HyperLink
#define PB_HyperLink_Underline 1

// Image
#define PB_Image_Border 0x200 
#define PB_Image_Raised 1

// ListView
#define PB_ListView_MultiSelect 0x800 // #LBS_EXTENDEDSEL
#define PB_ListView_ClickSelect 0x8   // #LBS_MULTIPLESEL

// ListIcon
#define PB_ListIcon_CheckBoxes     1
#define PB_ListIcon_MultiSelect    4
#define PB_ListIcon_GridLines      0x10000
#define PB_ListIcon_FullRowSelect  0x40000000
#define PB_ListIcon_HeaderDragDrop 0x10000000
#define PB_ListIcon_AlwaysShowSelection 8
#define PB_ListIcon_ThreeState     64 // LVS_SHAREIMAGELISTS (re-used for this setting)

// MDI
#define PB_MDI_BorderLess               0x00000001
#define PB_MDI_AutoSize                 0x00000002
#define PB_MDI_NoScrollBars             0x00000004

// Panel
#define PB_Panel_ItemWidth  1 // Attributes
#define PB_Panel_ItemHeight 2
#define PB_Panel_TabHeight  3

// ProgressBar
#define PB_ProgressBar_Smooth   1
#define PB_ProgressBar_Vertical 4

// ScrollArea
#define PB_ScrollArea_Flat       1
#define PB_ScrollArea_Raised     2
#define PB_ScrollArea_Single     4
#define PB_ScrollArea_BorderLess 8
#define PB_ScrollArea_Center     16

#define PB_ScrollArea_InnerWidth  1 // Attributes
#define PB_ScrollArea_InnerHeight 2
#define PB_ScrollArea_X           3
#define PB_ScrollArea_Y           4
#define PB_ScrollArea_ScrollStep  5

// ScrollBar
#define PB_ScrollBar_Vertical 1

// Splitter
#define PB_Splitter_Vertical  1
#define PB_Splitter_Separator 2
#define PB_Splitter_FirstFixed  4
#define PB_Splitter_SecondFixed 8

#define PB_Splitter_FirstMinimumSize  1 // Attributes
#define PB_Splitter_SecondMinimumSize 2
#define PB_Splitter_FirstGadget       3
#define PB_Splitter_SecondGadget      4

// String
#define PB_String_Password  32         // ES_PASSWORD
#define PB_String_ReadOnly  0x800
#define PB_String_Numeric   0x2000
#define PB_String_LowerCase 16
#define PB_String_UpperCase 8
#define PB_String_BorderLess 0x20000      // reuse WS_GROUP
#define PB_String_AutoComplete 0x10000000 // reuse WS_VISIBLE
#define PB_String_AutoInsert 0x40000000 // reuse WS_CHILD

// Spin
#define PB_Spin_ReadOnly  1
#define PB_Spin_Numeric   2

// Text
#define PB_Text_Border WS_GROUP
#define PB_Text_Center 1
#define PB_Text_Right  2

// TrackBar
#define PB_TrackBar_Ticks    1
#define PB_TrackBar_Vertical 2

// Tree
#define PB_Tree_AlwaysShowSelection 32
#define PB_Tree_NoLines     2
#define PB_Tree_NoButtons   1
#define PB_Tree_CheckBoxes  0x100
#define PB_Tree_ThreeState  0x10000 //  WS_TABSTOP reused


struct PB_GadgetStructure;

typedef integer (M_PBVIRTUAL *GadgetCallbackProc)     (struct PB_GadgetStructure *Gadget, HWND Window, UINT Message, WPARAM wParam, LPARAM lParam);
typedef void    (M_PBVIRTUAL *FreeGadgetProc)         (struct PB_GadgetStructure *Gadget);
typedef integer (M_PBVIRTUAL *GetGadgetStateProc)     (struct PB_GadgetStructure *Gadget);
typedef void    (M_PBVIRTUAL *SetGadgetStateProc)     (struct PB_GadgetStructure *Gadget, integer State);
typedef void    (M_PBVIRTUAL *GetGadgetTextProc)      (struct PB_GadgetStructure *Gadget, int PreviousStringPosition);
typedef void    (M_PBVIRTUAL *SetGadgetTextProc)      (struct PB_GadgetStructure *Gadget, const TCHAR *Text);
typedef integer (M_PBVIRTUAL *AddGadgetItem2Proc)     (struct PB_GadgetStructure *Gadget, int Position, const TCHAR *Text, int *Image);
typedef integer (M_PBVIRTUAL *AddGadgetItem3Proc)     (struct PB_GadgetStructure *Gadget, int Position, const TCHAR *Text, int *Image, int Flags);
typedef void    (M_PBVIRTUAL *RemoveGadgetItemProc)   (struct PB_GadgetStructure *Gadget, int Item);
typedef void    (M_PBVIRTUAL *ClearGadgetItemsProc)   (struct PB_GadgetStructure *Gadget);
typedef void    (M_PBVIRTUAL *ResizeGadgetProc)       (struct PB_GadgetStructure *Gadget, int X, int Y, int Width, int Height);
typedef int     (M_PBVIRTUAL *CountGadgetItemsProc)   (struct PB_GadgetStructure *Gadget);
typedef int     (M_PBVIRTUAL *GetGadgetItemStateProc) (struct PB_GadgetStructure *Gadget, int Item);
typedef void    (M_PBVIRTUAL *SetGadgetItemStateProc) (struct PB_GadgetStructure *Gadget, int Item, int State);
typedef void    (M_PBVIRTUAL *GetGadgetItemTextProc)  (struct PB_GadgetStructure *Gadget, int Item, int Column, int PreviousStringPosition);
typedef void    (M_PBVIRTUAL *SetGadgetItemTextProc)  (struct PB_GadgetStructure *Gadget, int Item, const TCHAR *Text, int Column);
typedef void    (M_PBVIRTUAL *OpenGadgetList2Proc)    (struct PB_GadgetStructure *Gadget, int Item);
typedef int     (M_PBVIRTUAL *GadgetXProc)            (struct PB_GadgetStructure *Gadget);
typedef int     (M_PBVIRTUAL *GadgetYProc)            (struct PB_GadgetStructure *Gadget);
typedef int     (M_PBVIRTUAL *GadgetWidthProc)        (struct PB_GadgetStructure *Gadget);
typedef int     (M_PBVIRTUAL *GadgetHeightProc)       (struct PB_GadgetStructure *Gadget);
typedef void    (M_PBVIRTUAL *HideGadgetProc)         (struct PB_GadgetStructure *Gadget, int State);
typedef void    (M_PBVIRTUAL *AddGadgetColumnProc)    (struct PB_GadgetStructure *Gadget, int Position, const TCHAR *Text, int Width);
typedef void    (M_PBVIRTUAL *RemoveGadgetColumnProc) (struct PB_GadgetStructure *Gadget, int Position);
typedef integer (M_PBVIRTUAL *GetGadgetAttributeProc) (struct PB_GadgetStructure *Gadget, int Attribute);
typedef void    (M_PBVIRTUAL *SetGadgetAttributeProc) (struct PB_GadgetStructure *Gadget, int Attribute, integer Value);
typedef int     (M_PBVIRTUAL *GetGadgetItemAttribute2Proc) (struct PB_GadgetStructure *Gadget, int Item, int Attribute, int Column);
typedef void    (M_PBVIRTUAL *SetGadgetItemAttribute2Proc) (struct PB_GadgetStructure *Gadget, int Item, int Attribute, int Value, int Column);
typedef void    (M_PBVIRTUAL *SetGadgetColorProc)     (struct PB_GadgetStructure *Gadget, int ColorType, int Color);
typedef integer (M_PBVIRTUAL *GetGadgetColorProc)     (struct PB_GadgetStructure *Gadget, int ColorType);
typedef void    (M_PBVIRTUAL *SetGadgetItemColor2Proc)(struct PB_GadgetStructure *Gadget, int Item, int ColorType, int Color, int Column);
typedef int     (M_PBVIRTUAL *GetGadgetItemColor2Proc)(struct PB_GadgetStructure *Gadget, int Item, int ColorType, int Column);
typedef void    (M_PBVIRTUAL *SetGadgetItemDataProc)  (struct PB_GadgetStructure *Gadget, int Item, integer Value);
typedef integer (M_PBVIRTUAL *GetGadgetItemDataProc)  (struct PB_GadgetStructure *Gadget, int Item);
typedef void    (M_PBVIRTUAL *GetRequiredSizeProc)   (struct PB_GadgetStructure *Gadget, int *Width, int *Height);
typedef void    (M_PBVIRTUAL *SetActiveGadgetProc)    (struct PB_GadgetStructure *Gadget);
typedef HFONT   (M_PBVIRTUAL *GetGadgetFontProc)      (struct PB_GadgetStructure *Gadget);
typedef void    (M_PBVIRTUAL *SetGadgetFontProc)      (struct PB_GadgetStructure *Gadget, HFONT Font);
typedef void    (M_PBVIRTUAL *SetGadgetItemImageProc) (struct PB_GadgetStructure *Gadget, int Position, HBITMAP Image);


enum {  // gadget types
  PB_GadgetType_Unknown = 0,

  PB_GadgetType_Button,
  PB_GadgetType_String,
  PB_GadgetType_Text,
  PB_GadgetType_CheckBox,
  PB_GadgetType_Option,
  PB_GadgetType_ListView,
  PB_GadgetType_Frame,
  PB_GadgetType_ComboBox,
  PB_GadgetType_Image,
  PB_GadgetType_HyperLink,
  PB_GadgetType_Container,
  PB_GadgetType_ListIcon,
  PB_GadgetType_IPAddress,
  PB_GadgetType_ProgressBar,
  PB_GadgetType_ScrollBar,
  PB_GadgetType_ScrollArea,
  PB_GadgetType_TrackBar,
  PB_GadgetType_Web,
  PB_GadgetType_ButtonImage,
  PB_GadgetType_Calendar,
  PB_GadgetType_Date,
  PB_GadgetType_Editor,
  PB_GadgetType_ExplorerList,
  PB_GadgetType_ExplorerTree,
  PB_GadgetType_ExplorerCombo,
  PB_GadgetType_Spin,
  PB_GadgetType_Tree,
  PB_GadgetType_Panel,
  PB_GadgetType_Splitter,
  PB_GadgetType_MDI,
	PB_GadgetType_Scintilla,
	PB_GadgetType_Shortcut,
	PB_GadgetType_Canvas,
	PB_GadgetType_OpenGL,

	PB_GadgetType_LastEnum // to easily know the size of the enumeration
};

typedef struct
{
  int                          GadgetType;    // Gadget Type for this VT
  int                          SizeOf;        // SizeOf the VT (for future compatibility

  GadgetCallbackProc           GadgetCallback;
  FreeGadgetProc               FreeGadget;
  GetGadgetStateProc           GetGadgetState;
  SetGadgetStateProc           SetGadgetState;
  GetGadgetTextProc            GetGadgetText;
  SetGadgetTextProc            SetGadgetText;
  AddGadgetItem2Proc           AddGadgetItem2;
  AddGadgetItem3Proc           AddGadgetItem3;
  RemoveGadgetItemProc         RemoveGadgetItem;
  ClearGadgetItemsProc         ClearGadgetItems;
  ResizeGadgetProc             ResizeGadget;
  CountGadgetItemsProc         CountGadgetItems;
  GetGadgetItemStateProc       GetGadgetItemState;
  SetGadgetItemStateProc       SetGadgetItemState;
  GetGadgetItemTextProc        GetGadgetItemText;
  SetGadgetItemTextProc        SetGadgetItemText;
  OpenGadgetList2Proc          OpenGadgetList2;
  GadgetXProc                  GadgetX;
  GadgetYProc                  GadgetY;
  GadgetWidthProc              GadgetWidth;
  GadgetHeightProc             GadgetHeight;
  HideGadgetProc               HideGadget;
  AddGadgetColumnProc          AddGadgetColumn;
  RemoveGadgetColumnProc       RemoveGadgetColumn;
  GetGadgetAttributeProc       GetGadgetAttribute;
  SetGadgetAttributeProc       SetGadgetAttribute;
  GetGadgetItemAttribute2Proc  GetGadgetItemAttribute2;
  SetGadgetItemAttribute2Proc  SetGadgetItemAttribute2;
  SetGadgetColorProc           SetGadgetColor;
  GetGadgetColorProc           GetGadgetColor;
  SetGadgetItemColor2Proc      SetGadgetItemColor2;
  GetGadgetItemColor2Proc      GetGadgetItemColor2;
  SetGadgetItemDataProc        SetGadgetItemData;
  GetGadgetItemDataProc        GetGadgetItemData;
  GetRequiredSizeProc         GetRequiredSize;
  SetActiveGadgetProc          SetActiveGadget;
  GetGadgetFontProc            GetGadgetFont;
  SetGadgetFontProc            SetGadgetFont;
  SetGadgetItemImageProc       SetGadgetItemImage;
} PB_GadgetVT;

typedef struct PB_GadgetStructure
{
  HWND         Gadget;
  PB_GadgetVT *VT;
  integer      UserData;      // for Get/SetGadgetData
  WNDPROC      OldCallback;   // for PB_Gadget_RegisterDestroy
  integer      Data[4];       // for gadget internal data. (mostly used for front/backcolor and such).
} PB_Gadget;

typedef struct
{
  HWND         CurrentWindow;
  int          FirstOptionGadget;

  HFONT        DefaultFont;

  HWND        *PanelStack;
  int          PanelStackIndex;
  int          PanelStackSize;

  HWND         ToolTipWindow;      // one tooltip window per thread

  // This is for CalendarGadget only. We need this as a global structure for the message processing,
  // but it must still be threadsave.
  //
  MONTHDAYSTATE TargetMonthArray[12];

  // This one if for the XP theme fix of the PanelGadget
  // Again, we need to return a global Brush value once per thread, so store it here
  HBRUSH       PanelBrush;

} PB_GadgetGlobals;

typedef struct
{
  HBITMAP Image;
  int     Index;
  int     ReferenceCount;
} PB_GadgetImageList_Entry;

typedef struct
{
  HIMAGELIST  SmallImageList;
  HIMAGELIST  LargeImageList;
  PB_GadgetImageList_Entry *ImageTable;
  int         ImageCount;
  int         TableSize;
} PB_GadgetImageList;


extern PB_Object *PB_Gadget_Objects;
extern integer    PB_Gadget_Globals;
extern HFONT      PB_Gadget_SystemFont;
extern int        PB_Gadget_CommonControlsVersion;
extern int        PB_Gadget_IsThemed;
extern HMODULE    PB_Gadget_UXThemeDLL;

#define PB_GetGadgetFont                   M_UnicodeFunction(PB_GetGadgetFont)
#define PB_SetGadgetFont                   M_UnicodeFunction(PB_SetGadgetFont)
#define PB_GadgetX                         M_UnicodeFunction(PB_GadgetX)
#define PB_GadgetX2                        M_UnicodeFunction(PB_GadgetX2)
#define PB_GadgetY                         M_UnicodeFunction(PB_GadgetY)
#define PB_GadgetY2                        M_UnicodeFunction(PB_GadgetY2)
#define PB_BindGadgetEvent                 M_UnicodeFunction(PB_BindGadgetEvent)
#define PB_BindGadgetEvent2                M_UnicodeFunction(PB_BindGadgetEvent2)
#define PB_UnbindGadgetEvent               M_UnicodeFunction(PB_UnbindGadgetEvent)
#define PB_UnbindGadgetEvent2              M_UnicodeFunction(PB_UnbindGadgetEvent2)
#define PB_GetActiveGadget                 M_UnicodeFunction(PB_GetActiveGadget)
#define PB_UseGadgetList                   M_UnicodeFunction(PB_UseGadgetList)
#define PB_ShortcutGadget                  M_UnicodeFunction(PB_ShortcutGadget)
#define PB_ResizeGadget                    M_UnicodeFunction(PB_ResizeGadget)

#define PB_Gadget_RegisterGadget           M_UnicodeFunction(PB_Gadget_RegisterGadget)
#define PB_Gadget_GetRootWindow            M_UnicodeFunction(PB_Gadget_GetRootWindow)
#define PB_Gadget_GetCommonControlsVersion M_UnicodeFunction(PB_Gadget_GetCommonControlsVersion)
#define PB_Gadget_FreeImageList						 M_UnicodeFunction(PB_Gadget_FreeImageList)
#define PB_Gadget_InitImageList						 M_UnicodeFunction(PB_Gadget_InitImageList)
#define PB_Gadget_AddImageList						 M_UnicodeFunction(PB_Gadget_AddImageList)
#define PB_Gadget_RemoveImageList					 M_UnicodeFunction(PB_Gadget_RemoveImageList)
#define PB_Gadget_ClearImageList					 M_UnicodeFunction(PB_Gadget_ClearImageList)
#define PB_Gadget_FlushEvents							 M_UnicodeFunction(PB_Gadget_FlushEvents)
#define PB_Gadget_SendGadgetCommand        M_UnicodeFunction(PB_Gadget_SendGadgetCommand)
#define PB_Gadget_SendForcedGadgetCommand  M_UnicodeFunction(PB_Gadget_SendForcedGadgetCommand)
#define PB_Gadget_EnsureGadget        		 M_UnicodeFunction(PB_Gadget_EnsureGadget)
#define PB_Gadget_GenericResizeGadget      M_UnicodeFunction(PB_Gadget_GenericResizeGadget)
#define PB_Gadget_DrawListIconGrid         M_UnicodeFunction(PB_Gadget_DrawListIconGrid)
#define PB_Gadget_CreateWeb                M_UnicodeFunction(PB_Gadget_CreateWeb)
#define PB_Gadget_FreeWeb                  M_UnicodeFunction(PB_Gadget_FreeWeb)

#define PB_Window_ProcessEvent     M_UnicodeFunction(PB_Window_ProcessEvent)
#define PB_Window_RawProcessEvent  M_UnicodeFunction(PB_Window_RawProcessEvent)


typedef int (*WebGadgetTranslateAcceleratorFunc)(UINT uMsg, WPARAM wParam, LPARAM lParam);
extern WebGadgetTranslateAcceleratorFunc PB_Gadget_WebGadgetTranslateAccelerator; 


M_PBFUNCTION(LRESULT) PB_Window_RawProcessEvent(HWND Window, UINT Message, WPARAM wParam, LPARAM lParam);
LRESULT CALLBACK PB_Window_ProcessEvent(HWND Window, UINT Message, WPARAM wParam, LPARAM lParam);

M_PBFUNCTION(HWND) PB_Gadget_RegisterGadget(integer GadgetID, PB_Gadget *Gadget, HWND GadgetWindow, PB_GadgetVT *VT);
M_PBFUNCTION(integer)  PB_Gadget_GetCommonControlsVersion(void);
M_PBFUNCTION(void) PB_Gadget_PushGadgetList(HWND NewCurrentWindow);
M_PBFUNCTION(HWND) PB_Gadget_GetRootWindow(HWND Window);
M_PBFUNCTION(void) PB_Gadget_FlushEvents(void);
M_PBFUNCTION(void) PB_Gadget_GenericResizeGadget(PB_Gadget *Gadget, int x, int y, int Width, int Height);
M_PBFUNCTION(void) PB_Gadget_DrawListIconGrid(HWND Window, HDC DC, COLORREF Color);
M_PBFUNCTION(void) PB_Gadget_GetRequiredSize(PB_Gadget *Gadget, int *Width, int *Height);

M_PBFUNCTION(PB_GadgetImageList *) PB_Gadget_InitImageList(int NeedLargeList);
M_PBFUNCTION(void)                 PB_Gadget_FreeImageList(PB_GadgetImageList *ImageList);
M_PBFUNCTION(integer)              PB_Gadget_AddImageList(HBITMAP Image, PB_GadgetImageList *ImageList);
M_PBFUNCTION(void)                 PB_Gadget_RemoveImageList(PB_GadgetImageList *ImageList, int Index);
M_PBFUNCTION(void)                 PB_Gadget_ClearImageList(PB_GadgetImageList *ImageList);
M_PBFUNCTION(PB_Gadget *)          PB_IsGadget(integer GadgetID);
M_PBFUNCTION(void)                 PB_Gadget_SendGadgetCommand(HWND Window, int EventType);
M_PBFUNCTION(void)                 PB_Gadget_SendForcedGadgetCommand(HWND Window, int EventType);
M_PBFUNCTION(integer)							 PB_Gadget_EnsureGadget(HWND Gadget);
M_PBFUNCTION(void)                 PB_Gadget_AddInbetweenImage(HWND GadgetWindow, HIMAGELIST ImageList);

#define PB_Gadget_RedrawGadget(Window) RedrawWindow(Window, 0, 0, RDW_ERASE|RDW_INTERNALPAINT|RDW_INVALIDATE|RDW_FRAME)

M_PBFUNCTION(HBRUSH) PB_Gadget_CreateSharedBrush(int Color);
M_PBFUNCTION(void)   PB_Gadget_FreeSharedBrush(HBRUSH Brush);

// shared coloring functions for simple Gadgets
M_PBFUNCTION(void) PB_Gadget_SharedSetGadgetColor(PB_Gadget *Gadget, int ColorType, int Color);
M_PBFUNCTION(integer)  PB_Gadget_SharedGetGadgetColor(PB_Gadget *Gadget, int ColorType);
M_PBFUNCTION(void) PB_Gadget_SharedFreeGadget(PB_Gadget *Gadget);

M_PBFUNCTION(void) PB_FreeGadget(integer GadgetID);
M_PBFUNCTION(void) PB_ClearGadgetItems(integer GadgetID);
M_PBFUNCTION(HWND) PB_UseGadgetList(HWND WindowID);
M_PBFUNCTION(integer) PB_GadgetX(integer GadgetID);
M_PBFUNCTION(integer) PB_GadgetY(integer GadgetID);
M_PBFUNCTION(integer) PB_GadgetWidth(integer GadgetID);
M_PBFUNCTION(integer) PB_GadgetHeight(integer GadgetID);
M_PBFUNCTION(integer) PB_CountGadgetItems(integer GadgetID);
M_PBFUNCTION(integer) PB_GetActiveGadget(void);


#define PB_RectTopProperty    TEXT("PB_RectTop")
#define PB_RectBottomProperty TEXT("PB_RectBottom")


#include <Gadget/GadgetCommon.h>



#define PB_Gadget_GetOrAllocateID(GadgetID) ((PB_Gadget *)PB_Object_GetOrAllocateID(PB_Gadget_Objects, GadgetID))
#define PB_Gadget_GetObject(GadgetID) 			((PB_Gadget *)PB_Object_GetObject			 (PB_Gadget_Objects, GadgetID))
#define PB_Gadget_FreeID(GadgetID) 											  PB_Object_FreeID         (PB_Gadget_Objects, GadgetID)

#endif
