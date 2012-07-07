//
//  MainViewController.h
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import "FlipsideViewController.h"
#import <QuartzCore/QuartzCore.h>

@class AudioStreamer;

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>

- (void)resetAnimation;

@end
