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
	[TestFlight takeOff:@"f0fecfba73bb54d020763779a78a67cb_MjAxMjgyMDExLTExLTIwIDA3OjMyOjE5LjM4NzYxMg"];
	[TestFlight setOptions:@{@"logToConsole": @(NO)}];
	
	self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
    self.mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	[self.window addSubview:self.mainViewController.view];
    [self.window makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[self.mainViewController resetAnimation];
}


@end
