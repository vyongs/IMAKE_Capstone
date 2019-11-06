/*
 * IsTicket()
 */

#include "Ticket.h"


M_PBFUNCTION(PB_Ticket *) PB_IsTicket(integer TicketID)
{
  return PB_Object_IsObject(PB_Ticket_Objects, TicketID);
}
