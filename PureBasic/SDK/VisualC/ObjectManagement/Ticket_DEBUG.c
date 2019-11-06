/*
 * Debug file for the simple library file
 */

#include "Ticket.h"
#include <DebuggerModule.h>


// Custom error messages can be localized
//
static PB_Language LanguageTable = 
{
  "Libraries.catalog", // Filename where the string are found (will be located in PureBasic\Catalogs directory)
  "PB_Libraries",      // 
  "File",              // Section name
  0,
  {     
    "Negative ticket",   "A ticket value can't be negative.",  
    "666 ticket",  "Deamon ticket not allowed !",  
    "", "",   
  }
};


static void CheckInit()
{
  // Nothing to do here. A common place to put global init code check
}


static void CheckIDRange(integer ID)
{
  CheckInit();

  if (ID < -1 || ID >= 1000)
    SendCommonError("HighNumber", "#Ticket", 1000);
}


static void CheckObject(integer ID)
{
  CheckInit();

	if (PB_IsTicket(ID) == 0)
    SendCommonError("NoObject", "#Ticket");
}




/* All debug commands (name + _DEBUG)
 */ 

void PB_FreeTicket_DEBUG(integer TicketID)
{
}


void PB_CreateTicket2_DEBUG(integer TicketID, int Value, int Flags)
{
  CheckIDRange(TicketID);
  
  if (Value < 0)
  {
    SendTranslatedError("Negative ticket");
  }
  else if (Value == 666)
  {
    SendTranslatedError("666 ticket");
  }
}
void PB_CreateTicket_DEBUG(integer TicketID, int Value) { PB_CreateTicket2_DEBUG(TicketID, Value, 0); }


void PB_DisplayTicket_DEBUG(integer TicketID)
{
  CheckObject(TicketID);
}
