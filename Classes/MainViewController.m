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

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_0
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_0 550.32
#endif

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
#define IF_IOS4_OR_GREATER(...) \
if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iPhoneOS_4_0) \
{ \
__VA_ARGS__ \
}
#else
#define IF_IOS4_OR_GREATER(...)
#endif

@implementation MainViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{
        // Custom initialization
		operationQueue = [[NSOperationQueue alloc] init];
        [operationQueue setMaxConcurrentOperationCount:2];
    }
    return self;
}


- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo
{    	
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
	
	nowPlayingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 434, 320, 24)];
	[nowPlayingLabel setText:introText];
	[nowPlayingLabel setFont:[UIFont boldSystemFontOfSize:18]];
	[nowPlayingLabel setBackgroundColor:[UIColor clearColor]];
	[nowPlayingLabel setTextColor:[UIColor lightGrayColor]];
	[nowPlayingLabel sizeToFit];
	[self.view addSubview:nowPlayingLabel];
	
	scrollText = [CABasicAnimation animationWithKeyPath:@"position.x"];
	scrollText.duration = (640 + nowPlayingLabel.frame.size.width) / 60;
	scrollText.repeatCount = 10000;
	scrollText.autoreverses = NO;
	scrollText.fromValue = [NSNumber numberWithFloat:320 + (nowPlayingLabel.frame.size.width / 2)];
	scrollText.toValue = [NSNumber numberWithFloat:0 - (nowPlayingLabel.frame.size.width / 2)];
	[[nowPlayingLabel layer] addAnimation:scrollText forKey:@"scrollTextKey"];
	nowPlayingTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(updateNowPlaying) userInfo:nil repeats:YES];
	
	busyLoading = NO;
	playing = NO;
	
	savedChannelPlaying = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)destroyStreamer
{
	if (streamer)
	{
		[[NSNotificationCenter defaultCenter] removeObserver:self name:ASStatusChangedNotification object:streamer];
		
		[streamer stop];
		[streamer release];
		streamer = nil;
	}
}


- (void)playbackStateChanged:(NSNotification *)aNotification
{
	if ([streamer isWaiting])
	{
		// show spinner and hide stop button when waiting for stream to play (eg. loading or interrupted)
		switch (channelPlaying) {
			case 1:
				[channel1Spinner setHidden:NO];
				[channel1Spinner startAnimating];
				[channel1Button setEnabled:NO];
				[channel1StopButton setHidden:YES];
				[channel1StopButton setEnabled:NO];
				break;
			case 2:
				[channel2Spinner setHidden:NO];
				[channel2Spinner startAnimating];
				[channel2Button setEnabled:NO];
				[channel2StopButton setHidden:YES];
				[channel2StopButton setEnabled:NO];
				break;
			case 3:
				[channel3Spinner setHidden:NO];
				[channel3Spinner startAnimating];
				[channel3Button setEnabled:NO];
				[channel3StopButton setHidden:YES];
				[channel3StopButton setEnabled:NO];
				break;
			case 4:
				[channel4Spinner setHidden:NO];
				[channel4Spinner startAnimating];
				[channel4Button setEnabled:NO];
				[channel4StopButton setHidden:YES];
				[channel4StopButton setEnabled:NO];
				break;
			default:
				break;
		}
	}
	else if ([streamer isPlaying])
	{
		[self updateNowPlaying];

		// hide spinner and show stop button
		switch (channelPlaying) {
			case 1:
				[channel1Spinner setHidden:YES];
				[channel1StopButton setHidden:NO];
				[channel1StopButton setEnabled:YES];
				break;
			case 2:
				[channel2Spinner setHidden:YES];
				[channel2StopButton setHidden:NO];
				[channel2StopButton setEnabled:YES];
				break;
			case 3:
				[channel3Spinner setHidden:YES];
				[channel3StopButton setHidden:NO];
				[channel3StopButton setEnabled:YES];
				break;
			case 4:
				[channel4Spinner setHidden:YES];
				[channel4StopButton setHidden:NO];
				[channel4StopButton setEnabled:YES];
				break;
			default:
				break;
		}
	}
	else if ([streamer isIdle])
	{
		// streamer stops
		[self resetEverything];
		[self destroyStreamer];
	}
}

- (void)createStreamer
{
	IF_IOS4_OR_GREATER
	(
		[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
		[self becomeFirstResponder];
	);
	
	if (streamer)
	{
		return;
	}
	
	[self destroyStreamer];
	
	NSString *escapedValue =
	[(NSString *)CFURLCreateStringByAddingPercentEscapes(
														 nil,
														 (CFStringRef)channelSelection,
														 NULL,
														 NULL,
														 kCFStringEncodingUTF8)
	 autorelease];
	
	NSURL *url = [NSURL URLWithString:escapedValue];
	streamer = [[AudioStreamer alloc] initWithURL:url];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(playbackStateChanged:)
	 name:ASStatusChangedNotification
	 object:streamer];
}

- (void)updateNowPlaying
{
	if(channelPlaying != 0 && busyLoading == NO)
	{
		busyLoading = YES;
		[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
		NSInvocationOperation *operation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(synchronousLoadNowPlayingData) object:nil];
		[operationQueue addOperation:operation];
		[operation release];
	}
}

- (void)synchronousLoadNowPlayingData
{
	NSString *urlString = [[NSString alloc] initWithFormat:@"http://intergalactic.fm/data/playing%d.html", channelPlaying];
    NSURL *url = [NSURL URLWithString:urlString];
	NSData *data = [NSData dataWithContentsOfURL:url];
	
	nowPlayingString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	nowPlayingString = [nowPlayingString stringByReplacingOccurrencesOfString:@"&amp;" withString:@"&"];

	NSArray* lines = [nowPlayingString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];	
		
	if(![[lines objectAtIndex:2] isEqualToString:[nowPlayingLabel text]]) 
	{		
		[self performSelectorOnMainThread:@selector(updateNowPlayingLabel:) withObject:[lines objectAtIndex:2] waitUntilDone:YES];
	}	
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	busyLoading = NO;
}

