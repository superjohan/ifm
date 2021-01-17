//
//  MainViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import "MainViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>
#import "NSArray+IFMAdditions.h"
#import <AVFoundation/AVFoundation.h>
#import "IFMStations.h"
#import "IFMStation.h"
#import "IFMNowPlaying.h"

@interface MainViewController ()
@property (nonatomic) IBOutlet UIButton *channel1Button;
@property (nonatomic) IBOutlet UIButton *channel2Button;
@property (nonatomic) IBOutlet UIButton *channel3Button;
@property (nonatomic) IBOutlet UIButton *channel1StopButton;
@property (nonatomic) IBOutlet UIButton *channel2StopButton;
@property (nonatomic) IBOutlet UIButton *channel3StopButton;
@property (nonatomic) IBOutlet UIActivityIndicatorView *channel1Spinner;
@property (nonatomic) IBOutlet UIActivityIndicatorView *channel2Spinner;
@property (nonatomic) IBOutlet UIActivityIndicatorView *channel3Spinner;
@property (nonatomic) IBOutlet UIButton *infoButton;
@property (nonatomic) UILabel *nowPlayingLabel;
@property (nonatomic) NSString *nowPlayingString;
@property (nonatomic) NSTimer *nowPlayingTimer;
@property (nonatomic) MPMoviePlayerController *player;
@property (nonatomic) IFMStations *stations;
@property (nonatomic) IFMNowPlaying *nowPlayingUpdater;
@property (nonatomic) IFMStation *currentStation;
@property (nonatomic) NSArray<UIButton *> *playButtons;
@property (nonatomic) NSArray<UIButton *> *stopButtons;
@property (nonatomic) NSArray<UIActivityIndicatorView *> *spinners;
@end

static const NSInteger IFMChannelsMax = 3; // this should come from the feed!

@implementation MainViewController

#pragma mark - Private

- (void)_stopStreamer
{
	if (self.player.playbackState != MPMoviePlaybackStateStopped)
	{
		[self.player stop];
	}

	[self _resetEverything];
}

- (void)_setChannelToWaiting:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self.spinners objectAtIndexOrNil:channel];
	UIButton *playButton = [self.playButtons objectAtIndexOrNil:channel];
	UIButton *stopButton = [self.stopButtons objectAtIndexOrNil:channel];
	
	[spinner startAnimating];
	spinner.hidden = NO;
	playButton.enabled = NO;
	stopButton.hidden = YES;
	stopButton.enabled = NO;
}

- (void)_setChannelToPlaying:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self.spinners objectAtIndexOrNil:channel];
	UIButton *stopButton = [self.stopButtons objectAtIndexOrNil:channel];

	spinner.hidden = YES;
	stopButton.hidden = NO;
	stopButton.enabled = YES;
}

- (void)_playerNotificationReceived:(NSNotification *)notification
{
	if (self.player.playbackState == MPMoviePlaybackStateInterrupted)
	{
		[self _stopStreamer];
	}
	else if (self.player.playbackState == MPMoviePlaybackStatePaused)
	{
		[self _setChannelToWaiting:[self.stations uiIndexForStation:self.currentStation]];
	}
	else if (self.player.playbackState == MPMoviePlaybackStatePlaying)
	{
		self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:15 target:self selector:@selector(_updateNowPlaying) userInfo:nil repeats:YES];

		[self _updateNowPlaying];
		[self _setChannelToPlaying:[self.stations uiIndexForStation:self.currentStation]];
	}
	else if (self.player.playbackState == MPMoviePlaybackStateStopped)
	{
		[self _stopStreamer];
	}
}

