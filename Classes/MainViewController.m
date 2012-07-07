//
//  MainViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import "MainViewController.h"
#import "AudioStreamer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CFNetwork/CFNetwork.h>

@interface MainViewController ()
@property (nonatomic, retain) IBOutlet UIButton *channel1Button;
@property (nonatomic, retain) IBOutlet UIButton *channel2Button;
@property (nonatomic, retain) IBOutlet UIButton *channel3Button;
@property (nonatomic, retain) IBOutlet UIButton *channel4Button;
@property (nonatomic, retain) IBOutlet UIButton *channel1StopButton;
@property (nonatomic, retain) IBOutlet UIButton *channel2StopButton;
@property (nonatomic, retain) IBOutlet UIButton *channel3StopButton;
@property (nonatomic, retain) IBOutlet UIButton *channel4StopButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *channel1Spinner;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *channel2Spinner;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *channel3Spinner;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *channel4Spinner;
@property (nonatomic, retain) UILabel *nowPlayingLabel;
@property (nonatomic, retain) AudioStreamer *streamer;
@property (nonatomic, retain) NSString *channelSelection;
@property (nonatomic, retain) NSString *nowPlayingString;
@property (nonatomic, assign) NSInteger channelPlaying;
@property (nonatomic, assign) NSInteger savedChannelPlaying;
@property (nonatomic, retain) NSOperationQueue *operationQueue;
@property (nonatomic, retain) CABasicAnimation *scrollText;
@property (nonatomic, retain) NSTimer *nowPlayingTimer;
@property (nonatomic, assign) BOOL busyLoading;
@property (nonatomic, assign) BOOL playing;
@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{
		self.operationQueue = [[NSOperationQueue alloc] init];
        [self.operationQueue setMaxConcurrentOperationCount:2];
    }
    return self;
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{    
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo
{    	
	[TestFlight passCheckpoint:@"Info button touched"];
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (BOOL)canBecomeFirstResponder
{
    return TRUE;
}

-(void)viewDidLoad
{
	[self resetEverything];
			
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
	NSString *introText = [NSString stringWithFormat:@"Intergalactic FM Player version %@ — Developed by Aero Deko — Visit our site at http://aerodeko.com", version];
	
	self.nowPlayingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 434, 320, 24)];
	[self.nowPlayingLabel setText:introText];
	[self.nowPlayingLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[self.nowPlayingLabel setBackgroundColor:[UIColor clearColor]];
	[self.nowPlayingLabel setTextColor:[UIColor lightGrayColor]];
	[self.nowPlayingLabel sizeToFit];
	[self.view addSubview:self.nowPlayingLabel];
	
	self.scrollText = [CABasicAnimation animationWithKeyPath:@"position.x"];
	self.scrollText.duration = (640 + self.nowPlayingLabel.frame.size.width) / 60;
	self.scrollText.repeatCount = 10000;
	self.scrollText.autoreverses = NO;
	self.scrollText.fromValue = [NSNumber numberWithFloat:320 + (self.nowPlayingLabel.frame.size.width / 2)];
	self.scrollText.toValue = [NSNumber numberWithFloat:0 - (self.nowPlayingLabel.frame.size.width / 2)];
	[[self.nowPlayingLabel layer] addAnimation:self.scrollText forKey:@"scrollTextKey"];
	self.nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(updateNowPlaying) userInfo:nil repeats:YES];
	
	self.busyLoading = NO;
	self.playing = NO;
	
	self.savedChannelPlaying = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)destroyStreamer
{
	if (self.streamer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:self.streamer];
		
		[self.streamer stop];
		[self.streamer release];
		self.streamer = nil;
	}
}

- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([self.streamer isWaiting])
	{
		// show spinner and hide stop button when waiting for stream to play (eg. loading or interrupted)
		switch (self.channelPlaying) {
			case 1:
				[self.channel1Spinner setHidden:NO];
				[self.channel1Spinner startAnimating];
				[self.channel1Button setEnabled:NO];
				[self.channel1StopButton setHidden:YES];
				[self.channel1StopButton setEnabled:NO];
				break;
			case 2:
				[self.channel2Spinner setHidden:NO];
				[self.channel2Spinner startAnimating];
				[self.channel2Button setEnabled:NO];
				[self.channel2StopButton setHidden:YES];
				[self.channel2StopButton setEnabled:NO];
				break;
			case 3:
				[self.channel3Spinner setHidden:NO];
				[self.channel3Spinner startAnimating];
				[self.channel3Button setEnabled:NO];
				[self.channel3StopButton setHidden:YES];
				[self.channel3StopButton setEnabled:NO];
				break;
			case 4:
				[self.channel4Spinner setHidden:NO];
				[self.channel4Spinner startAnimating];
				[self.channel4Button setEnabled:NO];
				[self.channel4StopButton setHidden:YES];
				[self.channel4StopButton setEnabled:NO];
				break;
			default:
				break;
		}
	}
	else if ([self.streamer isPlaying])
	{
		[self updateNowPlaying];

		// hide spinner and show stop button
		switch (self.channelPlaying) {
			case 1:
				[self.channel1Spinner setHidden:YES];
				[self.channel1StopButton setHidden:NO];
				[self.channel1StopButton setEnabled:YES];
				break;
			case 2:
				[self.channel2Spinner setHidden:YES];
				[self.channel2StopButton setHidden:NO];
				[self.channel2StopButton setEnabled:YES];
				break;
			case 3:
				[self.channel3Spinner setHidden:YES];
				[self.channel3StopButton setHidden:NO];
				[self.channel3StopButton setEnabled:YES];
				break;
			case 4:
				[self.channel4Spinner setHidden:YES];
				[self.channel4StopButton setHidden:NO];
				[self.channel4StopButton setEnabled:YES];
				break;
			default:
				break;
		}
	}
	else if ([self.streamer isIdle])
	{
		// streamer stops
		[self resetEverything];
		[self destroyStreamer];
	}
}

- (void)createStreamer
{
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[self becomeFirstResponder];
	
	if (self.streamer)
	{
		return;
	}
	
	[self destroyStreamer];
	
	NSString *escapedValue =
	[(NSString *)CFURLCreateStringByAddingPercentEscapes(nil, (CFStringRef)self.channelSelection, NULL, NULL, kCFStringEncodingUTF8) autorelease];
	
	NSURL *url = [NSURL URLWithString:escapedValue];
	self.streamer = [[AudioStreamer alloc] initWithURL:url];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:ASStatusChangedNotification object:self.streamer];
}

- (void)updateNowPlaying
{
	if(self.channelPlaying != 0 && self.busyLoading == NO)
	{
		self.busyLoading = YES;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(synchronousLoadNowPlayingData) object:nil];
		[self.operationQueue addOperation:operation];
		[operation release];
	}
}

