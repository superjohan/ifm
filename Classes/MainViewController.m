//
//  MainViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import "MainViewController.h"
#import "AudioStreamer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>
#import "AECGHelpers.h"
#import "AENSArrayAdditions.h"

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
@property (nonatomic, strong) AudioStreamer *streamer;
@property (nonatomic, strong) NSString *channelSelection;
@property (nonatomic, strong) NSString *nowPlayingString;
@property (nonatomic, assign) NSInteger channelPlaying;
@property (nonatomic, assign) NSInteger savedChannelPlaying;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSTimer *nowPlayingTimer;
@property (nonatomic, assign) BOOL busyLoading;
@property (nonatomic, assign) BOOL playing;
@end

@implementation MainViewController

#pragma mark - Private

- (void)ae_destroyStreamer
{
	if (self.streamer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:self.streamer];
		
		[self.streamer stop];
		self.streamer = nil;
	}
}

- (void)ae_stopStreamer
{
	[self ae_destroyStreamer];
	[self ae_resetEverything];
}

- (void)ae_setChannelToWaiting:(NSInteger)channel
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

- (void)ae_setChannelToPlaying:(NSInteger)channel
{
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]];
	UIButton *stopButton = [self valueForKey:[NSString stringWithFormat:@"channel%dStopButton", channel]];
	
	spinner.hidden = YES;
	stopButton.hidden = NO;
	stopButton.enabled = YES;
}

- (void)ae_playbackStateChanged:(NSNotification *)aNotification
{
	if ([self.streamer isWaiting])
		[self ae_setChannelToWaiting:self.channelPlaying];
	else if ([self.streamer isPlaying])
	{
		[self ae_updateNowPlaying];
		[self ae_setChannelToPlaying:self.channelPlaying];
	}
	else if ([self.streamer isIdle])
		[self ae_stopStreamer];
}

- (void)ae_createStreamer
{
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[self becomeFirstResponder];
	
	if (self.streamer)
		return;
	
	NSString *escapedValue = [self.channelSelection stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *url = [NSURL URLWithString:escapedValue];
	self.streamer = [[AudioStreamer alloc] initWithURL:url];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ae_playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
}

- (void)ae_updateNowPlaying
{
	if (self.channelPlaying != 0 && self.busyLoading == NO)
	{
		self.busyLoading = YES;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(ae_synchronousLoadNowPlayingData) object:nil];
		[self.operationQueue addOperation:operation];
	}
}

- (void)ae_synchronousLoadNowPlayingData
{
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://intergalacticfm.com/data/playing%d.html", self.channelPlaying];
    NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	
	self.nowPlayingString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	self.nowPlayingString = [self.nowPlayingString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];
	
	NSArray* lines = [self.nowPlayingString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	if ( ! [[lines objectAtIndex:2] isEqualToString:[self.nowPlayingLabel text]])
		[self performSelectorOnMainThread:@selector(ae_updateNowPlayingLabel:) withObject:[lines objectAtIndex:2] waitUntilDone:YES];
	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.busyLoading = NO;
}

- (void)ae_updateNowPlayingLabel:(NSString *)track
{
	self.nowPlayingLabel.text = track;
	[self resetAnimation];
}

- (void)ae_startPlayingWithM3U:(NSString *)m3u
{
	self.channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] firstObject];
	[self ae_createStreamer];
	[self.streamer start];
	self.playing = YES;
	[self ae_setPlayButtonsEnabled:YES];
}

- (void)ae_setPlayButtonsEnabled:(BOOL)enabled
{
	for (NSInteger channel = 1;  channel < 5; channel++)
		[[self valueForKey:[NSString stringWithFormat:@"channel%dButton", channel]] setEnabled:enabled];
}

- (void)ae_displayPlaylistError
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Unable to load playlist", nil) message:NSLocalizedString(@"The Internet connection may be down, or the servers aren't responding.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Dismiss", nil), nil];
	[alert show];
	[self ae_setPlayButtonsEnabled:YES];

	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", self.channelPlaying]];
	spinner.hidden = YES;
}

