#include <AudioToolbox/AudioToolbox.h>
#include <AudioUnit/AudioUnit.h>
#include <stdio.h>

#include "CAXException.h"
#include "CAStreamBasicDescription.h"
#include "Helper.h"

int SetupRemoteIO(AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat)
{	
	try
    {
		// Open the output unit
		AudioComponentDescription desc;
		desc.componentType = kAudioUnitType_Output;
		desc.componentSubType = kAudioUnitSubType_RemoteIO;
		desc.componentManufacturer = kAudioUnitManufacturer_Apple;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		AudioComponent comp = AudioComponentFindNext(NULL, &desc);
		
		XThrowIfError(AudioComponentInstanceNew(comp, &inRemoteIOUnit), "couldn't open the remote I/O unit");

		UInt32 one = 1;
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Input, 1, &one, sizeof(one)),
                      "couldn't enable input on the remote I/O unit");
        
        UInt32 zero = 0;
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_EnableIO,
                                           kAudioUnitScope_Output, 0, &zero, sizeof(zero)),
                      "couldn't disable output on the remote I/O unit");

        XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioOutputUnitProperty_SetInputCallback,
                                           kAudioUnitScope_Global, 0, &inRenderProc, sizeof(inRenderProc)),
                      "couldn't set input callback");
        
        /*
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_SetRenderCallback,
                                           kAudioUnitScope_Input, 0, &inRenderProc, sizeof(inRenderProc)),
                      "couldn't set remote i/o render callback");
		*/
        
        // set our required format - Canonical AU format: LPCM non-interleaved 8.24 fixed point
        outFormat.SetAUCanonical(2, false);
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Input, 0, &outFormat, sizeof(outFormat)),
                      "couldn't set the remote I/O unit's output client format");
        
		XThrowIfError(AudioUnitSetProperty(inRemoteIOUnit, kAudioUnitProperty_StreamFormat,
                                           kAudioUnitScope_Output, 1, &outFormat, sizeof(outFormat)),
                      "couldn't set the remote I/O unit's input client format");

		XThrowIfError(AudioUnitInitialize(inRemoteIOUnit), "couldn't initialize the remote I/O unit");
	}
	catch (CAXException &e)
    {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		return 1;
	}
	catch (...)
    {
		fprintf(stderr, "An unknown error occurred\n");
		return 1;
	}	
	
	return 0;
}


inline SInt32 smul32by16(SInt32 i32, SInt16 i16)
{
#if defined FFF //__arm__
	register SInt32 r;
	asm volatile("smulwb %0, %1, %2" : "=r"(r) : "r"(i32), "r"(i16));
	return r;
#else	
	return (SInt32)(((SInt64)i32 * (SInt64)i16) >> 16);
#endif
}

inline SInt32 smulAdd32by16(SInt32 i32, SInt16 i16, SInt32 acc)
{
#if defined __arm__
	register SInt32 r;
	asm volatile("smlawb %0, %1, %2, %3" : "=r"(r) : "r"(i32), "r"(i16), "r"(acc));
	return r;
#else		
	return ((SInt32)(((SInt64)i32 * (SInt64)i16) >> 16) + acc);
#endif
}

const Float32 DCRejectionFilter::kDefaultPoleDist = 0.975f;

DCRejectionFilter::DCRejectionFilter(Float32 poleDist)
{
	mA1 = (SInt16)((float)(1<<15)*poleDist);
	mGain = (mA1 >> 1) + (1<<14); // Normalization factor: (r+1)/2 = r/2 + 0.5
	Reset();
}

void DCRejectionFilter::Reset()
{
	mY1 = mX1 = 0;	
}

void DCRejectionFilter::InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides)
{
	register SInt32 y1 = mY1, x1 = mX1;
	for (UInt32 i=0; i < numFrames; i++)
	{
		register SInt32 x0, y0;
		x0 = ioData[i*strides];
		y0 = smul32by16(y1, mA1);
		y1 = smulAdd32by16(x0 - x1, mGain, y0) << 1;
		ioData[i*strides] = y1;
		x1 = x0;
	}
	mY1 = y1;
	mX1 = x1;
}