- (void)synchronousLoadNowPlayingData
{
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://intergalactic.fm/data/playing%d.html", self.channelPlaying];
    NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	
	self.nowPlayingString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	self.nowPlayingString = [self.nowPlayingString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

	NSArray* lines = [self.nowPlayingString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		
	if(![[lines objectAtIndex:2] isEqualToString:[self.nowPlayingLabel text]])
	{		
		[self performSelectorOnMainThread:@selector(updateNowPlayingLabel:) withObject:[lines objectAtIndex:2] waitUntilDone:YES];
	}	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	self.busyLoading = NO;
}

- (void)updateNowPlayingLabel:(NSString *)track
{
	[self.nowPlayingLabel setText:track];
	[self.nowPlayingLabel sizeToFit];
	[self resetAnimation];
}

- (void)resetAnimation
{
	[[self.nowPlayingLabel layer] removeAllAnimations];
	self.scrollText = [CABasicAnimation animationWithKeyPath:@"position.x"];
	self.scrollText.duration = (640 + self.nowPlayingLabel.frame.size.width) / 60;
	self.scrollText.repeatCount = 10000;
	self.scrollText.autoreverses = NO;
	self.scrollText.fromValue = [NSNumber numberWithFloat:320 + (self.nowPlayingLabel.frame.size.width / 2)];
	self.scrollText.toValue = [NSNumber numberWithFloat:0 - (self.nowPlayingLabel.frame.size.width / 2)];
	[[self.nowPlayingLabel layer] addAnimation:self.scrollText forKey:@"scrollTextKey"];
}

- (void)ae_playChannel:(NSInteger)channel
{
	[TestFlight passCheckpoint:[NSString stringWithFormat:@"Channel %d button touched", channel]];
	
	[self.streamer stop];
	[self destroyStreamer];
	[self resetEverything];
	
	NSString *m3u = [NSString stringWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://radio.intergalactic.fm/%daac.m3u", channel]]encoding:NSUTF8StringEncoding error:nil];
	self.channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	self.channelPlaying = channel;
	self.savedChannelPlaying = channel;
	
	[self createStreamer];
	[self.streamer start];
	self.playing = YES;
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

	[self.streamer stop];
	[self destroyStreamer];
	[self performSelectorOnMainThread:@selector(resetEverything) withObject:nil waitUntilDone:YES];
	self.savedChannelPlaying = 0;
}

- (void)resetEverything
{
	self.channelPlaying = 0;
	self.playing = NO;
	
	[self.channel1Spinner setHidden:YES];
	[self.channel2Spinner setHidden:YES];
	[self.channel3Spinner setHidden:YES];
	[self.channel4Spinner setHidden:YES];
	
	[self.channel1Button setEnabled:YES];
	[self.channel2Button setEnabled:YES];
	[self.channel3Button setEnabled:YES];
	[self.channel4Button setEnabled:YES];
	
	[self.channel1StopButton setEnabled:NO];
	[self.channel2StopButton setEnabled:NO];
	[self.channel3StopButton setEnabled:NO];
	[self.channel4StopButton setEnabled:NO];
	
	[self.channel1StopButton setHidden:YES];
	[self.channel2StopButton setHidden:YES];
	[self.channel3StopButton setHidden:YES];
	[self.channel4StopButton setHidden:YES];
	
	self.nowPlayingLabel.text = @"";
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	if(event.type == UIEventTypeRemoteControl)
	{
		[TestFlight passCheckpoint:@"Remote control event received"];
		
		switch (event.subtype)
		{
            case UIEventSubtypeRemoteControlPlay:
                break;
            case UIEventSubtypeRemoteControlPause:
				[self.streamer stop];
				[self destroyStreamer];
				[self resetEverything];
                break;                
            case UIEventSubtypeRemoteControlStop:
				[self.streamer stop];
				[self destroyStreamer];
				[self resetEverything];
                break;                
            case UIEventSubtypeRemoteControlTogglePlayPause:
			{
				if(self.playing)
				{
					self.playing = NO;
					[self.streamer stop];
					[self destroyStreamer];
					[self resetEverything];
				}
				else if(self.playing == NO && self.savedChannelPlaying != 0)
				{
					[self playSavedChannel];
				}
                break;                
			}
            case UIEventSubtypeRemoteControlNextTrack:
			{        
				[self.streamer stop];
				[self destroyStreamer];
				[self resetEverything];
				if(self.savedChannelPlaying < 4)
				{
					self.savedChannelPlaying++;
				}
				else 
				{
					self.savedChannelPlaying = 1;
				}
				[self playSavedChannel];
				break;
			}
            case UIEventSubtypeRemoteControlPreviousTrack:
			{        
				[self.streamer stop];
				[self destroyStreamer];
				[self resetEverything];
				if(self.savedChannelPlaying == 1)
				{
					self.savedChannelPlaying = 4;
				}
				else 
				{
					self.savedChannelPlaying--;
				}
				[self playSavedChannel];
				break;
			}
			default:
				break;
		}
	}
}

- (void)playSavedChannel
{
	self.playing = YES;
	switch (self.savedChannelPlaying)
	{
		case 1:
			[self channel1ButtonPressed:nil];
			break;
		case 2:
			[self channel2ButtonPressed:nil];
			break;
		case 3:
			[self channel3ButtonPressed:nil];
			break;
		case 4:
			[self channel4ButtonPressed:nil];
			break;
		default:
			break;
	}					
}

- (void)dealloc
{
    [super dealloc];
}


@end