- (void)updateNowPlayingLabel:(NSString *)track
{
	[nowPlayingLabel setText:track];
	[nowPlayingLabel sizeToFit];
	[self resetAnimation];
}

- (void)resetAnimation
{
	[[nowPlayingLabel layer] removeAllAnimations];
	scrollText = [CABasicAnimation animationWithKeyPath:@"position.x"];
	scrollText.duration = (640 + nowPlayingLabel.frame.size.width) / 60;
	scrollText.repeatCount = 10000;
	scrollText.autoreverses = NO;
	scrollText.fromValue = [NSNumber numberWithFloat:320 + (nowPlayingLabel.frame.size.width / 2)];
	scrollText.toValue = [NSNumber numberWithFloat:0 - (nowPlayingLabel.frame.size.width / 2)];
	[[nowPlayingLabel layer] addAnimation:scrollText forKey:@"scrollTextKey"];		
}

- (IBAction)channel1ButtonPressed:(id)sender
{
	[streamer stop];
	[self destroyStreamer];
	[self resetEverything];
		
	NSString *m3u = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://radio.intergalactic.fm/1aac.m3u"] 
											 encoding:NSUTF8StringEncoding
												error:nil];
	channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	channelPlaying = 1;
	savedChannelPlaying = 1;
	
	[self createStreamer];
	[streamer start];
	playing = YES;
}


- (IBAction)channel2ButtonPressed:(id)sender
{
	[streamer stop];
	[self destroyStreamer];
	[self resetEverything];
	
	NSString *m3u = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://radio.intergalactic.fm/2aac.m3u"] 
											 encoding:NSUTF8StringEncoding
												error:nil];
	channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	channelPlaying = 2;
	savedChannelPlaying = 2;
	
	[self createStreamer];
	[streamer start];
	playing = YES;
}


- (IBAction)channel3ButtonPressed:(id)sender
{
	[streamer stop];
	[self destroyStreamer];
	[self resetEverything];

	NSString *m3u = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://radio.intergalactic.fm/3aac.m3u"] 
											 encoding:NSUTF8StringEncoding
												error:nil];
	channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	channelPlaying = 3;
	savedChannelPlaying = 3;
	
	[self createStreamer];
	[streamer start];
	playing = YES;
}


- (IBAction)channel4ButtonPressed:(id)sender
{
	[streamer stop];
	[self destroyStreamer];
	[self resetEverything];

	NSString *m3u = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://radio.intergalactic.fm/4aac.m3u"] 
											 encoding:NSUTF8StringEncoding
												error:nil];
	channelSelection = [[m3u componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] objectAtIndex:0];
	channelPlaying = 4;
	savedChannelPlaying = 4;
	
	[self createStreamer];
	[streamer start];
	playing = YES;
}


- (IBAction)stopButtonPressed:(id)sender
{
	[streamer stop];
	[self destroyStreamer];
	[self performSelectorOnMainThread:@selector(resetEverything) withObject:nil waitUntilDone:YES];
	savedChannelPlaying = 0;
}


- (void)resetEverything
{
	channelPlaying = 0;
	playing = NO;
	
	[channel1Spinner setHidden:YES];
	[channel2Spinner setHidden:YES];
	[channel3Spinner setHidden:YES];
	[channel4Spinner setHidden:YES];
	
	[channel1Button setEnabled:YES];
	[channel2Button setEnabled:YES];
	[channel3Button setEnabled:YES];
	[channel4Button setEnabled:YES];
	
	[channel1StopButton setEnabled:NO];
	[channel2StopButton setEnabled:NO];
	[channel3StopButton setEnabled:NO];
	[channel4StopButton setEnabled:NO];
	
	[channel1StopButton setHidden:YES];
	[channel2StopButton setHidden:YES];
	[channel3StopButton setHidden:YES];
	[channel4StopButton setHidden:YES];
	
	nowPlayingLabel.text = @"";
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
	if(event.type == UIEventTypeRemoteControl)
	{
		switch (event.subtype)
		{
            case UIEventSubtypeRemoteControlPlay:
                break;
            case UIEventSubtypeRemoteControlPause:
				[streamer stop];
				[self destroyStreamer];
				[self resetEverything];
                break;                
            case UIEventSubtypeRemoteControlStop:
				[streamer stop];
				[self destroyStreamer];
				[self resetEverything];
                break;                
            case UIEventSubtypeRemoteControlTogglePlayPause:
			{
				if(playing)
				{
					playing = NO;
					[streamer stop];
					[self destroyStreamer];
					[self resetEverything];
				}
				else if(playing == NO && savedChannelPlaying != 0)
				{
					[self playSavedChannel];
				}
                break;                
			}
            case UIEventSubtypeRemoteControlNextTrack:
			{        
				[streamer stop];
				[self destroyStreamer];
				[self resetEverything];
				if(savedChannelPlaying < 4)
				{
					savedChannelPlaying++;
				}
				else 
				{
					savedChannelPlaying = 1;
				}
				[self playSavedChannel];
				break;
			}
            case UIEventSubtypeRemoteControlPreviousTrack:
			{        
				[streamer stop];
				[self destroyStreamer];
				[self resetEverything];
				if(savedChannelPlaying == 1)
				{
					savedChannelPlaying = 4;
				}
				else 
				{
					savedChannelPlaying--;
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
	playing = YES;
	switch (savedChannelPlaying)
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

- (void)dealloc {
    [super dealloc];
}


@end
