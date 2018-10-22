#if !defined(__rio_helper_h__)
#define __rio_helper_h__

#include "CAStreamBasicDescription.h"
#include "AudioUnit/AudioUnit.h"


int SetupRemoteIO (AudioUnit& inRemoteIOUnit, AURenderCallbackStruct inRenderProc, CAStreamBasicDescription& outFormat);

class DCRejectionFilter
{
public:
	DCRejectionFilter(Float32 poleDist = DCRejectionFilter::kDefaultPoleDist);

	void InplaceFilter(SInt32* ioData, UInt32 numFrames, UInt32 strides);
	void Reset();

protected:
	
	// Coefficients
	SInt16 mA1;
	SInt16 mGain;

	// State variables
	SInt32 mY1;
	SInt32 mX1;
	
	static const Float32 kDefaultPoleDist;
};

#endif