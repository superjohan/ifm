//
//  IFMNowPlaying.m
//  IFM
//
//  Created by Johan Halin on 02/06/16.
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
	NSString *nowPlayingString = [[NSString alloc] initWithData:response encoding:NSUTF8StringEncoding];
	nowPlayingString = [nowPlayingString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	NSArray *lines = [nowPlayingString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	return [lines objectAtIndexOrNil:2];
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
