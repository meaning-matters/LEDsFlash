//
//  Led.h
//  LEDsFlash
//
//  Created by Kees van der Bent on 16/07/10.
//  Copyright 2010 Software Natural. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface Led : NSObject {
    AVCaptureSession*           capSession;
    AVCaptureDevice*            device;
    NSError*                    error;
    AVCaptureInput*             input;
    AVCaptureStillImageOutput*  output;    
    bool                        state;
}

@property bool  on;

+ (Led*)sharedInstance;

- (void)switchOn;

- (void)switchOff;

@end
