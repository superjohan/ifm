//
//  IFMStationsResponseParser.h
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import <Foundation/Foundation.h>

@class IFMStation;

@interface IFMStationsResponseParser : NSObject

+ (NSArray<IFMStation *> *)parseStationResponse:(NSData *)stationResponse;

@end
