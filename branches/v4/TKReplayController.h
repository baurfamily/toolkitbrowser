//
//  TKReplayController.h
//  Web Tool Kit
//
//  Created by Eric Baur on 10/23/05.
//  Copyright 2005 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "TKWebDocument.h"

@interface TKReplayController : NSObject <TKWebDocumentDelegate> {
	IBOutlet TKWebDocument *webDoc;
	IBOutlet NSArrayController *replayArrayController;
	IBOutlet NSTableView *replayTable;

	int currentStep;
	BOOL isRunning;
	BOOL isContinuous;
	
	int numberOfLoops;
}

- (IBAction)toggleReplay:(id)sender;
- (IBAction)nextStep:(id)sender;

- (IBAction)saveScript:(id)sender;
- (IBAction)loadScript:(id)sender;

- (void)webDocument:(TKWebDocument *)theWebDoc didFinishLoadingURL:(NSURLRequest *)urlRequest;


@end
