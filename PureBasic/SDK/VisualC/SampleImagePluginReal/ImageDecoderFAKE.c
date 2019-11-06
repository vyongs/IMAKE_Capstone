/*
 */
 
#include "ImageFAKE.h"

/* Cleanup routine, as it's used by the longjump and the normal finish routine
 *
 **/

static M_PBFUNCTION(void) Cleanup(PB_ImageDecoderGlobals *Globals)
{
}


static M_PBFUNCTION(integer) Decode(PB_ImageDecoderGlobals *Globals, char *Buffer, int LinePitch, int Flags)
{
  // you can access the global data	(8 'integer' slots available (32bit or 64bit depending of the PB version) you set in Check()
	// Globals->Data[0]
	
	return 1; // return 1 if successful
}


static M_PBFUNCTION(integer) Check(PB_ImageDecoderGlobals *Globals)
{
	int Result = 0;
	int FileLength = 0;
	integer MaximumLength = 0;
	char *Memory = 0;

	if (Globals->Mode == PB_ImageDecoder_File) // File streaming not supported on jpeg for now, so we read the full file in memory
	{
		// you can use 'Globals->File' here which is a regular FILE (fread() and such)
  }
	else if (Globals->Length >= 2) // Memory based
	{
	  Memory = (char *)Globals->Buffer;
		MaximumLength = (integer)Globals->Length; 
	}

	if (Memory)  // Read directly from a memory buffer
	{
	}

	return Result; // return non zero if the decoder supports this format
}


static PB_ImageDecoder ImageDecoder;
static int Registered = 0;

M_PBFUNCTION(integer) PB_UseFAKEImageDecoder()
{
	if (Registered == 0)
	{
		ImageDecoder.Check   = Check;
		ImageDecoder.Decode  = Decode;
		ImageDecoder.Cleanup = Cleanup;

		PB_ImageDecoder_Register(&ImageDecoder);
		Registered = 1;
	}

	return Registered;
}
