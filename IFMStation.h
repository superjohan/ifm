//
//  IFMStation.h
//  IFM
//
//  Created by Johan Halin on 24/05/16.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface IFMStation : NSObject

@property (nonatomic, readonly) NSString * _Nonnull name;
@property (nonatomic, readonly) NSURL * _Nonnull url;
@property (nonatomic, readonly) NSURL * _Nonnull nowPlayingUrl;
@property (nonatomic, readonly) UIImage * _Nonnull artwork;

- (instancetype _Nonnull )initWithDictionary:(NSDictionary *_Nonnull)dictionary NS_DESIGNATED_INITIALIZER;
- (instancetype _Nonnull )init NS_UNAVAILABLE;

@end
