//
//  IFMStationsResponseParser.m
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import "IFMStationsResponseParser.h"
#import "IFMStation.h"

@implementation IFMStationsResponseParser

+ (NSArray<IFMStation *> *)parseStationResponse:(NSData *)stationResponse {
	NSError *stationInfoError = nil;
	NSDictionary *stationInfo = [NSJSONSerialization JSONObjectWithData:stationResponse options:0 error:&stationInfoError];
	if (stationInfo == nil) {
		AELOG_INFO(@"%@", stationInfoError);
		
		return nil;
	}
	
	if ([stationInfo isKindOfClass:[NSDictionary class]] == NO) {
		AELOG_INFO(@"stationInfo is not a dictionary");
		
		return nil;
	}
	
	NSArray *stationDicts = stationInfo[@"stations"];
	if (stationDicts == nil || [stationDicts isKindOfClass:[NSArray class]] == NO) {
		AELOG_INFO(@"stationDicts is nil or not an array: %@", stationDicts);
		
		return nil;
	}
	
	NSMutableArray *stations = [[NSMutableArray alloc] init];
	
	for (NSDictionary *stationDict in stationDicts) {
		if ([stationDict isKindOfClass:[NSDictionary class]] == NO) {
			AELOG_INFO(@"station info is not a dictionary: %@", stationDict);
			
			continue;
		}
		
		IFMStation *station = [[IFMStation alloc] initWithDictionary:stationDict];
		[stations addObject:station];
	}
	
	return [NSArray arrayWithArray:stations];
}

@end
