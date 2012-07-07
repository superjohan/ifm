//
//  FlipsideViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import "FlipsideViewController.h"

@interface FlipsideViewController ()
@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, retain) IBOutlet UIActivityIndicatorView *loadingSpinner;
@end

@implementation FlipsideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.webView.delegate = self;
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://intergalactic.fm"]]];
}

- (IBAction)done
{
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[self.webView stopLoading];
	[self.delegate flipsideViewControllerDidFinish:self];	
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload
{
	self.webView = nil;
}

- (IBAction)goBack:(id)sender
{
	[self.webView goBack];
}

- (IBAction)goForward:(id)sender
{
	[self.webView goForward];
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	self.loadingSpinner.hidden = NO;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	self.loadingSpinner.hidden = YES;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)dealloc
{
	self.webView = nil;
	
	[super dealloc];
}


@end
