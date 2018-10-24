//
//  LEDsFlashAppDelegate.m
//  LEDsFlash
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
//

#import "LEDsFlashAppDelegate.h"
#import "MainViewController.h"
#import "AudioUnit/AudioUnit.h"
#import "AudioToolbox/AudioToolbox.h"
#import "CAXException.h"
#import "BTrack.h"

AveragesBuffer* averagesBuffer;

// https://stackoverflow.com/a/51282039/1971013
static int hopSize = 512;
static int frameSize = 1024;

BTrack btrack(hopSize, frameSize);
double btrackFrame[1024];
int btrackIndex = 0;

@implementation AveragesBuffer
- (void)putAverage:(float)average
{
    int         capacity = kSampleRate / kFrameNumber;
    static bool isFull = NO;

    @synchronized (self)
    {
        if (isFull == NO && ((putIndex + 1) % capacity) == getIndex)
        {
            NSLog(@"AveragesBuffer is full, skip.\n");
            isFull = YES;
        }
        else
        {
            averages[putIndex] = average;
            putIndex = (putIndex + 1) % capacity;
            isFull = NO;
        }
    }
}


- (bool)getBeat:(float)beatLevel
{
    static  bool    previousBeat;
    bool            beat;
    int             capacity = kSampleRate / kFrameNumber;
    
    @synchronized (self)
    {
#define VERSION_A
        
#ifdef  VERSION_A        
        static float previousSampleAverage;
        if (putIndex == getIndex)
        {
            beat = previousBeat;    // ### This happens sometimes, why.  Because isFull never happens.
        }        
        else
        {
            int     size;
            float   totalAverage = 0.0;
            float   sampleAverage = 0.0;
            
            for (int index = 0; index < capacity; index++)
            {
                totalAverage += averages[index];
            }
            totalAverage /= capacity;

            if (putIndex > getIndex)
            {
                size = putIndex - getIndex;

                if (size < 4)
                {
                    return previousBeat;
                }
                
                for (getIndex; getIndex < putIndex; getIndex++)
                {
                    sampleAverage += averages[getIndex];
                }
                sampleAverage /= size;
            }                
            else
            {
                size = putIndex + capacity - getIndex;
                
                if (size < 4)
                {
                    return previousBeat;
                }

                for (getIndex; (getIndex + 1) % capacity != putIndex; getIndex = (getIndex + 1) % capacity)
                {
                    sampleAverage += averages[getIndex];
                }
                sampleAverage /= size;
            }
            
            // Calculate variance.
            float variance = 0.0;
            for (int index = 0; index < capacity; index++)
            {
              //  variance += (averages[index] / totalAverage - 1.0) * (averages[index] / totalAverage - 1.0);
            }
            //variance /= capacity;
            
            
            beat = sampleAverage > ((-beatLevel + 0.05) * totalAverage);

            if (beat)
            {
             //   printf("V=%f  sqrt(V)=%f log(V)=%f F=%f \n", variance, sqrt(variance), log(variance), sampleAverage / totalAverage);
                
            }
            
            float   hysteresisFactor = 1.0 + (-beatLevel / 10);
            if (beat == NO && previousBeat == YES)
            {
                if (sampleAverage >= previousSampleAverage / hysteresisFactor)
                {
                    // Keep beat on, as the average has not dropped below the hysteresis.
                    beat = YES;
                }
            }
            previousBeat = beat;
            previousSampleAverage = sampleAverage;
            
           // NSLog(@"size == %d %s\n", size, size > 4 ? "+++" : size < 4 ? "---" : "   ");
        }
#endif
            
#ifdef  VERSION_B
        if (putIndex == getIndex)
        {
            beat = NO;
        }        
        else
        {
            int     size;
            float   totalAverage = 0.0;
            
            for (int index = 0; index < capacity; index++)
            {
                totalAverage += averages[index];
            }
            totalAverage /= capacity;
            
            if (putIndex > getIndex)
            {
                size = putIndex - getIndex;
                
                if (size < 2)
                {
                    return previousBeat;
                }
                
                int count = 0;
                for (getIndex; count < 2 && getIndex < putIndex; getIndex++)
                {
                    count += (previousBeat = beat = averages[getIndex] > (-beatLevel * totalAverage));
                    if (beat == NO)
                    {
                        count = 0;
                    }
                }
            }                
            else
            {
                size = putIndex + capacity - getIndex;
                
                if (size < 2)
                {
                    return previousBeat;
                }
                
                int count = 0;
                for (getIndex; count < 2 && (getIndex + 1) % capacity != putIndex; getIndex = (getIndex + 1) % capacity)
                {
                    count += (previousBeat = beat = averages[getIndex] > (-beatLevel * totalAverage));
                    if (beat == NO)
                    {
                        count = 0;
                    }
                }
            }
        }        
#endif
    }    
    
    return beat;
}
@end