- (void)_updateNowPlaying
{
	if (self.currentStation != nil && self.nowPlayingUpdater.updating == NO)
	{
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		
		[self.nowPlayingUpdater updateNowPlayingWithStation:self.currentStation completion:^(NSString *nowPlaying) {
			[self _updateNowPlayingLabel:nowPlaying];
			
			[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
		}];
	}
}

- (void)_updateNowPlayingLabel:(NSString *)track
{
	if ([track isEqualToString:self.nowPlayingLabel.text] == NO)
	{
		self.nowPlayingLabel.text = track;
		[self resetAnimation];
	}
}

- (void)_startPlayingWithM3U:(NSString *)m3u
{
	[self _setPlayButtonsEnabled:YES];
}

- (void)_setPlayButtonsEnabled:(BOOL)enabled
{
	for (NSInteger channel = 0; channel < IFMChannelsMax; channel++)
	{
		[[self.playButtons objectAtIndexOrNil:channel] setEnabled:enabled];
	}
}

- (void)_displayPlaylistError
{
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to load playlist", nil)
																   message:NSLocalizedString(@"The Internet connection may be down, or the servers aren't responding.", nil)
															preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss", nil)
											  style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) {}]];
	[self presentViewController:alert animated:YES completion:nil];
	[self _setPlayButtonsEnabled:YES];

	UIActivityIndicatorView *spinner = [self.spinners objectAtIndexOrNil:[self.stations uiIndexForStation:self.currentStation]];
	spinner.hidden = YES;
}

- (void)_playChannel:(NSInteger)channel
{
	[self _stopStreamer];
	[self _setPlayButtonsEnabled:YES];
	
	IFMStation *station = [self.stations stationForIndex:channel];
	self.player.contentURL = station.url;
	[self.player prepareToPlay];
	[self.player play];
	
	self.currentStation = station;
	
	UIActivityIndicatorView *spinner = [self.spinners objectAtIndexOrNil:channel];
	spinner.hidden = NO;
	[spinner startAnimating];
}

- (void)_resetEverything
{
	self.currentStation = nil;
	
	[self.nowPlayingTimer invalidate];
	self.nowPlayingTimer = nil;
	
	for (NSInteger channel = 0; channel < IFMChannelsMax; channel++)
	{
		[[self.spinners objectAtIndexOrNil:channel] setHidden:YES];
		[[self.playButtons objectAtIndexOrNil:channel] setEnabled:YES];
		[[self.stopButtons objectAtIndexOrNil:channel] setEnabled:NO];
		[[self.stopButtons objectAtIndexOrNil:channel] setHidden:YES];
	}
	
	self.nowPlayingLabel.text = @"";
}

#pragma mark - IBActions

