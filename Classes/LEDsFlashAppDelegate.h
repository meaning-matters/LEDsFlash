//
//  LEDsFlashAppDelegate.h
//  LEDsFlash
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#include <libkern/OSAtomic.h>
#include <CoreFoundation/CFURL.h>
#import <AVFoundation/AVFoundation.h>

#import "Helper.h"
#import "CAStreamBasicDescription.h"
#include "AUOutputBL.h"

#import "SettingsDelegate.h"

@class MainViewController;

#define kSampleRate       44100     // Sample rate; may change on new iPhone platform.
#define kFrameNumber        256     // Expected frame number; may change too.

@interface AveragesBuffer : NSObject
{
    float   averages[kSampleRate / kFrameNumber];   // Roughly 1 second.
    int     putIndex;
    int     getIndex;
}

- (void) putAverage:(float)average;

// Gets beat for all averages that came in since last time called.
- (bool) getBeat:(float)beatLevel;

@end


@interface LEDsFlashAppDelegate : NSObject <UIApplicationDelegate, SettingsDelegate>
{
    UIWindow*                   window;
    MainViewController*         mainViewController;
    
	AudioUnit					rioUnit;

	DCRejectionFilter*			dcFilter;
	CAStreamBasicDescription	streamDescription;
	Float64						hwSampleRate;
    
    AURenderCallbackStruct		renderCallbackStruct;

    NSTimer*                    inputTimer;
    
    bool                        beatIt;
    float                       beatLevel;
    
    AUOutputBL*                 inputBuffers;
}

@property (nonatomic, retain) IBOutlet UIWindow*                window;
@property (nonatomic, retain) IBOutlet MainViewController*      mainViewController;

@property (nonatomic, assign)          AudioUnit				rioUnit;
@property (nonatomic, assign)          AURenderCallbackStruct	renderCallbackStruct;

- (void)analyse;

@end

