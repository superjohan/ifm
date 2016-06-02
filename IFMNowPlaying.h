//
//  IFMNowPlaying.h
//  IFM
//
//  Created by Johan Halin on 02/06/16.
//
//

#import <Foundation/Foundation.h>

@class IFMStation;

@interface IFMNowPlaying : NSObject

- (void)updateNowPlayingWithStation:(IFMStation *)station completion:(void(^)(NSString *nowPlaying))completion;

@end
