//
//  MainViewController.h
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import "FlipsideViewController.h"
#import <QuartzCore/QuartzCore.h>

@class AudioStreamer;

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate>

- (IBAction)showInfo;
- (IBAction)channel1ButtonPressed:(id)sender;
- (IBAction)channel2ButtonPressed:(id)sender;
- (IBAction)channel3ButtonPressed:(id)sender;
- (IBAction)channel4ButtonPressed:(id)sender;
- (IBAction)stopButtonPressed:(id)sender;
- (void)createStreamer;
- (void)destroyStreamer;
- (void)resetEverything;
- (void)updateNowPlaying;
- (void)synchronousLoadNowPlayingData;
- (void)updateNowPlayingLabel:(NSString *)track;
- (void)resetAnimation;
- (void)playSavedChannel;

@end