@implementation LEDsFlashAppDelegate

@synthesize window;
@synthesize mainViewController;

@synthesize rioUnit;
@synthesize renderCallbackStruct;

#pragma mark -Audio Session Interruption Listener


void rioInterruptionListener(void *inClientData, UInt32 inInterruption)
{
	printf("Session interrupted! --- %s ---", inInterruption == kAudioSessionBeginInterruption ? "Begin Interruption" : "End Interruption");
	
	LEDsFlashAppDelegate*   appDelegate = (LEDsFlashAppDelegate*)inClientData;
	
	if (inInterruption == kAudioSessionEndInterruption)
    {
		// make sure we are again the active session
		AudioSessionSetActive(true);
		AudioOutputUnitStart(appDelegate->rioUnit);
	}
	
	if (inInterruption == kAudioSessionBeginInterruption)
    {
		AudioOutputUnitStop(appDelegate->rioUnit);
    }
}


#pragma mark -Audio Session Property Listener

void audioRouteChangeListener(
    void *                  inClientData,
    AudioSessionPropertyID  inID,
    UInt32                  inDataSize,
    const void *            inData)
{
	LEDsFlashAppDelegate*   appDelegate = (LEDsFlashAppDelegate*)inClientData;
    
	if (inID == kAudioSessionProperty_AudioRouteChange)
	{
		try
        {
			// if there was a route change, we need to dispose the current rio unit and create a new one
			XThrowIfError(AudioComponentInstanceDispose(appDelegate->rioUnit), "couldn't dispose remote i/o unit");		
            
			SetupRemoteIO(appDelegate->rioUnit, appDelegate->renderCallbackStruct, appDelegate->streamDescription);
			
			UInt32 size = sizeof(appDelegate->hwSampleRate);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &appDelegate->hwSampleRate), "couldn't get new sample rate");
            
			XThrowIfError(AudioOutputUnitStart(appDelegate->rioUnit), "couldn't start unit");
            
			CFStringRef newRoute;
			size = sizeof(CFStringRef);
			XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &size, &newRoute), "couldn't get new audio route");
			if (newRoute)
			{	
				CFShow(newRoute);
			}
		}
        catch (CAXException e)
        {
			char buf[256];
			fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		}
		
	}
}


#pragma mark -RIO Render Callback

static OSStatus	renderAudio(
    void						*inRefCon, 
    AudioUnitRenderActionFlags 	*ioActionFlags, 
    const AudioTimeStamp 		*inTimeStamp, 
    UInt32 						inBusNumber, 
    UInt32 						inNumberFrames, 
    AudioBufferList 			*ioData)
{
	LEDsFlashAppDelegate*   appDelegate = (LEDsFlashAppDelegate*)inRefCon;
	OSStatus                err = 0;
    int                     i;
    SInt8*                  data_ptr;

    if (appDelegate->inputBuffers == nil)
    {
        return 0;
    }
    else
    {
        ioData = appDelegate->inputBuffers->ABL();
    }

    
    appDelegate->inputBuffers->Prepare(inNumberFrames);
    
    err = AudioUnitRender(appDelegate->rioUnit, ioActionFlags, inTimeStamp, 1,
                          inNumberFrames, ioData);
	if (err)
    {
        printf("renderAudio: error %d\n", (int)err); return err;
    }
	
	// Remove DC component.
	for(UInt32 i = 0; appDelegate->dcFilter != nil && i < ioData->mNumberBuffers; ++i)
    {
		appDelegate->dcFilter[i].InplaceFilter((SInt32*)(ioData->mBuffers[i].mData), inNumberFrames, 1);        
    }

    // ### We assume 256 frames.
    if (inNumberFrames != 256)
    {
        NSLog(@"Number of frames %u != 256.", (unsigned int)inNumberFrames);
    }
    
    float   average = 0.0;
    data_ptr = (SInt8 *)(ioData->mBuffers[0].mData);
    UInt32 *uint32_ptr = (UInt32 *)(ioData->mBuffers[0].mData);
    for (i = 0; i < inNumberFrames; i++)
    {
        float   sample;
        
        sample = data_ptr[2];
        data_ptr += 4;

        average += (sample * sample);

        btrackFrame[btrackIndex++] = (double)((SInt16)(uint32_ptr[i] >> 9)) / 32768.0;
    }
    average /= inNumberFrames;
    
    [averagesBuffer putAverage:average];

    if (btrackIndex == frameSize)
    {
        btrack.processAudioFrame(btrackFrame);
        if (btrack.beatDueInCurrentFrame())
        {
            [appDelegate.mainViewController switchLedOn:INPUT_SOURCE_BEAT];
        }
        else
        {
            [appDelegate.mainViewController switchLedOff:INPUT_SOURCE_BEAT];
        }
        
        //  memmove(uint32_ptr, &uint32_ptr[frameSize - hopSize], sizeof(UInt32) * frameSize - hopSize);
        
        btrackIndex = frameSize - hopSize;
    }

	return err;
}


