//
//  IFM_PlayerAppDelegate.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import "IFM_PlayerAppDelegate.h"
#import "MainViewController.h"

@implementation IFM_PlayerAppDelegate


@synthesize window;
@synthesize mainViewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{    
	[TestFlight takeOff:@"f0fecfba73bb54d020763779a78a67cb_MjAxMjgyMDExLTExLTIwIDA3OjMyOjE5LjM4NzYxMg"];
	[TestFlight setOptions:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO] forKey:@"logToConsole"]];
	
	MainViewController *aController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];
	self.mainViewController = aController;
	[aController release];
	
    mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
	[window addSubview:[mainViewController view]];
    [window makeKeyAndVisible];
	
	return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	[mainViewController resetAnimation];
}


- (void)dealloc {
    [mainViewController release];
    [window release];
    [super dealloc];
}

@end
