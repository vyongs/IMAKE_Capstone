/*

		SDK Example
		-----------

    Fake Image encoder plugin for PureBasic

*/


#include "ImageFAKE.h"

/* The encoder procedure
 *
 * Parameters:
 *
 *   - Filename: The output file name (string$)
 *
 *   - Buffer: the uncompressed image buffer, in 24 bits format, similar to the
 *						 decoder buffer.
 *
 *   - Width:  Width of the picture to encode (in pixels)
 *
 *   - Height: Height of the picture to encode (in pixels)
 *
 *   - LinePitch: Real length of a line, for the buffer, in bytes.
 *
 *	 - Flags: Not supported for now. Will be for compression adjustment
 *
 *   - RequestedDepth: the depth (in bit) of the encoded picture
 *
 * Return value:
 *
 *   - 0: The encoder has failed
 *   - 1: The encoder has correctly done the job
 *
 **/

static M_PBFUNCTION(integer) Encode(const char *Filename, const char *Buffer, int Width, int Height, int LinePitch, int Flags, int EncoderFlags, int RequestedDepth)
{
	int Result = 0;  // False by default
	int x, y;
	FILE *File;
	const char *SourceCursor;

	// Open the file in write/binary mode
  // there is a separate unicode version only on Windows
  #if defined(UNICODE) && defined(WINDOWS)
    if (File = _wfopen((wchar_t *)Filename, TEXT("wb")))
  #else
    if (File = fopen(Filename, "wb"))
  #endif
	{
		for (y=0; y < Height; y++)
  	{
			SourceCursor = Buffer+y*LinePitch;

			for (x=0; x<Width; x++)
			{
				// Read the pixels here and write it to disk in the desired format
			}
		}

		fclose(File);

		Result = 1;
	}

	return Result;
}


/* The virtual table with the exported PureBasic function.
 *
 * Only the function name and the ID should be modified.
 *
 * The ID will be unique ID of the encoder, which is passed
 * in the SaveImage(#Image, Filename$, EncoderID) function.
 *
 **/

static PB_ImageEncoder ImageEncoder;
static int Registered = 0;

M_PBFUNCTION(integer) PB_UseFAKEImageEncoder()
{
	if (Registered == 0)
	{
		ImageEncoder.ID			  = 'FAKE';
		ImageEncoder.Encode24 = Encode;
		ImageEncoder.Encode32 = 0;       // the ImageEncoder lib will convert 32bit to 24bit

		PB_ImageEncoder_Register(&ImageEncoder);
		Registered = 1;
	}

	return Registered;
}
