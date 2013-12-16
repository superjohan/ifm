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
#import "AECGHelpers.h"
#import "AENSArrayAdditions.h"
#import <AVFoundation/AVFoundation.h>

@interface MainViewController ()
@property (nonatomic, strong) IBOutlet UIButton *channel1Button;
@property (nonatomic, strong) IBOutlet UIButton *channel2Button;
@property (nonatomic, strong) IBOutlet UIButton *channel3Button;
@property (nonatomic, strong) IBOutlet UIButton *channel4Button;
@property (nonatomic, strong) IBOutlet UIButton *channel1StopButton;
@property (nonatomic, strong) IBOutlet UIButton *channel2StopButton;
@property (nonatomic, strong) IBOutlet UIButton *channel3StopButton;
@property (nonatomic, strong) IBOutlet UIButton *channel4StopButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *channel1Spinner;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *channel2Spinner;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *channel3Spinner;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *channel4Spinner;
@property (nonatomic, strong) UILabel *nowPlayingLabel;
@property (nonatomic, strong) NSString *channelSelection;
@property (nonatomic, strong) NSString *nowPlayingString;
@property (nonatomic, assign) NSInteger channelPlaying;
@property (nonatomic, assign) NSInteger savedChannelPlaying;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSTimer *nowPlayingTimer;
@property (nonatomic, assign) BOOL busyLoading;
@property (nonatomic, assign) BOOL playing;
@property (nonatomic, strong) MPMoviePlayerController *player;
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
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]];
	UIButton *playButton = [self valueForKey:[NSString stringWithFormat:@"channel%dButton", channel]];
	UIButton *stopButton = [self valueForKey:[NSString stringWithFormat:@"channel%dStopButton", channel]];
	
	[spinner startAnimating];
	spinner.hidden = NO;
	playButton.enabled = NO;
	stopButton.hidden = YES;
	stopButton.enabled = NO;
}

- (void)_setChannelToPlaying:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]];
	UIButton *stopButton = [self valueForKey:[NSString stringWithFormat:@"channel%dStopButton", channel]];
	
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
		[self _setChannelToWaiting:self.channelPlaying];
	}
	else if (self.player.playbackState == MPMoviePlaybackStatePlaying)
	{
		[self _updateNowPlaying];
		[self _setChannelToPlaying:self.channelPlaying];
	}
	else if (self.player.playbackState == MPMoviePlaybackStateStopped)
	{
		[self _stopStreamer];
	}
}

- (void)_updateNowPlaying
{
	if (self.channelPlaying != 0 && self.busyLoading == NO)
	{
		self.busyLoading = YES;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(_synchronousLoadNowPlayingData) object:nil];
		[self.operationQueue addOperation:operation];
	}
}

// FIXME: this is the dumbest thing ever
- (void)_synchronousLoadNowPlayingData
{
	NSString *urlString = [[NSString alloc] initWithFormat:@"https://intergalacticfm.com/ifm-system/playing%d.php", self.channelPlaying];
    NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	
	self.nowPlayingString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	self.nowPlayingString = [self.nowPlayingString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	
	NSArray* lines = [self.nowPlayingString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if ( ! [[lines objectAtIndex:2] isEqualToString:[self.nowPlayingLabel text]])
	{
		[self performSelectorOnMainThread:@selector(_updateNowPlayingLabel:) withObject:[lines objectAtIndex:2] waitUntilDone:YES];
	}
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.busyLoading = NO;
}

- (void)_updateNowPlayingLabel:(NSString *)track
{
	self.nowPlayingLabel.text = track;
	[self resetAnimation];
}

- (void)_startPlayingWithM3U:(NSString *)m3u
{
	self.playing = YES;
	[self _setPlayButtonsEnabled:YES];
}

- (void)_setPlayButtonsEnabled:(BOOL)enabled
{
	for (NSInteger channel = 1;  channel < 5; channel++)
	{
		[[self valueForKey:[NSString stringWithFormat:@"channel%dButton", channel]] setEnabled:enabled];
	}
}

- (void)_displayPlaylistError
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to load playlist", nil) message:NSLocalizedString(@"The Internet connection may be down, or the servers aren't responding.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Dismiss", nil), nil];
	[alert show];
	[self _setPlayButtonsEnabled:YES];

	// FIXME: create a method for this
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", self.channelPlaying]];
	spinner.hidden = YES;
}

- (void)_playChannel:(NSInteger)channel
{
	[self _stopStreamer];
	[self _setPlayButtonsEnabled:YES];
	
	if (channel == 1)
	{
		self.player.contentURL = [NSURL URLWithString:@"http://95.211.225.124:1935/live/mfm/playlist.m3u8"];
	}
	else if (channel == 2)
	{
		self.player.contentURL = [NSURL URLWithString:@"http://95.211.225.124:1935/live/ifm2/playlist.m3u8"];
	}
	else if (channel == 3)
	{
		self.player.contentURL = [NSURL URLWithString:@"http://95.211.225.124:1935/live/ifm3/playlist.m3u8"];
	}
	else if (channel == 4)
	{
		self.player.contentURL = [NSURL URLWithString:@"http://95.211.225.124:1935/live/ifm4/playlist.m3u8"];
	}
	
	[self.player prepareToPlay];
	[self.player play];
	
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]];
	spinner.hidden = NO;
	[spinner startAnimating];

	self.channelPlaying = channel;
	self.savedChannelPlaying = self.channelPlaying;
}

