/*
 */

#include "ListIconSampleGadget.h"


/* Usage of the Data fields in the Gadget Structure:
 *  [0] length of largest string in the Gadget
 *  [1] pointer to PB_GadgetImageList for this gadget (0 if no images yet)
 *  [2] GridLine Color
 *  [3] internal flags (not Gadget flags), to know if custom colors are set etc
 */
#define DATA_MaxString  0
#define DATA_ImageList  1
#define DATA_GridColor  2
#define DATA_InternalFlags 3

// values for the InternalFlags field
//
#define FLAG_FrontColorSet     (1)
#define FLAG_BackColorSet      (1 << 1)
#define FLAG_DisplayGrid       (1 << 2)
#define FLAG_ThreeStateMode    (1 << 3) // 3state mode is on
#define FLAG_ThreeStateBlocked (1 << 4) // block state change in 3state mode

/* Storage of individual cell colors + user data for each item.
 * This data is stored in a memoryblock which is stored in lParam of each item struct.
 * It is only allocated when needed, so always check the lParam for 0!
 * If the memory exists though, it has the number of cells inside as there are columns in the gadget.
 */
typedef struct
{
  int FrontColor; // colors are stored as (ColorValue+1), so 0 means no color stored yet
  int BackColor;
} PB_ListIconCell;

typedef struct
{
  integer UserData;
  PB_ListIconCell Cells[];
} PB_ListIconItem;
// only the base struct, not the following cells
#define SIZEOF_ListIconItem sizeof(integer)

static PB_GadgetVT ListIconVT;
static int         Initialized;
static int         OriginalFrontColor, OriginalBackColor;
static WNDPROC     StandardListIconCallback;

