/*
 * Ticket Library
 *
 * Init and End functions example
 */

#include "Ticket.h"


/* Our global variable
 */
PB_Object *PB_Ticket_Objects;


/* Single ticket free routine
 */
M_PBFUNCTION(void) PB_FreeTicket(integer TicketID)
{
  PB_Ticket *Ticket;

	if (Ticket = PB_Ticket_GetObject(TicketID))
	{
		PB_Ticket_FreeID(TicketID); // Free either the dynamic ID or put the array ID to 0
  }
}

/* End routine, we have to free all the objects. The object manager provide a very handy functions for that.
 */
M_PBFUNCTION(void) PB_FreeTickets()
{
  PB_Object_CleanAll(PB_Ticket_Objects); // will enumerate all objects and call FreeTicket() on each
}

/* Init routine, just initialise our object manager.
 * The syntax is: PB_Object_Init(size of the object, increment step for the static objects, free routine address)
 */
M_PBFUNCTION(void) PB_InitTicket()
{
  /* When using the free routine callback, we don't need to explicitely free an object
   * when allocating a new one (the old one will be automatically freed).
   */
  PB_Ticket_Objects = PB_Object_Init(sizeof(PB_Ticket), 16, &PB_FreeTicket);
}