- (void)ae_playChannel:(NSInteger)channel
{
	[TestFlight passCheckpoint:[NSString stringWithFormat:@"Channel %d button touched", channel]];
	
	[self ae_stopStreamer];
	[self ae_setPlayButtonsEnabled:NO];
	
	UIActivityIndicatorView *spinner = [self valueForKey:[NSString stringWithFormat:@"channel%dSpinner", channel]];
	spinner.hidden = NO;
	[spinner startAnimating];

	self.channelPlaying = channel;
	self.savedChannelPlaying = self.channelPlaying;
	
	__block MainViewController *blockSelf = self;
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://radio.intergalacticfm.com/%daac.m3u", channel]]];
	[NSURLConnection sendAsynchronousRequest:request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
		if (data == nil)
			[blockSelf performSelectorOnMainThread:@selector(ae_displayPlaylistError) withObject:nil waitUntilDone:YES];
		else
		{
			NSString *m3u = [NSString stringWithCString:[data bytes] encoding:NSUTF8StringEncoding];
			[blockSelf performSelectorOnMainThread:@selector(ae_startPlayingWithM3U:) withObject:m3u waitUntilDone:YES];
		}
	}];
}

- (void)ae_resetEverything
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

- (void)ae_playSavedChannel
{
	[self ae_playChannel:self.savedChannelPlaying];
}

#pragma mark - IBActions

- (IBAction)showInfo
{
	[TestFlight passCheckpoint:@"Info button touched"];
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
}

- (IBAction)channel1ButtonPressed:(id)sender
{
	[self ae_playChannel:1];
}

- (IBAction)channel2ButtonPressed:(id)sender
{
	[self ae_playChannel:2];
}

- (IBAction)channel3ButtonPressed:(id)sender
{
	[self ae_playChannel:3];
}

- (IBAction)channel4ButtonPressed:(id)sender
{
	[self ae_playChannel:4];
}

- (IBAction)stopButtonPressed:(id)sender
{
	[TestFlight passCheckpoint:@"Stop button touched"];
	
	[self ae_stopStreamer];
	
	self.savedChannelPlaying = 0;
}

#pragma mark - Public

- (void)resetAnimation
{
	[self.nowPlayingLabel sizeToFit];
	self.nowPlayingLabel.frame = AECGRectPlaceX(self.nowPlayingLabel.frame, self.view.frame.size.width);
	[UIView animateWithDuration:((640 + self.nowPlayingLabel.frame.size.width) / 60) delay:0 options:(UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveLinear) animations:^{
		self.nowPlayingLabel.frame = AECGRectPlaceX(self.nowPlayingLabel.frame, -self.nowPlayingLabel.frame.size.width);
	} completion:nil];
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
	[self ae_resetEverything];
	
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *introText = [NSString stringWithFormat:@"Intergalactic FM for iPhone version %@ — http://intergalacticfm.com/ — Developed by Aero Deko — Visit our site at http://aerodeko.com/ — Intergalactic FM for iPhone uses AudioStreamer by Matt Gallagher.", version];
	
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
		[TestFlight passCheckpoint:@"Remote control event received"];
		
		switch (event.subtype)
		{
            case UIEventSubtypeRemoteControlPlay:
			{
                break;
			}
            case UIEventSubtypeRemoteControlPause:
			{
				[self ae_stopStreamer];
                break;
            }
			case UIEventSubtypeRemoteControlStop:
			{
				[self ae_stopStreamer];
                break;
			}
            case UIEventSubtypeRemoteControlTogglePlayPause:
			{
				if (self.playing)
					[self ae_stopStreamer];
				else if ( ! self.playing && self.savedChannelPlaying != 0)
					[self ae_playSavedChannel];
				
                break;
			}
            case UIEventSubtypeRemoteControlNextTrack:
			{
				[self ae_stopStreamer];
				
				if (self.savedChannelPlaying < 4)
					self.savedChannelPlaying++;
				else
					self.savedChannelPlaying = 1;
				
				[self ae_playSavedChannel];
				break;
			}
            case UIEventSubtypeRemoteControlPreviousTrack:
			{
				[self ae_stopStreamer];
				
				if (self.savedChannelPlaying == 1)
					self.savedChannelPlaying = 4;
				else
					self.savedChannelPlaying--;
				
				[self ae_playSavedChannel];
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
