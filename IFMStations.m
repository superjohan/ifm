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

@interface IFMStations ()

@property (nonatomic) NSArray *stations;
@property (nonatomic) IFMStationsUpdater *updater;

@end

@implementation IFMStations

#pragma mark - Public

- (instancetype)init {
	if ((self = [super init])) {
		_stations = [[NSArray alloc] init]; // TODO: Read from disk.
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

- (void)updateStations {
	[self.updater updateStationsWithCompletion:^(NSArray<IFMStation *> *stations) {
		if (stations != nil) {
			self.stations = stations;
		}
	}];
}

@end
