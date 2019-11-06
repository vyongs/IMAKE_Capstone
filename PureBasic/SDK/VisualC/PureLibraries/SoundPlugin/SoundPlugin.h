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
#include <stdio.h>


#define PB_SoundDecoder_Create M_UnicodeFunction(PB_SoundDecoder_Create)

// Duplicate the Sound.h constants here
//
#define PB_Sound_Loop 1

typedef	void *(M_PBVIRTUAL *SoundDecoderCreateType)(FILE *File, const char *Memory, int MemoryLength, int Flags);
typedef	int   (M_PBVIRTUAL *SoundDecoderDecodeType)(void *Decoder, char *OutputBuffer, int Length, int Format, int Flags);
typedef	void  (M_PBVIRTUAL *SoundDecoderStopType)(void *Decoder);
typedef	int   (M_PBVIRTUAL *SoundDecoderGetNbChannelsType)(void *Decoder);
typedef	int   (M_PBVIRTUAL *SoundDecoderGetNbSamplesType)(void *Decoder);
typedef	int   (M_PBVIRTUAL *SoundDecoderGetRateType)(void *Decoder);
typedef	void  (M_PBVIRTUAL *SoundDecoderFreeType)(void *Decoder);

typedef struct
{
	SoundDecoderCreateType        Create;
	SoundDecoderDecodeType        Decode;
	SoundDecoderStopType          Stop;
	SoundDecoderGetNbChannelsType GetNbChannels;
	SoundDecoderGetNbSamplesType  GetNbSamples;
	SoundDecoderGetRateType       GetRate;
	SoundDecoderFreeType          Free;
} PB_SoundDecoderFunctions;


// Every sound decoder plugin will implement this structure
typedef struct
{
  PB_SoundDecoderFunctions *Functions; 
  FILE *File;
} PB_SoundDecoder;


typedef struct
{
	int ID;
	int (M_PBVIRTUAL *Encode)(char *Filename, char *Buffer, int Width, int Height, int LinePitch, int Flags);
} PB_SoundEncoder;


extern int                       PB_SoundDecoder_NbDecoders;
extern PB_SoundDecoderFunctions *PB_SoundDecoder_Decoders[];


// Decoder functions
M_PBFUNCTION(PB_SoundDecoder *) PB_SoundDecoder_Create(const TCHAR *Filename, const char *Memory, int MemoryLength, int Flags);
M_PBFUNCTION(integer)    PB_SoundDecoder_GetNbChannels(PB_SoundDecoder *Decoder);
M_PBFUNCTION(integer)    PB_SoundDecoder_GetNbSamples(PB_SoundDecoder *Decoder);
M_PBFUNCTION(integer)    PB_SoundDecoder_GetRate(PB_SoundDecoder *Decoder);
M_PBFUNCTION(void)   PB_SoundDecoder_Free(PB_SoundDecoder *Decoder);
M_PBFUNCTION(void)   PB_SoundDecoder_Stop(PB_SoundDecoder *Decoder);
M_PBFUNCTION(integer)    PB_SoundDecoder_Decode(PB_SoundDecoder *Decoder, char *Buffer, int Length, int Format, int Flags);
M_PBFUNCTION(void)   PB_SoundDecoder_Register(PB_SoundDecoderFunctions *DecoderFunctions);

// Encoder functions
M_PBFUNCTION(void)   PB_SoundEncoder_Register(PB_SoundDecoderFunctions *Decoder);
M_PBFUNCTION(integer)    PB_SoundEncoder_Encode(char *Filename, char *Buffer, int ID, int Width, int Height, int LinePitch, int Flags);

// Helper functions
M_PBFUNCTION(void)   PB_SoundPlugin_SuppressChannel(char *Buffer, int NbSamples, int SampleLength, int Format);
