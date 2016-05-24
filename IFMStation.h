//
//  IFMStation.h
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import <Foundation/Foundation.h>

@interface IFMStation : NSObject

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSURL *url;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

@end
