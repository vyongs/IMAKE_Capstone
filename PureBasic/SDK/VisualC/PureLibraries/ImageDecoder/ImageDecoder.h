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
 
#ifndef IMAGEDECODER_H
#define IMAGEDECODER_H


#include <PureLibrary.h>
#include <Object/Object.h>
#include <Memory/Memory.h>

// decoder mode
#define PB_ImageDecoder_File   0
#define PB_ImageDecoder_Memory 1

// flags for Decode() and Encode()
#define PB_ImageDecoder_ReverseY        (1 << 1)

struct PB_ImageDecoderStruct;

// Nb private global data for the decoder
#define PB_ImageDecoder_NbData 8

/* Global data for the decoding process. This structure is passed directly to the decoder for convenience, but
 * a decoder can also call GetThreadMemory() to get it if the data is needed outside of the main decoder functions.
 *
 */
typedef struct
{
  // Set by ImageDecoder functions
  //
  struct PB_ImageDecoderStruct *Decoder;

  // The Filename is only valid inside the Check(). If the decoder needs it longer, it must make a copy!
  // The Filename is always ASCII on Linux and unicode-dependent on Windows
  //
  const char *Filename;
  FILE       *File;
  const char *Buffer;
  int         Length;
  int         Mode;

  // Set by the decoders
  //
  int Width;
  int Height;
  int Depth;
  int Flags;

  // Private data fields so the decoders can store global data
  // Note: we do use the 'data' system, because the structure has to have the
  // same size for every decoder because it's a global per threads memory, which
  // is initialized in the 'Init' routine (so every created threads got its private
  // area).
  //
  integer Data[PB_ImageDecoder_NbData];
  
  int OriginalDepth;
  int NbFrames;
  int FrameDelay; // delay between frame (milliseconds)
} PB_ImageDecoderGlobals;



/* Note: The Cleanup() is only called if for some reason Decode() will not be called.
 *   (for example if the Image allocation failed. Decode() does its own cleanup too!
 *
 * So the possible call sequence is "Check -> Decode" or "Check -> Cleanup"
 */
typedef struct PB_ImageDecoderStruct
{
  integer (M_PBVIRTUAL *Check)  (PB_ImageDecoderGlobals *Globals);
  integer (M_PBVIRTUAL *Decode) (PB_ImageDecoderGlobals *Globals, char *Buffer, int Pitch, int Flags);
  void (M_PBVIRTUAL *Cleanup)(PB_ImageDecoderGlobals *Globals);
  int ID;
} PB_ImageDecoder;


#define PB_ImageDecoder_CheckFile M_UnicodeFunction(PB_ImageDecoder_CheckFile)

extern int 							 PB_ImageDecoder_NbDecoders;
extern PB_ImageDecoder  *PB_ImageDecoder_Decoders[30];
extern integer           PB_ImageDecoder_Globals;

// On Linux/OSX, StringToFilename() must be called OUTSIDE of this function! (as it is usually already needed for BMP check too)
M_PBFUNCTION(integer)  PB_ImageDecoder_CheckFile(const TCHAR *Filename);

M_PBFUNCTION(integer)  PB_ImageDecoder_CheckMemory(const char *Buffer, integer Length);
M_PBFUNCTION(integer)  PB_ImageDecoder_GetWidth();
M_PBFUNCTION(integer)  PB_ImageDecoder_GetHeight();
M_PBFUNCTION(integer)  PB_ImageDecoder_GetDepth();
M_PBFUNCTION(integer)  PB_ImageDecoder_GetOriginalDepth();
M_PBFUNCTION(integer)  PB_ImageDecoder_GetNbFrames();
M_PBFUNCTION(integer)  PB_ImageDecoder_GetFrameDelay();
M_PBFUNCTION(integer)  PB_ImageDecoder_Decode(char *Buffer, int LinePitch, int Flags);
M_PBFUNCTION(void)     PB_ImageDecoder_Cleanup();

M_PBFUNCTION(void)     PB_ImageDecoder_Register(PB_ImageDecoder *Decoder);



/* Note:
 * - The Encode24 must always be implemented. The Encode32 is optional
 * - Filename is always ASCII on Linux, and unicode dependent on Windows
 * - Flags contains PB_ImageDecoder_ReverseY
 * - EncoderFlags contains the flags parameter from SaveImage
 */
typedef struct
{
	int ID;
	integer (M_PBVIRTUAL *Encode24)(const char *Filename, const char *Buffer, int Width, int Height, int LinePitch, int Flags, int EncoderFlags, int RequestedDepth);
	integer (M_PBVIRTUAL *Encode32)(const char *Filename, const char *Buffer, int Width, int Height, int LinePitch, int Flags, int EncoderFlags, int RequestedDepth);
}  PB_ImageEncoder;

extern int 							 PB_ImageEncoder_NbEncoders;
extern PB_ImageEncoder  *PB_ImageEncoder_Encoders[30];

M_PBFUNCTION(void) PB_ImageEncoder_Register(PB_ImageEncoder *Decoder);

#define PB_ImageEncoder_Encode M_UnicodeFunction(PB_ImageEncoder_Encode)

/* Note:
 * - This function is unicode dependent.
 * - The input must be 32bit or 24bit
 * - This directly handles 32bit and 24bit BMP images, so only Windows needs extra bitmap handling for < 24bit
 */
M_PBFUNCTION(integer) PB_ImageEncoder_Encode(const TCHAR *Filename, const char *Buffer, int ID, int Width, int Height, int LinePitch, int Depth, int Flags, int EncoderFlags, int RequestedDepth);


typedef struct 
{
  unsigned char Red;
  unsigned char Green;
  unsigned char Blue;
} PB_RGB;


typedef struct 
{
  unsigned char Red;
  unsigned char Green;
  unsigned char Blue;
  unsigned char Alpha;
} PB_RGBA;


/* Location of color components for 32bit -> 24bit mapping
 */
#if defined(WINDOWS)
  #define OFFSET32_RED    2
  #define OFFSET32_GREEN  1
  #define OFFSET32_BLUE   0
  #define OFFSET32_ALPHA  3
  
  #define OFFSET24_RED    2
  #define OFFSET24_GREEN  1
  #define OFFSET24_BLUE   0  
  
#else
  #define OFFSET32_RED    0
  #define OFFSET32_GREEN  1
  #define OFFSET32_BLUE   2
  #define OFFSET32_ALPHA  3
  
  #define OFFSET24_RED    0
  #define OFFSET24_GREEN  1
  #define OFFSET24_BLUE   2
#endif


M_PBFUNCTION(void *) PB_ImageDecoder_ConvertRGBToRGBA(const PB_RGB *Input, int Width, int Height, int RowPitch);


#define PB_ImagePlugin_JPEG      0x4745504A  // Note than gcc complain about 'JPEG'
#define PB_ImagePlugin_JPEG2000  0x4B32504A  // Note than gcc complain about 'JP2K'
#define PB_ImagePlugin_PNG       0x474E50    // Note than gcc complain about 'PNG'
#define PB_ImagePlugin_TGA       0x414754    // Note than gcc complain about 'TGA'
#define PB_ImagePlugin_TIFF      0x46464954  // Note than gcc complain about 'TIFF'
#define PB_ImagePlugin_BMP       0x504D42    // Note than gcc complain about 'BMP'
#define PB_ImagePlugin_ICON      0x4E4F4349  // Not a real decoder/encoder, but used by ImageFormat()
#define PB_ImagePlugin_GIF       0x474946    // Note than gcc complain about 'GIF'

#endif
