//
//  MainViewController.h
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "IFM-Swift.h"

@interface MainViewController : UIViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil player:(IFMPlayer *)player;
- (void)resetAnimation;

@end
