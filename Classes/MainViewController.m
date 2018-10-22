//
//  MainViewController.m
//  LEDsDisco
//
//  Created by Kees van der Bent on 12/07/10.
//  Copyright Software Natural 2010. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

@synthesize beatLabel;
@synthesize shakeLabel;
@synthesize tapLabel;
@synthesize moveLabel;
@synthesize selectInputLabel;
@synthesize settingsDelegate;
@synthesize sources;


- (void)analyseMotion
{    
    CMDeviceMotion* motion = motionManager.deviceMotion;
    
    if (motion == nil)
    {
        // The timer may fire a few times before the motion manager is active.
        return;
    }

    if (shakeIt)
    {
        CMAcceleration acceleration = motion.userAcceleration;
        
        double          length;

        // No sqrt() to get a non-linear slider scale.
        length = (acceleration.x * acceleration.x) +
                 (acceleration.y * acceleration.y) +
                 (acceleration.z * acceleration.z);
        
        if (length > -shakeSensitivity)
        {
            [self switchLedOn:INPUT_SOURCE_SHAKE];
        }
        else if (length <= -shakeSensitivity / 5)
        {
            [self switchLedOff:INPUT_SOURCE_SHAKE];
        }
    }
    
    if (moveIt)
    {
        CMAttitude* attitude = motion.attitude;
                
        // Dynamic algorithm which calculates travelled distance.
        static double       totalDistance = 0.0;    // In theory should be reset after very long time.
        static CMQuaternion previousQuaternion;
        CMQuaternion        currentQuaternion;
        double              distance;
        
        currentQuaternion = attitude.quaternion;
        distance = sqrt(pow(currentQuaternion.x - previousQuaternion.x, 2) +
                        pow(currentQuaternion.y - previousQuaternion.y, 2) +
                        pow(currentQuaternion.z - previousQuaternion.z, 2) +
                        pow(currentQuaternion.w - previousQuaternion.w, 2));
        totalDistance += distance;        
        previousQuaternion = currentQuaternion;
        
        // The moveFrequency (which is actually distance), must be negated to
        // get positive value.  Negative values were used as a trick for the
        // slider; this allows the smallest value to be at the right side of
        // the slider.  Alternatively the slider could be frequency, but then
        // the scale of the slider would have become a 1/x function, while
        // lineair --obtained with this negation trick-- is much better.
        if (fmod(totalDistance, -moveFrequency) >= -moveFrequency / 2.0)
        {
            [self switchLedOn:INPUT_SOURCE_MOVE];
        }
        else 
        {
            [self switchLedOff:INPUT_SOURCE_MOVE];
        }                   
    }
}


- (void)enableMotionInput
{
    motionTimer = [NSTimer scheduledTimerWithTimeInterval:1 / 45.0   // Same as accelerometer interval.
                   target:self selector:@selector(analyseMotion)
                   userInfo:nil repeats:YES];
    
    [motionManager startDeviceMotionUpdates];
}


- (void)disableMotionInput
{
    [motionTimer invalidate];
    
    [motionManager stopDeviceMotionUpdates];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[super viewDidLoad];
    
    led = [Led sharedInstance];
    
    version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    // Read settings.
    settings = [NSUserDefaults standardUserDefaults];
    if ([settings stringForKey:@"version"] == nil)
    {
        // First time: Defaults.
        beatIt = true;
        [settings setBool:beatIt forKey:@"beatIt"];
        
        beatLevel = -1.40;          // Used nagative values to get higher value at right side of slider.
        [settings setFloat:beatLevel forKey:@"beatLevel"];
        
        shakeIt = true;
        [settings setBool:shakeIt forKey:@"shakeIt"];
        
        shakeSensitivity = -1.05;   // Used nagative values to get higher value at right side of slider.
        [settings setFloat:shakeSensitivity forKey:@"shakeSensitivity"];
        
        tapIt = true;
        [settings setBool:tapIt forKey:@"tapIt"];
        
        tapDuration = 0.166;
        [settings setFloat:tapDuration forKey:@"tapDuration"];
        
        moveIt = true;
        [settings setBool:moveIt forKey:@"moveIt"];
        
        moveFrequency = -0.54;      // Used nagative values to get higher value at right side of slider.
        [settings setFloat:moveFrequency forKey:@"moveFrequency"];
        
        ledPreference = false;  // Preference for OFF.
        [settings setBool:ledPreference forKey:@"ledPreference"];
        
        // This marks that all default settings were saved.
        [settings setObject:version forKey:@"version"];
        [settings synchronize];
    }
    else
    {
        // Other time.
        beatIt = [settings boolForKey:@"beatIt"];
        beatLevel = [settings floatForKey:@"beatLevel"];
        shakeIt = [settings boolForKey:@"shakeIt"];
        shakeSensitivity = [settings floatForKey:@"shakeSensitivity"];
        tapIt = [settings boolForKey:@"tapIt"];
        tapDuration = [settings floatForKey:@"tapDuration"];
        moveIt = [settings boolForKey:@"moveIt"];
        moveFrequency = [settings floatForKey:@"moveFrequency"];
        ledPreference = [settings boolForKey:@"ledPreference"];
    }
    
    ledOnTimer = nil;
    
    [self updateLabels];
    
    // ### Get rid of this by moving audio code into this module.
    [settingsDelegate setBeatIt:beatIt];
    [settingsDelegate setBeatLevel:beatLevel];
  
    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval = 1 / 45.0;

    if (shakeIt || moveIt)
    {
        [self enableMotionInput];
    }
    
    sources = 0;
}