- (IBAction)showInfo
{
	NSURL *url = [NSURL URLWithString:@"https://www.intergalactic.fm"];
	
	if ([[UIApplication sharedApplication] respondsToSelector:@selector(openURL:options:completionHandler:)]) {
		[[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
	} else {
		[[UIApplication sharedApplication] openURL:url];
	}
}

- (IBAction)channel1ButtonPressed:(id)sender
{
	[self _playChannel:0];
}

- (IBAction)channel2ButtonPressed:(id)sender
{
	[self _playChannel:1];
}

- (IBAction)channel3ButtonPressed:(id)sender
{
	[self _playChannel:2];
}

- (IBAction)stopButtonPressed:(id)sender
{
	[self _stopStreamer];
}

#pragma mark - Public

- (void)resetAnimation
{
	[self.nowPlayingLabel sizeToFit];
	self.nowPlayingLabel.frame = CGRectMake(self.view.frame.size.width,
											self.nowPlayingLabel.frame.origin.y,
											self.nowPlayingLabel.bounds.size.width,
											self.nowPlayingLabel.bounds.size.height);
	[UIView animateWithDuration:((640 + self.nowPlayingLabel.frame.size.width) / 60) delay:0 options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear) animations:^{
		self.nowPlayingLabel.frame = CGRectMake(-self.nowPlayingLabel.frame.size.width,
												self.nowPlayingLabel.frame.origin.y,
												self.nowPlayingLabel.bounds.size.width,
												self.nowPlayingLabel.bounds.size.height);
	} completion:nil];
}

#pragma mark - UIViewController overrides

- (BOOL)canBecomeFirstResponder
{
	return YES;
}

- (void)viewDidLoad
{
	[super viewDidLoad];

	NSMutableArray *playButtons = [[NSMutableArray alloc] init];
	[playButtons addObject:self.channel1Button];
	[playButtons addObject:self.channel2Button];
	[playButtons addObject:self.channel3Button];
	self.playButtons = playButtons;

	NSMutableArray *stopButtons = [[NSMutableArray alloc] init];
	[stopButtons addObject:self.channel1StopButton];
	[stopButtons addObject:self.channel2StopButton];
	[stopButtons addObject:self.channel3StopButton];
	self.stopButtons = stopButtons;

	NSMutableArray *spinners = [[NSMutableArray alloc] init];
	[spinners addObject:self.channel1Spinner];
	[spinners addObject:self.channel2Spinner];
	[spinners addObject:self.channel3Spinner];
	self.spinners = spinners;

	self.stations = [[IFMStations alloc] init];
	[self.stations updateStations];
	
	self.nowPlayingUpdater = [[IFMNowPlaying alloc] init];
	
	[self _resetEverything];
	
	[UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerNotificationReceived:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
	
	self.player = [[MPMoviePlayerController alloc] init];
	self.player.movieSourceType = MPMovieSourceTypeStreaming;
	self.player.view.hidden = YES;
	[self.view addSubview:self.player.view];
	
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&activationError];
	[[AVAudioSession sharedInstance] setActive:YES error:&activationError];
	
	NSString *version = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
	NSString *introText = [NSString stringWithFormat:@"Intergalactic FM for iPhone version %@ — https://www.intergalactic.fm/ — Developed by Aero Deko and IFM dev corps", version];
	
	self.nowPlayingLabel = [[UILabel alloc] initWithFrame:CGRectZero];
	self.nowPlayingLabel.text = introText;
	self.nowPlayingLabel.font = [UIFont fontWithName:@"Michroma" size:20];
	self.nowPlayingLabel.backgroundColor = [UIColor clearColor];
	self.nowPlayingLabel.textColor = [UIColor redColor];
	[self.nowPlayingLabel sizeToFit];
	CGFloat height = CGRectGetMinY(self.infoButton.frame) - CGRectGetMaxY(self.channel3Button.frame);
	CGFloat y = CGRectGetMaxY(self.channel3Button.frame) + (height / 2.0) - (CGRectGetHeight(self.nowPlayingLabel.bounds) / 2.0);
	CGFloat yOffset = 6;
	self.nowPlayingLabel.frame = CGRectMake(0, y + yOffset, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.nowPlayingLabel.bounds));
	[self.view addSubview:self.nowPlayingLabel];
	[self resetAnimation];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	if (event.type == UIEventTypeRemoteControl)
	{
		switch (event.subtype)
		{
			case UIEventSubtypeRemoteControlPlay:
			{
				break;
			}
			case UIEventSubtypeRemoteControlPause:
			{
				[self _stopStreamer];
				break;
			}
			case UIEventSubtypeRemoteControlStop:
			{
				[self _stopStreamer];
				break;
			}
			case UIEventSubtypeRemoteControlTogglePlayPause:
			{
				// TODO: Verify that playbackState works.
				
				if (self.player.playbackState == MPMoviePlaybackStatePlaying)
				{
					[self _stopStreamer];
				}
				else if (self.player.playbackState != MPMoviePlaybackStatePlaying && self.currentStation != nil)
				{
					[self _playChannel:[self.stations uiIndexForStation:self.currentStation]];
				}
				
				break;
			}
			case UIEventSubtypeRemoteControlNextTrack:
			{
				[self _stopStreamer];
				
				NSInteger index = [self.stations uiIndexForStation:self.currentStation];
				
				if (index < self.stations.numberOfStations)
				{
					index += 1;
				}
				else
				{
					index = 0;
				}
				
				self.currentStation = [self.stations stationForIndex:index];
				
				[self _playChannel:index];
				
				break;
			}
			case UIEventSubtypeRemoteControlPreviousTrack:
			{
				[self _stopStreamer];
				
				NSInteger index = [self.stations uiIndexForStation:self.currentStation];

				if (index == 0)
				{
					index = self.stations.numberOfStations;
				}
				else
				{
					index -= 1;
				}
				
				self.currentStation = [self.stations stationForIndex:index];
				
				[self _playChannel:index];

				break;
			}
			default:
			{
				break;
			}
		}
	}
}

@end
