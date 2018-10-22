    //
//  InfoViewController.m
//  LEDsDisco
//
//  Created by Kees van der Bent on 19/07/10.
//  Copyright 2010 Software Natural. All rights reserved.
//

#import "InfoViewController.h"


@implementation InfoViewController

@synthesize delegate;

@synthesize infoLabel;


- (IBAction)done:(id)sender
{
	[self.delegate infoViewControllerDidFinish:self];	
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    infoLabel.text = [NSString stringWithFormat:@"Version %@ - LEDsFlash@mail.com", version];
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
