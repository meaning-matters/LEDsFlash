//
//  Led.m
//  LEDsFlash
//
//  Created by Kees van der Bent on 16/07/10.
//  Copyright 2010 Software Natural. All rights reserved.
//

#import "Led.h"

static Led *sharedInstance = nil;



@implementation Led

@synthesize on;


- (void)switchOn
{
    if (!on)
    {
        [device setTorchMode:AVCaptureTorchModeOn]; 
    }
    on = YES;
}


- (void)switchOff
{
    if (on)
    {
        [device setTorchMode:AVCaptureTorchModeOff];
        
    }
    on = NO;
}


// This must be called by user to get hold of LED.
+ (Led*)sharedInstance
{
    
    
    @synchronized(self)
    {
        if (sharedInstance == nil)
            sharedInstance = [[Led alloc] init];
    }
    return sharedInstance;
}


+ (id)allocWithZone:(NSZone *)zone
{
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [super allocWithZone:zone];
            return sharedInstance;  // assignment and return on first allocation
        }
    }
    return nil; // on subsequent allocation attempts return nil
}


- (id)init
{
    if (self = [super init])
    {
        sharedInstance = self;
        
        capSession=[[AVCaptureSession alloc] init];
        device=[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        [device lockForConfiguration:&error];
        [capSession beginConfiguration];
        input=[[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
        output= [[AVCaptureStillImageOutput alloc] init];
        [capSession addInput:input];
        [capSession addOutput:output];
        [capSession commitConfiguration];
        [capSession startRunning];
        
        on = NO;
    }
    
    return sharedInstance;
}


- (id)copyWithZone:(NSZone *)zone
{
    return self;
}


- (id)retain
{
    return self;
}


- (unsigned)retainCount
{
    return UINT_MAX;  // denotes an object that cannot be released
}


- (void)release
{
    // Do nothing.
}


- (id)autorelease
{
    return self;
}

@end
