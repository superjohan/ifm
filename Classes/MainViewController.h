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

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	
	IBOutlet UIButton *channel1Button;
	IBOutlet UIButton *channel2Button;
	IBOutlet UIButton *channel3Button;
	IBOutlet UIButton *channel4Button;

	IBOutlet UIButton *channel1StopButton;
	IBOutlet UIButton *channel2StopButton;
	IBOutlet UIButton *channel3StopButton;
	IBOutlet UIButton *channel4StopButton;
		
	IBOutlet UIActivityIndicatorView *channel1Spinner;
	IBOutlet UIActivityIndicatorView *channel2Spinner;
	IBOutlet UIActivityIndicatorView *channel3Spinner;
	IBOutlet UIActivityIndicatorView *channel4Spinner;

	UILabel *nowPlayingLabel;
	
	AudioStreamer *streamer;
	
	NSString *channelSelection;
	NSString *nowPlayingString;
	
	NSInteger channelPlaying;
	NSInteger savedChannelPlaying;
	
	NSOperationQueue *operationQueue;

	CABasicAnimation *scrollText;
	
	NSTimer *nowPlayingTimer;
	
	BOOL busyLoading;
	BOOL playing;

}

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
