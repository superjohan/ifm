//
//  FlipsideViewController.m
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import "FlipsideViewController.h"


@implementation FlipsideViewController

@synthesize delegate;
@synthesize webView;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[webView setDelegate:self];
	NSString *urlAddress = @"http://intergalacticfm.com/";
	NSURL *url = [NSURL URLWithString:urlAddress];
	NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
	[webView loadRequest:requestObj];
}


- (IBAction)done {
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	[webView stopLoading];
	[self.delegate flipsideViewControllerDidFinish:self];	
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void)viewDidUnload {
	self.webView = nil;
}


- (IBAction)goBack:(id)sender {
	[webView goBack];
}


- (IBAction)goForward:(id)sender {
	[webView goForward];
}


- (void)webViewDidStartLoad:(UIWebView *)webView {
	[loadingSpinner setHidden:NO];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[loadingSpinner setHidden:YES];
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


- (void)dealloc {
    [super dealloc];
	[webView release];
}


@end
