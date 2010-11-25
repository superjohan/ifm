//
//  FlipsideViewController.h
//  IFM Player
//
//  Created by Johan Halin on 15.02.2010.
//  Copyright Parasol 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController <UIWebViewDelegate> {
	id <FlipsideViewControllerDelegate> delegate;
	IBOutlet UIWebView *webView;
	IBOutlet UIBarButtonItem *backButton;
	IBOutlet UIBarButtonItem *forwardButton;
	IBOutlet UIActivityIndicatorView *loadingSpinner;
}

@property (nonatomic, retain) UIWebView *webView;

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
- (IBAction)done;
- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;

@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

