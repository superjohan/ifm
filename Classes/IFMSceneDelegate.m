//
//  IFMSceneDelegate.m
//  IFM
//
//  Created by Johan Halin on 30.10.2023.
//

#import "IFMSceneDelegate.h"
#import "MainViewController.h"

@interface IFMSceneDelegate ()
@property (nonatomic) UIWindow *window;
@property (nonatomic) MainViewController *mainViewController;
@end

@implementation IFMSceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
	UIWindowScene *windowScene = (UIWindowScene *)scene;
	UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
	
	self.window = window;
	self.mainViewController = [[MainViewController alloc] initWithNibName:@"MainView" bundle:nil];

	self.window.rootViewController = self.mainViewController;
	[self.window makeKeyAndVisible];
}

- (void)sceneWillEnterForeground:(UIScene *)scene
{
	[self.mainViewController resetAnimation];
}

@end
