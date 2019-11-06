/*
 * MessageBox example
 */

#include "Ticket.h"


M_PBFUNCTION(void) PB_DisplayTicket(integer TicketID)
{
  PB_Ticket *Ticket;
  char Buffer[128];
  
  if (Ticket = PB_Ticket_GetObject(TicketID))
  {
    sprintf(Buffer, "Ticket value: %d", Ticket->Value);
    
    MessageBox(0, Buffer, "DisplayTicket()", 0);
  }
}
