/*
 * Simple Library
 *
 * Init and End functions example
 */

#include "Simple.h"


/* This function is called automatically when program starts
 */
M_PBFUNCTION(void) PB_InitSimple()
{
  MessageBox(0, "This is our init function", "", 0);
}


/* This function is called automatically when program ends
 */
M_PBFUNCTION(void) PB_FreeSimples()
{
  MessageBox(0, "This is our end function", "", 0);
}