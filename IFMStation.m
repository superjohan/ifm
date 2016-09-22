//
//  IFMStation.m
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import "IFMStation.h"

@interface IFMStation ()

@property (nonatomic) NSString *name;
@property (nonatomic) NSURL *url;

@end

@implementation IFMStation

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
	if ((self = [super init]))
	{
		_name = dictionary[@"name"];
		_url = [NSURL URLWithString:dictionary[@"url"]];
		_nowPlayingUrl = [NSURL URLWithString:dictionary[@"nowplaying"]];
	}
	
	return self;
}

@end
