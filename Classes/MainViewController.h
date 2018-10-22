//
//  MainViewController.h
//  LEDsDisco
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
//

#import <CoreMotion/CMMotionManager.h>
#import "FlipsideViewController.h"
#import "Led.h"
#import "SettingsDelegate.h"

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>
{
    bool                        beatIt;
    float                       beatLevel;
    bool                        shakeIt;
    float                       shakeSensitivity;
    bool                        tapIt;
    float                       tapDuration;
    bool                        moveIt;
    float                       moveFrequency;  // Is actually the inverse.
    bool                        ledPreference;
    NSString*                   version;
    
    NSUserDefaults*             settings;
    
    UILabel*                    beatLabel;
    UILabel*                    shakeLabel;
    UILabel*                    tapLabel;
    UILabel*                    moveLabel;    
    
    UILabel*                    selectInputLabel;

    Led*                        led;
    
    NSTimer*                    ledOnTimer;
    
    NSTimer*                    motionTimer;
    
    id <SettingsDelegate>       settingsDelegate;
    
    CMMotionManager*            motionManager;
    
    InputSource                 sources;
}

- (IBAction)showSettings:(id)sender;

- (void)updateLabels;

- (void)switchLedOn:(InputSource)source;

- (void)switchLedOff:(InputSource)source;


@property (nonatomic, retain) IBOutlet UILabel*     beatLabel;
@property (nonatomic, retain) IBOutlet UILabel*     shakeLabel;
@property (nonatomic, retain) IBOutlet UILabel*     tapLabel;
@property (nonatomic, retain) IBOutlet UILabel*     moveLabel;

@property (nonatomic, retain) IBOutlet UILabel*     selectInputLabel;

@property (nonatomic, assign) id <SettingsDelegate> settingsDelegate;

@property (assign) InputSource                      sources;

@end
