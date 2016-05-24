//
//  IFMStationsUpdater.m
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import "IFMStationsUpdater.h"
#import "IFMStationsResponseParser.h"

static NSString * const IFMStationsListURL = @"https://technopop.pp.fi/ifm/stations.json";

@interface IFMStationsUpdater () <NSURLSessionDataDelegate>

@property (nonatomic) BOOL downloading;
@property (nonatomic) NSURLSession *session;

@end

@implementation IFMStationsUpdater

#pragma mark - Public

- (instancetype)init {
	if ((self = [super init])) {
		NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		configuration.URLCache = nil;
		
		_session = [NSURLSession sessionWithConfiguration:configuration];
	}
	
	return self;
}

- (void)updateStationsWithCompletion:(void(^)(NSArray<IFMStation *> *stations))completion {
	if (self.downloading) {
		return;
	}
	
	self.downloading = YES;
	
	NSURL *url = [NSURL URLWithString:IFMStationsListURL];
	NSURLRequest *request = [NSURLRequest requestWithURL:url];
	NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * __nullable data, NSURLResponse * __nullable response, NSError * __nullable error) {
		if (data != nil) {
			NSArray<IFMStation *> *stations = [IFMStationsResponseParser parseStationResponse:data];
			completion(stations);
		} else {
			AELOG_INFO(@"%@", error);

			completion(nil);
		}
	}];
	
	[task resume];
}

@end
