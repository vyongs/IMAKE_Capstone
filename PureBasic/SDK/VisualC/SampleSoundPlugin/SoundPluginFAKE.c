/* Sound decoder plugin sample
 */

#include "SoundPluginFAKE.h"


static PB_SoundDecoderFunctions SoundDecoderFunctions;
static int Registered = 0;

typedef struct PB_Fake
{
  FILE* File;
  int NbChannels;
  int NbSamples;
  int Rate;
} PB_Fake;



static M_PBFUNCTION(integer) Decode(PB_Fake *Fake, char *OutputBuffer, int Length, int Format, int Flags)
{
  // OutputBuffer is a 16bit, 44khz output buffer
  // Length is the length (in bytes) of the output buffer
  // Format is ignored for now
  // Flags is the PlaySound() flags
  
  MessageBox(0, "Decode", "SoundPluginFAKE", 0);
  
  return 1000; // return the processed length. 
}


static M_PBFUNCTION(PB_Fake *) Create(FILE *File, const char *Memory, int MemoryLength, int Flags)
{
  PB_Fake *Fake = 0;
  
  MessageBox(0, "Create", "SoundPluginFAKE", 0);
 
  if (Fake = M_Alloc(sizeof(PB_Fake)))
  {
    // Flags are ignored for now
  
    if (File) // We have an open file handle, so it's read from a file. Use the standard fread() and such function. The handle remains valid until the Free function is called
    {
    }
    else // Direct decoding from memory
    {
      // Here Memory and MemoryLength are valid
    }
    
    Fake->File = File;
    Fake->NbChannels = 2;
    Fake->NbSamples = 1000;
    Fake->Rate = 44100;
  }
  
  return Fake; // if we return non zero, then the sound is handled by this plugin, if not the next registered plugin will be tested
}


static M_PBFUNCTION(integer) GetNbChannels(PB_Fake *Fake)
{
  return Fake->NbChannels;
}


static M_PBFUNCTION(integer) GetNbSamples(PB_Fake *Fake)
{
  return Fake->NbSamples;
}


static M_PBFUNCTION(integer) GetRate(PB_Fake *Fake)
{
  return Fake->Rate;
}

static M_PBFUNCTION(void) Stop(PB_Fake *Fake)
{
  // Stop the sound
}

static M_PBFUNCTION(void) Free(PB_Fake *Fake)
{
  MessageBox(0, "Free", "SoundPluginFAKE", 0);

  // Do your free routine here.
  
  // you need to close the file if a file was used.
  if (Fake->File)
  {
    fclose(Fake->File);
  }
    
  M_Free(Fake);
}


M_PBFUNCTION(void) PB_UseFAKESoundDecoder()
{
  if (Registered == 0)
  {
    SoundDecoderFunctions.Create         = (SoundDecoderCreateType)Create;
    SoundDecoderFunctions.Decode         = (SoundDecoderDecodeType)Decode;
    SoundDecoderFunctions.Stop           = (SoundDecoderStopType)Stop;
    SoundDecoderFunctions.GetNbChannels  = (SoundDecoderGetNbChannelsType)GetNbChannels;
    SoundDecoderFunctions.GetNbSamples   = (SoundDecoderGetNbSamplesType)GetNbSamples;
    SoundDecoderFunctions.GetRate        = (SoundDecoderGetRateType)GetRate;
    SoundDecoderFunctions.Free           = (SoundDecoderFreeType)Free;

    PB_SoundDecoder_Register(&SoundDecoderFunctions);
    Registered = 1;
  }
}