- (bool)getBeatIt
{
    return beatIt;
}


- (float)getBeatLevel
{
    return beatLevel;
}


- (bool)getShakeIt
{
    return shakeIt;
}


- (float)getShakeSensitivity
{
    return shakeSensitivity;
}


- (bool)getTapIt
{
    return tapIt;
}


- (float)getTapDuration
{
    return tapDuration;
}


- (bool)getMoveIt
{
    return moveIt;
}


- (float)getMoveFrequency
{
    return moveFrequency;
}


- (bool)getLedPreference
{
    return ledPreference;
}


- (void)setBeatIt:(bool)value
{
    beatIt = value;
    [settings setBool:beatIt forKey:@"beatIt"];  
    [self updateLabels];
        
    [settingsDelegate setBeatIt:value]; // ### Remove by moving audio code to this module.

    if (value == NO)
    {
        [self switchLedOff:INPUT_SOURCE_BEAT];        
    }
}


- (void)setBeatLevel:(float)level
{
    beatLevel = level;
    [settings setFloat:beatLevel forKey:@"beatLevel"];
    
    [settingsDelegate setBeatLevel:level];  // ### Remove by moving audio code here.
}


- (void)setShakeIt:(bool)value
{
    shakeIt = value;
    [settings setBool:shakeIt forKey:@"shakeIt"];
    [self updateLabels];

    if (shakeIt == NO && moveIt == NO && motionManager.deviceMotionActive == YES)
    {
        [self disableMotionInput];
    }
    
    if (shakeIt == YES && motionManager.deviceMotionActive == NO)
    {
        [self enableMotionInput];
    }
    
    if (value == NO)
    {
        [self switchLedOff:INPUT_SOURCE_SHAKE];        
    }
}


- (void)setShakeSensitivity:(float)sensitivity
{
    shakeSensitivity = sensitivity;
    [settings setFloat:shakeSensitivity forKey:@"shakeSensitivity"];
}


- (void)setTapIt:(bool)value
{
    tapIt = value;
    [settings setBool:tapIt forKey:@"tapIt"];
    [self updateLabels];

    if (value == NO)
    {
        [self switchLedOff:INPUT_SOURCE_TAP];        
    }
}


- (void)setTapDuration:(float)duration
{
    tapDuration = duration;
    [settings setFloat:tapDuration forKey:@"tapDuration"];
    
    if (tapIt && tapDuration > 0.0)
    {
        [self switchLedOn:INPUT_SOURCE_TAP];
        [ledOnTimer invalidate];
        ledOnTimer = [NSTimer scheduledTimerWithTimeInterval:tapDuration
                      target:self selector:@selector(switchOffTap)
                      userInfo:nil repeats:NO];
    }
}


