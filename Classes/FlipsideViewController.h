//
//  FlipsideViewController.h
//  LEDsDisco
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
// view

#import <UIKit/UIKit.h>
#import "InfoViewController.h"

@class FlipsideViewController;


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;

- (bool)getBeatIt;
- (float)getBeatLevel;
- (bool)getShakeIt;
- (float)getShakeSensitivity;
- (bool)getTapIt;
- (float)getTapDuration;
- (bool)getMoveIt;
- (float)getMoveFrequency;
- (bool)getLedPreference;

- (void)setBeatIt:(bool)value;
- (void)setBeatLevel:(float)level;
- (void)setShakeIt:(bool)value;
- (void)setShakeSensitivity:(float)sensitivity;
- (void)setTapIt:(bool)value;
- (void)setTapDuration:(float)duration;
- (void)setMoveIt:(bool)value;
- (void)setMoveFrequency:(float)frequency;
- (void)setLedPreference:(bool)preference;

@end


@interface FlipsideViewController : UIViewController <InfoViewControllerDelegate>
{
	id <FlipsideViewControllerDelegate> delegate;
    
    UISwitch*                           beatSwitch;
    UISlider*                           beatSlider;
    UISwitch*                           shakeSwitch;
    UISlider*                           shakeSlider;
    UISwitch*                           tapSwitch;
    UISlider*                           tapSlider;
    UISwitch*                           moveSwitch;
    UISlider*                           moveSlider;

    UISwitch*                           preferenceSwitch;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate>   delegate;
@property (nonatomic, retain) IBOutlet UISwitch*                    beatSwitch;
@property (nonatomic, retain) IBOutlet UISlider*                    beatSlider;
@property (nonatomic, retain) IBOutlet UISwitch*                    shakeSwitch;
@property (nonatomic, retain) IBOutlet UISlider*                    shakeSlider;
@property (nonatomic, retain) IBOutlet UISwitch*                    tapSwitch;
@property (nonatomic, retain) IBOutlet UISlider*                    tapSlider;
@property (nonatomic, retain) IBOutlet UISwitch*                    moveSwitch;
@property (nonatomic, retain) IBOutlet UISlider*                    moveSlider;

@property (nonatomic, retain) IBOutlet UISwitch*                    preferenceSwitch;

- (IBAction)done:(id)sender;
- (IBAction)beatSwitchChanged;
- (IBAction)beatSliderChanged;
- (IBAction)shakeSwitchChanged;
- (IBAction)shakeSliderChanged;
- (IBAction)tapSwitchChanged;
- (IBAction)tapSliderChanged;
- (IBAction)moveSwitchChanged;
- (IBAction)moveSliderChanged;

- (IBAction)preferenceSwitchChanged;

- (IBAction)showInfo:(id)sender;

@end



