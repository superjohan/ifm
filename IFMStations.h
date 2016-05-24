//
//  IFMStations.h
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import <Foundation/Foundation.h>

@class IFMStation;

@interface IFMStations : NSObject

@property (nonatomic, readonly) NSInteger numberOfStations;

- (IFMStation *)stationForIndex:(NSInteger)stationIndex;
- (void)updateStations;

@end
