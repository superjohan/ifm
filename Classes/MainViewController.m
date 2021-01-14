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
@property (nonatomic) UILabel *nowPlayingLabel;
@property (nonatomic) NSString *nowPlayingString;
@property (nonatomic) NSTimer *nowPlayingTimer;
@property (nonatomic) MPMoviePlayerController *player;
@property (nonatomic) IFMStations *stations;
@property (nonatomic) IFMNowPlaying *nowPlayingUpdater;
@property (nonatomic) IFMStation *currentStation;
@end

@implementation MainViewController

#pragma mark - Private

- (void)_stopStreamer
{
	[self.player stop];
	[self _resetEverything];
}

- (void)_setChannelToWaiting:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%ldSpinner", (long)channel]];
	UIButton *playButton = [self valueForKey:[NSString stringWithFormat:@"channel%ldButton", (long)channel]];
	UIButton *stopButton = [self valueForKey:[NSString stringWithFormat:@"channel%ldStopButton", (long)channel]];
	
	[spinner startAnimating];
	spinner.hidden = NO;
	playButton.enabled = NO;
	stopButton.hidden = YES;
	stopButton.enabled = NO;
}

- (void)_setChannelToPlaying:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%ldSpinner", (long)channel]];
	UIButton *stopButton = [self valueForKey:[NSString stringWithFormat:@"channel%ldStopButton", (long)channel]];
	
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
	for (NSInteger channel = 1;  channel < 4; channel++)
	{
		[[self valueForKey:[NSString stringWithFormat:@"channel%ldButton", (long)channel]] setEnabled:enabled];
	}
}

- (void)_displayPlaylistError
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to load playlist", nil) message:NSLocalizedString(@"The Internet connection may be down, or the servers aren't responding.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Dismiss", nil), nil];
	[alert show];
	[self _setPlayButtonsEnabled:YES];

	// FIXME: create a method for this
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%ldSpinner", (long)[self.stations uiIndexForStation:self.currentStation]]];
	spinner.hidden = YES;
}

- (void)_playChannel:(NSInteger)channel
{
	[self _stopStreamer];
	[self _setPlayButtonsEnabled:YES];
	
	IFMStation *station = [self.stations stationForIndex:channel - 1];
	self.player.contentURL = station.url;
	[self.player prepareToPlay];
	[self.player play];
	
	self.currentStation = station;
	
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%ldSpinner", (long)channel]];
	spinner.hidden = NO;
	[spinner startAnimating];
}

- (void)_resetEverything
{
	self.currentStation = nil;
	
	[self.nowPlayingTimer invalidate];
	self.nowPlayingTimer = nil;
	
	for (NSInteger channel = 1;  channel < 4; channel++)
	{
		[[self valueForKey:[NSString stringWithFormat:@"channel%ldSpinner", (long)channel]] setHidden:YES];
		[[self valueForKey:[NSString stringWithFormat:@"channel%ldButton", (long)channel]] setEnabled:YES];
		[[self valueForKey:[NSString stringWithFormat:@"channel%ldStopButton", (long)channel]] setEnabled:NO];
		[[self valueForKey:[NSString stringWithFormat:@"channel%ldStopButton", (long)channel]] setHidden:YES];
	}
	
	self.nowPlayingLabel.text = @"";
}

#pragma mark - IBActions

- (IBAction)showInfo
{
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentViewController:controller animated:YES completion:nil];
}

- (IBAction)channel1ButtonPressed:(id)sender
{
	[self _playChannel:1];
}

- (IBAction)channel2ButtonPressed:(id)sender
{
	[self _playChannel:2];
}

- (IBAction)channel3ButtonPressed:(id)sender
{
	[self _playChannel:3];
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
	NSString *introText = [NSString stringWithFormat:@"Intergalactic FM for iPhone version %@ — https://www.intergalactic.fm/ — Developed by Aero Deko / Updated by IFM dev corps — Visit our site at http://aerodeko.com/", version];
	
	self.nowPlayingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 390, 320, 24)]; // <-- holy shit FIXME FIXME FIXME
	self.nowPlayingLabel.text = introText;
	//self.nowPlayingLabel.font = [UIFont boldSystemFontOfSize:30];
    self.nowPlayingLabel.font = [UIFont fontWithName:@"Michroma" size:20];
	self.nowPlayingLabel.backgroundColor = [UIColor clearColor];
	self.nowPlayingLabel.textColor = [UIColor redColor];
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
					index = 1;
				}
				
				self.currentStation = [self.stations stationForIndex:index + 1];
				
				[self _playChannel:index];
				
				break;
			}
            case UIEventSubtypeRemoteControlPreviousTrack:
			{
				[self _stopStreamer];
				
				NSInteger index = [self.stations uiIndexForStation:self.currentStation];

				if (index == 1)
				{
					index = self.stations.numberOfStations;
				}
				else
				{
					index -= 1;
				}
				
				self.currentStation = [self.stations stationForIndex:index + 1];
				
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

#pragma mark - FlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
