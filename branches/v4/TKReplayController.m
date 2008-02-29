//
//  TKReplayController.m
//  Web Tool Kit
//
//  Created by Eric Baur on 10/23/05.
//  Copyright 2005 Eric Shore Baur. All rights reserved.
//

#import "TKReplayController.h"


@implementation TKReplayController

#pragma mark initilization methods

- (id)init
{
	self = [super init];
	if (self) {
		currentStep = 0;
		isRunning = NO;
	}
	return self;
}

#pragma mark action methods

- (IBAction)toggleReplay:(id)sender
{
	ENTRY(NSLog( @"[TKReplayController toggleReplay:]" ));
	isRunning = !isRunning;
	if (isRunning)
		[self nextStep:self];
}

- (IBAction)nextStep:(id)sender
{
	ENTRY(NSLog( @"[TKReplayController nextStep:]" ));
	NSArray *replayArray = [replayArrayController arrangedObjects];
	
	ReplayEvent *re = [replayArray objectAtIndex:currentStep];
	
	NSURLRequest *tempURL = [re valueForKey:@"urlRequest"];
	
	INFO(NSLog( @"loading URL: %@", [tempURL description] ));
	
	[re start];
	[webDoc loadURL:tempURL ];
	
	currentStep++;
	if (currentStep >= [replayArray count]) {
		currentStep = 0;
		if (!isContinuous) {
			isRunning = NO;
			return;
		}
	}
}

- (IBAction)saveScript:(id)sender
{
	NSMutableArray *tempArray = [NSMutableArray array];

	[[replayArrayController arrangedObjects]
		makeObjectsPerformSelector:@selector(addDictionaryToArray:)
		withObject:tempArray
	];

	[tempArray writeToFile:@"/tmp/temp.plist" atomically:YES];
}

- (IBAction)loadScript:(id)sender
{

}


#pragma mark delegate methods

- (void)webDocument:(TKWebDocument *)theWebDoc didFinishLoadingURL:(NSURLRequest *)urlRequest
{
	ENTRY(NSLog( @"webDocument:didFinishLoadingURL: %@", [urlRequest description] ));

	if (!isRunning)
		return;

	// this is probably overkill...
	int lastStep;
	if (currentStep)
		lastStep = currentStep-1;
	else
		lastStep = [[replayArrayController arrangedObjects] count] - 1;
		
	ReplayEvent *re = [[replayArrayController arrangedObjects] objectAtIndex:lastStep];

	if (![urlRequest isEqualTo:[re valueForKey:@"urlRequest"]])
		NSLog( @"URL finished did not match current ReplayEvent URL (stopping anyway)" );
		
	[re stop];
	
	if (isRunning)
		[self nextStep:self];
		
	[replayTable reloadData];
	[replayTable selectRowIndexes:[NSIndexSet indexSetWithIndex:lastStep] byExtendingSelection:NO];
}

@end
