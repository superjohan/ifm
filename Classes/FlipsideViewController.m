//
//  FlipsideViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Aero Deko 2012. All rights reserved.
//

#import "FlipsideViewController.h"

@interface FlipsideViewController ()
@property (nonatomic, strong) IBOutlet UIWebView *webView;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, strong) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *loadingSpinner;
@end

@implementation FlipsideViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.webView.delegate = self;
	[self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://intergalacticfm.com"]]];
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



@end
