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
    
    NSDictionary *dict = [jsonData objectAtIndex:0];
    
    NSString *sepa1 = @" - ";
    NSString *sepa2 = @" | ";
    NSNumber *yearInt = dict[@"year"];
    NSLog(@"yearInt: %@",yearInt);
    NSString *year = [NSString stringWithFormat:@"%@",yearInt];

    NSString *nowPlaying1 = [dict[@"artist"] stringByAppendingString:[sepa1 stringByAppendingString:dict[@"track"]]];
    NSString *nowPlaying2 = [nowPlaying1 stringByAppendingString:[sepa2 stringByAppendingString:dict[@"release"]]];
    NSString *nowPlaying3 = [nowPlaying2 stringByAppendingString:[sepa2 stringByAppendingString:dict[@"label"]]];
    NSString *nowPlaying4 = [nowPlaying3 stringByAppendingString:[sepa2 stringByAppendingString:year]];
    NSString *nowPlaying5 = [nowPlaying4 stringByAppendingString:[sepa2 stringByAppendingString:dict[@"country"]]];
    
    
    return nowPlaying5;
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
