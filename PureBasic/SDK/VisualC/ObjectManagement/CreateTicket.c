/*
 * Ticker example
 */

#include "Ticket.h"

// Note: always use 'integer' for ID, as it can be a pointer, and on 64 bit, 'int' is still 32 bit on Windows
//
M_PBFUNCTION(PB_Ticket *) PB_CreateTicket2(integer TicketID, int Value, int Flags)
{
  PB_Ticket *Ticket;
  
  // Previous object will be free'ed automatically by the object manager
  // as we used the 'free' callback in the object initializer.
  //
  if (Ticket = PB_Ticket_GetOrAllocateID(TicketID))
  {
    Ticket->Value = Value;
  }
  
  return Ticket; // return the Ticket object address, which is important if #PB_Any is used for the ID
}


M_PBFUNCTION(PB_Ticket *) PB_CreateTicket(integer TicketID, int Value)
{
  return PB_CreateTicket2(TicketID, Value, 0);
}