- (void)_resetEverything
{
	self.channelPlaying = 0;
	self.playing = NO;
	
	for (NSInteger channel = 1;  channel < 5; channel++)
	{
		[[self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]] setHidden:YES];
		[[self valueForKey:[NSString stringWithFormat:@"channel%dButton", channel]] setEnabled:YES];
		[[self valueForKey:[NSString stringWithFormat:@"channel%dStopButton", channel]] setEnabled:NO];
		[[self valueForKey:[NSString stringWithFormat:@"channel%dStopButton", channel]] setHidden:YES];
	}
	
	self.nowPlayingLabel.text = @"";
}

- (void)_playSavedChannel
{
	[self _playChannel:self.savedChannelPlaying];
}

#pragma mark - IBActions

- (IBAction)showInfo
{
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
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

- (IBAction)channel4ButtonPressed:(id)sender
{
	[self _playChannel:4];
}

- (IBAction)stopButtonPressed:(id)sender
{
	[self _stopStreamer];
	
	self.savedChannelPlaying = 0;
}

#pragma mark - Public

- (void)resetAnimation
{
	[self.nowPlayingLabel sizeToFit];
	self.nowPlayingLabel.frame = AECGRectPlaceX(self.nowPlayingLabel.frame, self.view.frame.size.width);
	[UIView animateWithDuration:((640 + self.nowPlayingLabel.frame.size.width) / 60) delay:0 options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear) animations:^
	{
		self.nowPlayingLabel.frame = AECGRectPlaceX(self.nowPlayingLabel.frame, -self.nowPlayingLabel.frame.size.width);
	}
	completion:nil];
}

#pragma mark - UIViewController overrides

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{
		self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:2];
    }
	
    return self;
}

- (BOOL)canBecomeFirstResponder
{
    return TRUE;
}

- (void)viewDidLoad
{
	[self _resetEverything];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerNotificationReceived:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
	
	self.player = [[MPMoviePlayerController alloc] init];
	self.player.movieSourceType = MPMovieSourceTypeStreaming;
	self.player.view.hidden = YES;
	[self.view addSubview:self.player.view];
	
	NSError *activationError = nil;
	[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&activationError];
	[[AVAudioSession sharedInstance] setActive:YES error:&activationError];
	
	NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *introText = [NSString stringWithFormat:@"Intergalactic FM for iPhone version %@ — http://intergalacticfm.com/ — Developed by Aero Deko — Visit our site at http://aerodeko.com/", version];
	
	self.nowPlayingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 434, 320, 24)];
	self.nowPlayingLabel.text = introText;
	self.nowPlayingLabel.font = [UIFont boldSystemFontOfSize:18];
	self.nowPlayingLabel.backgroundColor = [UIColor clearColor];
	self.nowPlayingLabel.textColor = [UIColor lightGrayColor];
	[self.view addSubview:self.nowPlayingLabel];
	[self resetAnimation];
	
	self.busyLoading = NO;
	self.playing = NO;
	
	self.savedChannelPlaying = 0;
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
				if (self.playing)
				{
					[self _stopStreamer];
				}
				else if ( ! self.playing && self.savedChannelPlaying != 0)
				{
					[self _playSavedChannel];
				}
				
                break;
			}
            case UIEventSubtypeRemoteControlNextTrack:
			{
				[self _stopStreamer];
				
				if (self.savedChannelPlaying < 4)
				{
					self.savedChannelPlaying++;
				}
				else
				{
					self.savedChannelPlaying = 1;
				}
				
				[self _playSavedChannel];
				break;
			}
            case UIEventSubtypeRemoteControlPreviousTrack:
			{
				[self _stopStreamer];
				
				if (self.savedChannelPlaying == 1)
				{
					self.savedChannelPlaying = 4;
				}
				else
				{
					self.savedChannelPlaying--;
				}
				
				[self _playSavedChannel];
				break;
			}
			default:
				break;
		}
	}
}

#pragma mark - FlipsideViewControllerDelegate

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{    
	[self dismissModalViewControllerAnimated:YES];
}

@end
