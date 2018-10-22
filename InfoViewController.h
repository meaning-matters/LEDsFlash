//
//  InfoViewController.h
//  LEDsDisco
//
//  Created by Kees van der Bent on 19/07/10.
//  Copyright 2010 Software Natural. All rights reserved.
//

#import <UIKit/UIKit.h>

@class InfoViewController;

@protocol InfoViewControllerDelegate
- (void)infoViewControllerDidFinish:(InfoViewController *)controller;
@end

@interface InfoViewController : UIViewController
{
	id <InfoViewControllerDelegate> delegate;
    
    UILabel*                        infoLabel;
}

@property (nonatomic, assign) id <InfoViewControllerDelegate>   delegate;

@property (nonatomic, retain) IBOutlet UILabel*                 infoLabel;

- (IBAction)done:(id)sender;

@end
