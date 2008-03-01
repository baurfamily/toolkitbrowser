//
//  TKWebDocument.h
//  Web Tool Kit
//
//  Created by Eric Baur on 12/30/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

#import "ReplayEvent.h"
#import "ResourceEvent.h"

@protocol TKWebDocumentDelegate
- (void)webDocument:(id)theWebDoc didFinishLoadingURL:(NSURLRequest *)urlRequest;
@end

@interface TKWebDocument : NSDocument
{
	unsigned int resourceCount;
	
	IBOutlet NSOutlineView *resourceOutlineView;
	IBOutlet NSTextField *startingPageField;
	IBOutlet NSTextView *documentTextView;
	IBOutlet NSImageView *documentImageView;
	IBOutlet NSTabView *documentTabView;
	IBOutlet WebView *webView;
	IBOutlet NSTextField *statusField;
	IBOutlet NSProgressIndicator *progressBar;
	
	IBOutlet NSArrayController *pagesArrayController;
	IBOutlet NSArrayController *resourcesArrayController;
	IBOutlet NSArrayController *activityArrayController;
	IBOutlet NSArrayController *exclusionsArrayController;
	IBOutlet NSArrayController *actionsArrayController;
	//IBOutlet NSArrayController *actionElementsArrayController;
	IBOutlet NSArrayController *replayArrayController;
	
	IBOutlet id<TKWebDocumentDelegate> delegate;
	//delegate must implement:
	//	- (void)webDocument:(TKWebDocument *)webDoc didFinishLoadingURL:(NSURLRequest)urlRequest
	
	NSMutableArray *pageArray;
	NSMutableArray *resourceArray;
	//NSMutableArray *actionsArray;
	
	//ResourceEvent *currentPage;
	NSMutableDictionary *framesDict;
	
	ResourceEvent *selectedPage;
}
- (IBAction)go:(id)sender;
- (void)loadURL:(NSURLRequest *)urlRequest;
- (void)setURLFromString:(NSString *)urlString;
- (WebView *)webView;
- (IBAction)addHistoryToReplay:(id)sender;

@end
