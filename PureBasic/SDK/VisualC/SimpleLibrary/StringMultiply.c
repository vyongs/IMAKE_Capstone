/*
 * String return example
 */

#include "Simple.h"


/* We use the 'TCHAR' type, which is a 'char' in ascii and a 'short' in unicode mode
 * so we don't have to do 2 versions of the command.
 * When defining the UNICODE constant, all Windows API switch to unicode functions
 * automatically.
 *
 * To test if your string function works correctly, always test it in an expression like:
 * a$ = "++"+MyFunction()+"++"
 *
 * Note: the 'PreviousPosition' parameter is added to all PB functions which need to return
 * a string
 */
 M_PBFUNCTION(void) PB_StringMultiply(const TCHAR *String, int NbTimes, int PreviousPosition)
{
  int StringLength;
  int k;
  int ParameterIndex;
  TCHAR *Output;

  if (String) // Ensure the pointer isn't null
  {
    if (NbTimes < 0) // Ensure we don't pass a negative value
      NbTimes = 0;
  
    StringLength = strlen(String)*NbTimes; 
  }
  else
    StringLength = 0;

  // Get the index of the parameter in the internal buffer (will return 0 if it's not in the internal buffer)
  //
  ParameterIndex = SYS_GetParameterIndex(String);
  
  // Requests the size. The internal buffer can be reallocated here, so that's why we called SYS_GetParameterIndex() just above
  //
  Output = SYS_GetOutputBuffer(StringLength, PreviousPosition);

  // Get back the string pointer only if it was on the internal buffer
  //  
  if (ParameterIndex)
 	  String = SYS_ResolveParameter(ParameterIndex);

  for (k=0; k<NbTimes; k++)
  {
    // NOTE: to deal with unicode easily, PureLibrary.h redefine all command 'string' function from the libc
    // to their unicode equivalent. If you don't need it, you will have to #undef them at the start of your source
    //
    strcpy(Output, String);
    Output += (StringLength/NbTimes);
  }
  
  *Output = 0;  // Ensure the null byte is written
}


