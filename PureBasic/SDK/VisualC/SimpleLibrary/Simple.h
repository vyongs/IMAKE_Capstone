/*
 * Simple library header file
 */

#include <PureLibrary.h>

// We define all the functions which needs several version (here the unicode flags)
//
#define PB_MessageBox     M_UnicodeFunction(PB_MessageBox)
#define PB_StringMultiply M_UnicodeFunction(PB_StringMultiply)

