#include "ImageDecoder.h"

M_PBFUNCTION int  PB_ImageDecoder_Check(char *Filename, char *Memory);
M_PBFUNCTION int  PB_ImageDecoder_GetWidth();
M_PBFUNCTION int  PB_ImageDecoder_GetHeight();
M_PBFUNCTION int  PB_ImageDecoder_Decode(char *Buffer, int LinePitch, int Format);
M_PBFUNCTION void PB_ImageDecoder_Register(struct PB_StructureImageDecoder *Decoder);

M_PBFUNCTION void PB_ImageEncoder_Register(struct PB_StructureImageEncoder *Decoder);
M_PBFUNCTION int PB_ImageEncoder_Encode(char *Filename, char *Buffer, int ID, int Width, int Height, int LinePitch, int Flags);

// Prototype for plugins functions

static _stdcall int Check(FILE *File, char *Memory, char *Filename);
