/*
 * Simple library header file
 */

#include <PureLibrary.h>
#include <Object/Object.h>

/* Our ticket object structure, ie: the data attached to one ticket
 */
typedef struct
{
  int Value;
} PB_Ticket;

/* Our global variables, which will be defined in Ticket.c
 * NOTE: All global variable of a lib should be prefixed with PB_LibrarName_
 * to avoid library symbol name clash when linking
 */
extern PB_Object *PB_Ticket_Objects;

M_PBFUNCTION(PB_Ticket *) PB_IsTicket(integer TicketID);

/* Define a few helper functions
 */
#define PB_Ticket_GetOrAllocateID(TicketID) ((PB_Ticket *)PB_Object_GetOrAllocateID (PB_Ticket_Objects, TicketID))
#define PB_Ticket_GetObject(TicketID)       ((PB_Ticket *)PB_Object_GetObject       (PB_Ticket_Objects, TicketID))
#define PB_Ticket_FreeID(TicketID)                        PB_Object_FreeID          (PB_Ticket_Objects, TicketID)




