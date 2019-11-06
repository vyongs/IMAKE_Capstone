/* === Copyright Notice ===
 *
 *
 *                  PureBasic source code file
 *
 *
 * This file is part of the PureBasic Software package. It may not
 * be distributed or published in source code or binary form without
 * the expressed permission by Fantaisie Software.
 *
 * By contributing modifications or additions to this file, you grant
 * Fantaisie Software the rights to use, modify and distribute your
 * work in the PureBasic package.
 *
 *
 * Copyright (C) 2000-2010 Fantaisie Software - all rights reserved
 *
 */

#include <PureLibrary.h>
#include <String/String.h>


#define PB_CompareMemoryString  M_UnicodeFunction(PB_CompareMemoryString)
#define PB_CompareMemoryString2 M_UnicodeFunction(PB_CompareMemoryString2)
#define PB_CompareMemoryString3 M_UnicodeFunction(PB_CompareMemoryString3)
#define PB_CompareMemoryString4 M_UnicodeFunction(PB_CompareMemoryString4)
#define PB_CopyMemoryString     M_UnicodeFunction(PB_CopyMemoryString)
#define PB_CopyMemoryString2    M_UnicodeFunction(PB_CopyMemoryString2)
#define PB_FillMemory           M_UnicodeFunction(PB_FillMemory)
#define PB_FillMemory2          M_UnicodeFunction(PB_FillMemory2)
#define PB_FillMemory3          M_UnicodeFunction(PB_FillMemory3)
#define PB_MemoryStringLength   M_UnicodeFunction(PB_MemoryStringLength)
#define PB_MemoryStringLength2  M_UnicodeFunction(PB_MemoryStringLength2)
#define PB_PeekC     						M_UnicodeFunction(PB_PeekC)
#define PB_PeekS     						M_UnicodeFunction(PB_PeekS)
#define PB_PeekS2    						M_UnicodeFunction(PB_PeekS2)
#define PB_PeekS3    						M_UnicodeFunction(PB_PeekS3)
#define PB_PokeC    						M_UnicodeFunction(PB_PokeC)
#define PB_PokeS    						M_UnicodeFunction(PB_PokeS)
#define PB_PokeS2    						M_UnicodeFunction(PB_PokeS2)
#define PB_PokeS3    						M_UnicodeFunction(PB_PokeS3)

// Purifier enabled functions
#define PB_AllocateMemory2    M_PurifierFunction(PB_AllocateMemory2)
#define PB_AllocateMemory     M_PurifierFunction(PB_AllocateMemory)
#define PB_AllocateStructure  M_PurifierFunction(PB_AllocateStructure)
#define PB_FreeMemory         M_PurifierFunction(PB_FreeMemory)
#define PB_FreeStructure      M_PurifierFunction(PB_FreeStructure)
#define PB_MemorySize         M_PurifierFunction(PB_MemorySize)
#define PB_ReAllocateMemory2  M_PurifierFunction(PB_ReAllocateMemory2)
#define PB_ReAllocateMemory   M_PurifierFunction(PB_ReAllocateMemory)


typedef struct PB_StructureMemory
{
	int *Memory;
} PB_Memory;

// #define PB_GetObjectAddress() (struct PB_StructureMemory *)((int)PB_Memory_ObjectsArea+MemoryID*sizeof(struct PB_StructureMemory))

#ifdef WINDOWS
  #define F_AllocateMemory(Size) HeapAlloc(PB_Memory_Heap, HEAP_ZERO_MEMORY, Size)
  #define F_AllocateMemoryNoClear(Size) HeapAlloc(PB_Memory_Heap, 0, Size)
  #define F_ReAllocateMemory(Memory, Size) HeapReAlloc(PB_Memory_Heap, HEAP_ZERO_MEMORY, Memory, Size)
  #define F_ReAllocateMemoryNoClear(Memory, Size) HeapReAlloc(PB_Memory_Heap, 0, Memory, Size)
  #define F_FreeMemory(Memory) HeapFree(PB_Memory_Heap, 0, Memory)
  #define F_CopyMemory(DestinationMemory, SourceMemory, Size) CopyMemory(DestinationMemory, SourceMemory, Size)
  #define F_MoveMemory(DestinationMemory, SourceMemory, Size) memmove(DestinationMemory, SourceMemory, Size)
  #define F_MemorySize(Memory) HeapSize(PB_Memory_Heap, 0, Memory)
#else
  #define F_AllocateMemory(Size) SYS_AllocateMemoryWithSize(Size)
  #define F_AllocateMemoryNoClear(Size) SYS_AllocateMemoryWithSizeNoClear(Size)
  #define F_ReAllocateMemory(Memory, Size) SYS_ReAllocateMemoryWithSize(Memory, Size)
  #define F_ReAllocateMemoryNoClear(Memory, Size) SYS_ReAllocateMemoryWithSizeNoClear(Memory, Size)
  #define F_FreeMemory(Memory) SYS_FreeMemoryWithSize(Memory)
  #define F_CopyMemory(DestinationMemory, SourceMemory, Size) memcpy(DestinationMemory, SourceMemory, Size)
  #define F_MoveMemory(DestinationMemory, SourceMemory, Size) memmove(DestinationMemory, SourceMemory, Size)
  #define F_MemorySize(Memory) (*((integer *)(Memory)-1))
#endif


#define PB_String_Greater 1
#define PB_String_Equal 0
#define PB_String_Lower -1

#define PB_Memory_NoClear 1

// This one is combined with PB_Unicode/Ascii/UTF8, so it needs to be greater than PB_NativeTypeMask
#define PB_String_NoZero (1 << 8)


extern int  PB_Memory_ObjectsNumber;
extern PB_Memory *PB_Memory_ObjectsArea;
extern int *PB_Memory_CurrentObject;
extern TCHAR **PB_Memory_CurrentStringPointer;
extern int *PB_Memory_Heap;

void *PB_Memory_GetAddress(int DynamicOrArrayID);

M_PBFUNCTION(void)   PB_FreeMemory(void *Memory);
M_PBFUNCTION(void)   PB_FreeMemorys();
M_PBFUNCTION(void)   PB_InitMemory();
M_PBFUNCTION(void *) PB_AllocateMemory(integer Size);
M_PBFUNCTION(void *) PB_AllocateMemory2(integer Size, int Flags);
M_PBFUNCTION(void *) PB_ReAllocateMemory(void *Memory, integer Size);
M_PBFUNCTION(void *) PB_ReAllocateMemory2(void *Memory, integer Size, int Flags);
M_PBFUNCTION(integer) PB_MemorySize(const char *Memory);
M_PBFUNCTION(void)   PB_PeekS(const TCHAR *Address, int PreviousPosition);
M_PBFUNCTION(void)   PB_PeekS3(const TCHAR *Address, integer Length, int Flags, int PreviousPosition);
