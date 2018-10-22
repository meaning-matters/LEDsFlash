//
//  FlipsideViewController.m
//  LEDsDisco
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
//

#import "FlipsideViewController.h"
#import "InfoViewController.h"


@implementation FlipsideViewController

@synthesize delegate;
@synthesize beatSwitch;
@synthesize beatSlider;
@synthesize shakeSwitch;
@synthesize shakeSlider;
@synthesize tapSwitch;
@synthesize tapSlider;
@synthesize moveSwitch;
@synthesize moveSlider;

@synthesize preferenceSwitch;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];   
    
    [beatSwitch setOn:[delegate getBeatIt]];
    [beatSlider setValue:[delegate getBeatLevel]];
    [shakeSwitch setOn:[delegate getShakeIt]];
    [shakeSlider setValue:[delegate getShakeSensitivity]];
    [tapSwitch setOn:[delegate getTapIt]];
    [tapSlider setValue:[delegate getTapDuration]];
    [moveSwitch setOn:[delegate getMoveIt]];
    [moveSlider setValue:[delegate getMoveFrequency]];
    
    [preferenceSwitch setOn:[delegate getLedPreference]];
}


- (IBAction)done:(id)sender
{
	[self.delegate flipsideViewControllerDidFinish:self];	
}


- (IBAction)showInfo:(id)sender 
{    
	InfoViewController *controller = [[InfoViewController alloc] initWithNibName:@"InfoView" bundle:nil];
	controller.delegate = self;
    
    //controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (IBAction)beatSwitchChanged
{
    [self.delegate setBeatIt:beatSwitch.on];
}


- (IBAction)beatSliderChanged
{    
    [self.delegate setBeatLevel:beatSlider.value];
}


- (IBAction)shakeSwitchChanged;
{
    [self.delegate setShakeIt:shakeSwitch.on];
}


- (IBAction)shakeSliderChanged
{    
    [self.delegate setShakeSensitivity:shakeSlider.value];
}


- (IBAction)tapSwitchChanged;
{
    [self.delegate setTapIt:tapSwitch.on];
}


- (IBAction)tapSliderChanged
{    
    [self.delegate setTapDuration:tapSlider.value];
}


- (IBAction)moveSwitchChanged
{
    [self.delegate setMoveIt:moveSwitch.on];
}


- (IBAction)moveSliderChanged
{    
    [self.delegate setMoveFrequency:moveSlider.value];
}


- (void)infoViewControllerDidFinish:(InfoViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (IBAction)preferenceSwitchChanged
{
    [self.delegate setLedPreference:preferenceSwitch.on];
}


- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc
{
    [super dealloc];
}


@end
