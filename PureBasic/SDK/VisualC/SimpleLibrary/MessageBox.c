/*
 * MessageBox example
 */

#include "Simple.h"

/* We use the 'TCHAR' type, which is a 'char' in ascii and a 'short' in unicode mode
 * so we don't have to do 2 versions of the command.
 * When defining the UNICODE constant, all Windows API switch to unicode functions
 * automatically
 */
M_PBFUNCTION(int) PB_MessageBox(HWND Window, const TCHAR *Text, const TCHAR *Title, int Buttons)
{
  return MessageBox(Window, Text, Title, Buttons);
}
