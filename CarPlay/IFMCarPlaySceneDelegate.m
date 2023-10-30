//
//  IFMCarPlaySceneDelegate.m
//  IFM
//
//  Created by Johan Halin on 30.10.2023.
//

#import "IFMCarPlaySceneDelegate.h"

@interface IFMCarPlaySceneDelegate ()
@property (nonatomic) CPInterfaceController *interfaceController;
@end

@implementation IFMCarPlaySceneDelegate

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene didConnectInterfaceController:(CPInterfaceController *)interfaceController
{
	self.interfaceController = interfaceController;
	
	// TODO: we need an IFMStations instance here, and it has to be the one used by the view controller.
	// create it in the scene delegate and pass it it to the view controller, and also create some mechanism
	// for global properties, as shitty as that may sound
	
	NSArray *items = @[
		[[CPListItem alloc] initWithText:@"Station 1" detailText:nil],
		[[CPListItem alloc] initWithText:@"Station 2" detailText:nil],
		[[CPListItem alloc] initWithText:@"Station 3" detailText:nil]
	];
	
	NSArray *sections = @[
		[[CPListSection alloc] initWithItems:items]
	];
	
	CPListTemplate *listTemplate = [[CPListTemplate alloc] initWithTitle:@"IFM"
																sections:sections];
	
	[self.interfaceController setRootTemplate:listTemplate animated:YES];
}

- (void)templateApplicationScene:(CPTemplateApplicationScene *)templateApplicationScene didDisconnectInterfaceController:(CPInterfaceController *)interfaceController
{
	
}

@end
