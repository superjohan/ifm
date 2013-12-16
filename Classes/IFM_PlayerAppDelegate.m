//
//  IFM_PlayerAppDelegate.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import "IFM_PlayerAppDelegate.h"
#import "MainViewController.h"

@implementation IFM_PlayerAppDelegate

@synthesize window;
@synthesize mainViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    self.mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	self.window.rootViewController = self.mainViewController;
    [self.window makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self.mainViewController resetAnimation];
}


@end