- (void)analyse
{	
    if (!beatIt)
    {
        return;
    }
    
	
    if ([averagesBuffer getBeat:beatLevel])
    {
        [mainViewController switchLedOn:INPUT_SOURCE_BEAT];
    }
    else
    {
        [mainViewController switchLedOff:INPUT_SOURCE_BEAT];
    }
}


- (void)setBeatIt:(bool)value
{
    beatIt = value;
}


- (void)setBeatLevel:(float)level
{
    beatLevel = level;
}


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
    averagesBuffer = [[AveragesBuffer alloc] init];
    
	CFURLRef url = NULL;
	try
    {
        // Initialize and configure the audio session
		XThrowIfError(AudioSessionInitialize(NULL, NULL, rioInterruptionListener, self), "couldn't initialize audio session");

		//UInt32 audioCategory = kAudioSessionCategory_RecordAudio;
		UInt32 audioCategory = kAudioSessionCategory_PlayAndRecord;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(audioCategory), &audioCategory), "couldn't set audio category");
        
        UInt32 value = TRUE;
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(value), &value);
        AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(value), &value);
        
        XThrowIfError(AudioSessionAddPropertyListener(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListener, self), "couldn't set property listener");

		Float32 preferredBufferSize = .005;
		XThrowIfError(AudioSessionSetProperty(kAudioSessionProperty_PreferredHardwareIOBufferDuration, sizeof(preferredBufferSize), &preferredBufferSize), "couldn't set i/o buffer duration");

        XThrowIfError(AudioSessionSetActive(true), "couldn't set audio session active\n");
        
		UInt32 size = sizeof(hwSampleRate);
		XThrowIfError(AudioSessionGetProperty(kAudioSessionProperty_CurrentHardwareSampleRate, &size, &hwSampleRate), "couldn't get hw sample rate");
		
        UInt32 maxFPS = 1024;   // ### Shouldn't this be 256, because we assume this at rendering.
        
        renderCallbackStruct.inputProc = renderAudio;
        renderCallbackStruct.inputProcRefCon = self;
		XThrowIfError(SetupRemoteIO(rioUnit, renderCallbackStruct, streamDescription), "couldn't setup remote i/o unit");
        inputBuffers = new AUOutputBL(streamDescription, maxFPS);

		size = sizeof(streamDescription);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamDescription, &size), "couldn't get the remote I/O unit's output client format");
        
		size = sizeof(maxFPS);
        XThrowIfError(AudioUnitSetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, size), "couldn't set maximum slice");
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_MaximumFramesPerSlice, kAudioUnitScope_Global, 0, &maxFPS, &size), "couldn't get the remote I/O unit's max frames per slice");
		
		size = sizeof(streamDescription);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamDescription, &size), "couldn't get the remote I/O unit's output client format");

		XThrowIfError(AudioOutputUnitStart(rioUnit), "couldn't start remote i/o unit");
        
		size = sizeof(streamDescription);
		XThrowIfError(AudioUnitGetProperty(rioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &streamDescription, &size), "couldn't get the remote I/O unit's output client format");

        dcFilter = new DCRejectionFilter[streamDescription.NumberChannels()];
	}
	catch (CAXException &e)
    {
		char buf[256];
		fprintf(stderr, "Error: %s (%s)\n", e.mOperation, e.FormatError(buf));
		if (dcFilter)
        {
            delete[] dcFilter;
        }
        
        if (inputBuffers)
        {
            delete inputBuffers;
        }
        
		if (url)
        {
            CFRelease(url);
        }
	}
	catch (...)
    {
		fprintf(stderr, "An unknown error occurred\n");
		if (dcFilter)
        {
            delete[] dcFilter;
        }
        
        if (inputBuffers)
        {
            delete inputBuffers;
        }
        
		if (url)
        {
            CFRelease(url);
        }
	}

    inputTimer = [NSTimer scheduledTimerWithTimeInterval:1 / 60.0
                  target:self selector:@selector(analyse)
                  userInfo:nil repeats:YES];
    
    mainViewController.settingsDelegate = self;
    
    // Add the main view controller's view to the window and display.
    window.rootViewController = mainViewController;
    [window makeKeyAndVisible];

    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, called instead of applicationWillTerminate: when the user quits.
     */
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of  transition from the background to the inactive state: here you can undo many of the changes made on entering the background.
     */
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     See also applicationDidEnterBackground:.
     */
}


#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
}


- (void)dealloc
{
    delete[] dcFilter;
    
    [mainViewController release];
    [window release];
    [super dealloc];
}

@end
