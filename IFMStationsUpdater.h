//
//  IFMStationsUpdater.h
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import <Foundation/Foundation.h>

@class IFMStation;

@interface IFMStationsUpdater : NSObject

- (void)updateStationsWithCompletion:(void(^)(NSArray<IFMStation *> *stations, NSData *data))completion;

@end