- (void)setMoveIt:(bool)value
{
    moveIt = value;
    [settings setBool:moveIt forKey:@"moveIt"];
    [self updateLabels];

    if (moveIt == NO && shakeIt == NO && motionManager.deviceMotionActive == YES)
    {
        [self disableMotionInput];
    }
    
    if (moveIt == YES && motionManager.deviceMotionActive == NO)
    {
        [self enableMotionInput];
    }
    
    if (value == NO)
    {
        [self switchLedOff:INPUT_SOURCE_MOVE];        
    }
}


- (void)setMoveFrequency:(float)frequency
{
    moveFrequency = frequency;
    [settings setFloat:moveFrequency forKey:@"moveFrequency"];
}


- (void)setLedPreference:(bool)preference
{
    ledPreference = preference;
    [settings setBool:ledPreference forKey:@"ledPreference"];
}


- (void)updateLabels
{
    if (beatIt + shakeIt + tapIt + moveIt == 0)
    {    
        selectInputLabel.hidden = NO;
    }
    else
    {
        selectInputLabel.hidden = YES;    
    }
    
    if (beatIt)
    {
        beatLabel.hidden = NO;
    }
    else
    {
        beatLabel.hidden = YES;
    }    
    
    if (shakeIt)
    {
        shakeLabel.hidden = NO;
    }
    else
    {
        shakeLabel.hidden = YES;
    }    
    
    if (tapIt)
    {
        tapLabel.hidden = NO;
    }
    else
    {
        tapLabel.hidden = YES;
    }    
    
    if (moveIt)
    {
        moveLabel.hidden = NO;
    }
    else
    {
        moveLabel.hidden = YES;
    }    
}


- (void)switchLedOn:(InputSource)source
{
    @synchronized(self)
    {
        if ((sources & source) == 0)
        {
            switch (source)
            {
            case INPUT_SOURCE_BEAT:
                beatLabel.highlighted = YES;            
                break;
                
            case INPUT_SOURCE_SHAKE:
                shakeLabel.highlighted = YES;            
                break;
                
            case INPUT_SOURCE_TAP:
                tapLabel.highlighted = YES;            
                break;

            case INPUT_SOURCE_MOVE:
                moveLabel.highlighted = YES;            
                break;
            }
            
            [led switchOn];

            if (ledPreference == false)
            {
                (source & INPUT_SOURCE_BEAT) == 0 && (beatLabel.highlighted = NO);            
                (source & INPUT_SOURCE_SHAKE) == 0 && (shakeLabel.highlighted = NO);            
                (source & INPUT_SOURCE_TAP) == 0 && (tapLabel.highlighted = NO);            
                (source & INPUT_SOURCE_MOVE) == 0 && (moveLabel.highlighted = NO);            
            }
        }    
        
        sources |= source;
    }
}


- (void)switchLedOff:(InputSource)source
{    
    @synchronized(self)
    {
        if (source == INPUT_SOURCE_TAP)
        {
            ledOnTimer = nil;        
        }

        if ((ledPreference == false && (sources & source) != 0) ||
            (ledPreference == true && (sources & ~source) == 0))
        {
            [led switchOff];
        }
        
        switch (source)
        {
        case INPUT_SOURCE_BEAT:
            beatLabel.highlighted = NO;            
            break;
            
        case INPUT_SOURCE_SHAKE:
            shakeLabel.highlighted = NO;            
            break;
            
        case INPUT_SOURCE_TAP:
            tapLabel.highlighted = NO;            
            break;
            
        case INPUT_SOURCE_MOVE:
            moveLabel.highlighted = NO;            
            break;
        }
        
        sources = sources & ~source;
    }
}


- (void)switchOffTap
{
    [self switchLedOff:INPUT_SOURCE_TAP];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (tapIt)
    {
        [self switchLedOn:INPUT_SOURCE_TAP];
        if (tapDuration > 0.0)
        {
            [ledOnTimer invalidate];
            ledOnTimer = [NSTimer scheduledTimerWithTimeInterval:tapDuration
                          target:self selector:@selector(switchOffTap)
                          userInfo:nil repeats:NO];
        }
    }
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([ledOnTimer isValid] == NO)
    {
        [self switchLedOff:INPUT_SOURCE_TAP];     
    }
}


- (IBAction)showSettings:(id)sender 
{    
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	//controller.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
	[self dismissModalViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload
{
	// Release any retained subviews of the main view.
	
    [settings synchronize];
    
    [motionManager release];
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


- (void)dealloc
{
    [super dealloc];
}


@end
