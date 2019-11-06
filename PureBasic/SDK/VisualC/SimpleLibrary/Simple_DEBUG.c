/*
 * Debug file for the simple library file
 */

#include "Simple.h"
#include <DebuggerModule.h>


/* All command debug equivalent (name + _DEBUG)
 * NOTE: There is no more M_PBFUNCTION attribute as the function need to be CDecl
 */ 
 
void PB_MessageBox_DEBUG(HWND Window, char *Text, char *Title, int Buttons)
{
  if (IsWindow(Window) == 0)
    SendDebuggerError("Not a valid window ID !");
}


void PB_StringMultiply_DEBUG(char *String, int NbTimes)
{
  if (NbTimes < -1)
    SendDebuggerError("StringMulitply(): NbTimes parameter can't be negative");
}