// -----------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer) ListIcon_Callback(PB_Gadget *Gadget, HWND Window, UINT Message, WPARAM wParam, LPARAM lParam)
{
  integer Result = PB_EventNotProcessed;

  if (Message == WM_NOTIFY) // Handle any message here
  {
    Result = 0; // set Result to 0, if you don't want the event to be populated to next handlers
  }

  return Result;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetColor(PB_Gadget *Gadget, int ColorType, int Color)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer)  ListIcon_GetGadgetColor(PB_Gadget *Gadget, int ColorType)
{
  return 0;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetItemColor2(PB_Gadget *Gadget, int Item, int ColorType, int Color, int Column)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(int)  ListIcon_GetGadgetItemColor2(PB_Gadget *Gadget, int Item, int ColorType, int Column)
{
  return 0;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_FreeGadget(PB_Gadget *Gadget)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_FillColumns(PB_Gadget *Gadget, int Position, TCHAR *Cursor)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer) ListIcon_AddGadgetItem2(PB_Gadget *Gadget, int Position, const TCHAR *Text, int *Image)
{
  return 0;
}


// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(int) ListIcon_CountGadgetItems(PB_Gadget *Gadget)
{
  return 0;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_ClearGadgetItems(PB_Gadget *Gadget)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_RemoveGadgetItem(PB_Gadget *Gadget, int Position)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetState(PB_Gadget *Gadget, integer Index)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_GetGadgetItemText(PB_Gadget *Gadget, int ItemID, int ColumnID, int PreviousStringPosition)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer) ListIcon_GetGadgetState(PB_Gadget *Gadget)
{
  return 0;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_GetGadgetText(PB_Gadget *Gadget, int PreviousStringPosition)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetText(PB_Gadget *Gadget, const TCHAR *Text)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(int) ListIcon_GetGadgetItemState(PB_Gadget *Gadget, int ItemID)
{
  return 0;
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetItemState(PB_Gadget *Gadget, int ItemID, int State)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetItemText(PB_Gadget *Gadget, int ItemID, const TCHAR *Text, int ColumnID)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_AddGadgetColumn(PB_Gadget *Gadget, int Position, const TCHAR *Text, int Width)
{
}

// ---------------------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_RemoveGadgetColumn(PB_Gadget *Gadget, int Position)
{
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetItemData(PB_Gadget *Gadget, int Item, integer Value)
{
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer)  ListIcon_GetGadgetItemData(PB_Gadget *Gadget, int Item)
{
  return 0;
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetItemAttribute2(PB_Gadget *Gadget, int Item, int Attribute, int Value, int Column)
{
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(int)  ListIcon_GetGadgetItemAttribute2(PB_Gadget *Gadget, int Item, int Attribute, int Column)
{
  return 0;
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(integer)  ListIcon_GetGadgetAttribute(PB_Gadget *Gadget, int Attribute)
{
  return 0;
}

// -----------------------------------------------------------------------------

static M_GADGETVIRTUAL(void) ListIcon_SetGadgetAttribute(PB_Gadget *Gadget, int Attribute, int Value)
{
}

// -----------------------------------------------------------------------------

static LRESULT CALLBACK CustomCallback(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
  {
    case WM_NCDESTROY:
      RemoveProp(hWnd, PB_RectTopProperty);
      RemoveProp(hWnd, PB_RectBottomProperty);
	    break;


		case WM_SETFONT:
      RemoveProp(hWnd, PB_RectTopProperty); // It's this one which triggers the new measure for the empty list grid
      break;
  }

  return CallWindowProc(StandardListIconCallback, hWnd, message, wParam, lParam);
}

// -----------------------------------------------------------------------------

M_PBFUNCTION(HWND) PB_ListIconSampleGadget2(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Title, int ColumnWidth, int Flags)
{
  PB_GadgetGlobals *Globals = PB_Object_GetThreadMemory(PB_Gadget_Globals);
  HWND Result;
  PB_Gadget *Gadget;
  int Mask    = WS_TABSTOP | WS_CHILD | WS_VISIBLE | LVS_REPORT | LVS_SHAREIMAGELISTS | Flags;
  int ExMask = LVS_EX_DOUBLEBUFFER; // We do use double buffered listview (needs XP or above, but will be ignored on previous Windows)
  HIMAGELIST ImageList;

  if ((Flags & LVS_SINGLESEL) == 0)  // Multiselection emulation
    Mask |= LVS_SINGLESEL;
  else
    Mask &= ~LVS_SINGLESEL;

  // We don't use 'LVS_EX_GRIDLINES' flags because of this nasty Windows bug: http://support.microsoft.com/kb/813791 (http://www.purebasic.fr/english/viewtopic.php?t=32912)
  // As we have our own ownerdraw line routine, use it all the time.
  //
  // if (Flags & WS_TABSTOP)
  //   ExMask |= LVS_EX_GRIDLINES;

  if (Flags & WS_CHILD)
    ExMask |= LVS_EX_FULLROWSELECT;

  if (Flags & WS_VISIBLE)
    ExMask |= LVS_EX_HEADERDRAGDROP;

  if (Flags & LVS_REPORT)
    ExMask |= LVS_EX_CHECKBOXES;

  // Useful: LVS_NOSORTHEADER (no clickable titles)
  //
  if (Result = CreateWindowEx(WS_EX_CLIENTEDGE, WC_LISTVIEW, 0, Mask, x, y, Width, Height, Globals->CurrentWindow, (HMENU)0, PB_Instance, 0))
  {

    // done after window creation to get the default colors...
    if (!Initialized)
    {
      PB_Gadget_GetCommonControlsVersion(); // make sure its called as the custom grid drawing needs to know the skin mode

      OriginalFrontColor = ListView_GetTextColor(Result);
      OriginalBackColor  = ListView_GetBkColor(Result);

      ZeroMemory(&ListIconVT, sizeof(PB_GadgetVT));

      ListIconVT.GadgetType = PB_GadgetType_ListIcon;
      ListIconVT.SizeOf     = sizeof(PB_GadgetVT);

      ListIconVT.GadgetCallback      = ListIcon_Callback;
      ListIconVT.FreeGadget          = ListIcon_FreeGadget;
      ListIconVT.AddGadgetColumn     = ListIcon_AddGadgetColumn;
      ListIconVT.AddGadgetItem2      = ListIcon_AddGadgetItem2;
      ListIconVT.GetGadgetState      = ListIcon_GetGadgetState;
      ListIconVT.SetGadgetState      = ListIcon_SetGadgetState;
      ListIconVT.GetGadgetText       = ListIcon_GetGadgetText;
      ListIconVT.SetGadgetText       = ListIcon_SetGadgetText;
      ListIconVT.CountGadgetItems    = ListIcon_CountGadgetItems;
      ListIconVT.ClearGadgetItems    = ListIcon_ClearGadgetItems;
      ListIconVT.RemoveGadgetItem    = ListIcon_RemoveGadgetItem;
      ListIconVT.GetGadgetItemState  = ListIcon_GetGadgetItemState;
      ListIconVT.SetGadgetItemState  = ListIcon_SetGadgetItemState;
      ListIconVT.GetGadgetItemText   = ListIcon_GetGadgetItemText;
      ListIconVT.SetGadgetItemText   = ListIcon_SetGadgetItemText;
      ListIconVT.RemoveGadgetColumn  = ListIcon_RemoveGadgetColumn;
      ListIconVT.SetGadgetColor      = ListIcon_SetGadgetColor;
      ListIconVT.GetGadgetColor      = ListIcon_GetGadgetColor;
      ListIconVT.SetGadgetItemColor2 = ListIcon_SetGadgetItemColor2;
      ListIconVT.GetGadgetItemColor2 = ListIcon_GetGadgetItemColor2;
      ListIconVT.SetGadgetItemData   = ListIcon_SetGadgetItemData;
      ListIconVT.GetGadgetItemData   = ListIcon_GetGadgetItemData;
      ListIconVT.SetGadgetAttribute  = ListIcon_SetGadgetAttribute;
      ListIconVT.GetGadgetAttribute  = ListIcon_GetGadgetAttribute;
      ListIconVT.SetGadgetItemAttribute2 = ListIcon_SetGadgetItemAttribute2;
      ListIconVT.GetGadgetItemAttribute2 = ListIcon_GetGadgetItemAttribute2;

      Initialized = 1;
    }
    
    SendMessage(Result, LVM_SETEXTENDEDLISTVIEWSTYLE, ExMask, ExMask);
    
    StandardListIconCallback = (WNDPROC)SetWindowLongPtr(Result, GWLP_WNDPROC, (LONG_PTR)CustomCallback);

    Gadget = PB_Gadget_GetOrAllocateID(GadgetID);
    Gadget->Data[DATA_GridColor] = -1;
    
    if (Flags & WS_TABSTOP)
      Gadget->Data[DATA_InternalFlags] |= FLAG_DisplayGrid; // Uses the colormask as storage, to avoid allocating a 'prop' only for that flag

    // 3state mode is only on when both flags are set
    //
    if ((Flags & LVS_REPORT) && (Flags & LVS_SHAREIMAGELISTS))
    {
      // The blocked flag disallows the user from selecting the inbetween state himself
      // (to match the behavior of the CheckBoxGadget)
      //
      Gadget->Data[DATA_InternalFlags] |= FLAG_ThreeStateMode|FLAG_ThreeStateBlocked;
      
      if (ImageList = ListView_GetImageList(Result, LVSIL_STATE))
        PB_Gadget_AddInbetweenImage(Result, ImageList);
    }

    Result = PB_Gadget_RegisterGadget(GadgetID, Gadget, Result, &ListIconVT);

    ListIcon_AddGadgetColumn(Gadget, 0, Title, ColumnWidth);
  }

  return Result;
}


M_PBFUNCTION(HWND) PB_ListIconSampleGadget(integer GadgetID, int x, int y, int Width, int Height, const TCHAR *Title, int ColumnWidth)
{
  return PB_ListIconSampleGadget2(GadgetID, x, y, Width, Height, Title, ColumnWidth, 0);
}
