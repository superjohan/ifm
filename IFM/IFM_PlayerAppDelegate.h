//
//  IFM_PlayerAppDelegate.h
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IFM-Swift.h"

@class MainViewController;

@interface IFM_PlayerAppDelegate : NSObject <UIApplicationDelegate>

@property (nonatomic, strong) IBOutlet UIWindow *window;
@property (nonatomic, strong) MainViewController *mainViewController;

@end

