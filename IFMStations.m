//
//  IFMStations.m
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import "IFMStations.h"
#import "AENSArrayAdditions.h"
#import "IFMStationsUpdater.h"
#import "IFMStationsResponseParser.h"

@interface IFMStations ()

@property (nonatomic) NSArray *stations;
@property (nonatomic) IFMStationsUpdater *updater;

@end

@implementation IFMStations

#pragma mark - Private

- (NSString *)_stationsFilePath {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = paths[0];
	NSString *stationsFilePath = [path stringByAppendingPathComponent:@"stations.json"];
	
	return stationsFilePath;
}

- (NSArray *)_loadStations {
	NSString *stationsPath = [self _stationsFilePath];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:stationsPath] == NO) {
		NSString *bundledStationsPath = [[NSBundle mainBundle] pathForResource:@"stations" ofType:@"json"];
		NSError *error = nil;
		if ([[NSFileManager defaultManager] copyItemAtPath:bundledStationsPath toPath:stationsPath error:&error] == NO) {
			AELOG_INFO(@"%@", error);
		}
	}
	
	NSData *data = [[NSData alloc] initWithContentsOfFile:stationsPath];
	
	return [IFMStationsResponseParser parseStationResponse:data];
}

#pragma mark - Public

- (instancetype)init {
	if ((self = [super init])) {
		_stations = [self _loadStations];
		_updater = [[IFMStationsUpdater alloc] init];
	}
	
	return self;
}

- (NSInteger)numberOfStations {
	return self.stations.count;
}

- (IFMStation *)stationForIndex:(NSInteger)stationIndex {
	return [self.stations objectAtIndexOrNil:stationIndex];
}

- (NSInteger)indexForStation:(IFMStation *)station {
	return [self.stations indexOfObject:station];
}

- (void)updateStations {
	[self.updater updateStationsWithCompletion:^(NSArray<IFMStation *> *stations, NSData *data) {
		// TODO: Verify that stations have changed.
		
		if (stations != nil) {
			[data writeToFile:[self _stationsFilePath] atomically:YES];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				self.stations = stations;
			});
		}
	}];
}

@end
