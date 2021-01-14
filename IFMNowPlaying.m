//
//  IFMNowPlaying.m
//  IFM
//
//  Created by Johan Halin on 02/06/16.
//  Updated by Alessandro Parisi on 24/12/20
//
//

#import "IFMNowPlaying.h"
#import "IFMStation.h"
#import "NSArray+IFMAdditions.h"

@interface IFMNowPlaying ()

@property (nonatomic) BOOL updating;
@property (nonatomic) NSURLSession *session;

@end

@implementation IFMNowPlaying

#pragma mark - Private

- (NSString *)_parseResponse:(NSData *)response
{
	NSError *err = nil;
	NSArray *jsonData = [NSJSONSerialization JSONObjectWithData:response options:NSJSONReadingAllowFragments error:&err];

	NSDictionary *dict = [jsonData objectAtIndexOrNil:0];
	if (!dict) {
		IFMLOG_INFO(@"Error parsing now playing info: %@", err);
		return nil;
	}

	NSString *separator1 = @"-";
	NSString *separator2 = @"|";

	NSString *artist = dict[@"artist"];
	NSString *nowPlaying = artist != nil ? artist : @"";
	nowPlaying = [self _appendStringIfNotEmpty:dict[@"track"] toString:nowPlaying withSeparator:separator1];
	nowPlaying = [self _appendStringIfNotEmpty:dict[@"release"] toString:nowPlaying withSeparator:separator2];
	nowPlaying = [self _appendStringIfNotEmpty:dict[@"label"] toString:nowPlaying withSeparator:separator2];

	NSObject *yearValue = dict[@"year"];
	NSString *year;
	if ([yearValue isKindOfClass:[NSNumber class]]) {
		year = [(NSNumber *)yearValue stringValue];
	} else if ([yearValue isKindOfClass:[NSString class]]) {
		year = (NSString *)yearValue;
	} else {
		year = nil;
	}

	nowPlaying = [self _appendStringIfNotEmpty:year toString:nowPlaying withSeparator:separator2];
	nowPlaying = [self _appendStringIfNotEmpty:dict[@"country"] toString:nowPlaying withSeparator:separator2];

	return nowPlaying;
}

- (NSString *)_appendStringIfNotEmpty:(NSString *)fromString
							 toString:(NSString *)toString
						withSeparator:(NSString *)separator
{
	if (fromString == nil || [[fromString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
	{
		return toString;
	}

	return [NSString stringWithFormat:@"%@ %@ %@", toString, separator, fromString];
}

#pragma mark - Public

- (instancetype)init
{
	if ((self = [super init]))
	{
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.URLCache = nil;
		
		_session = [NSURLSession sessionWithConfiguration:configuration];
	}
	
	return self;
}

- (void)updateNowPlayingWithStation:(IFMStation *)station completion:(void(^)(NSString *nowPlaying))completion
{
	if (self.updating)
	{
		return;
	}
	
	self.updating = YES;
	
	NSURLRequest *request = [NSURLRequest requestWithURL:station.nowPlayingUrl];
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
		NSString *parsedNowPlaying;
		
		if (data != nil)
		{
			parsedNowPlaying = [self _parseResponse:data];
		}
		else
		{
			IFMLOG_INFO(@"%@", error);
			parsedNowPlaying = nil;
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			self.updating = NO;

			completion(parsedNowPlaying);
		});
	}];
	
	[task resume];
}

@end
