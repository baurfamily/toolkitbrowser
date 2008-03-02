//
//  TKWebDocument.m
//  Web Tool Kit
//
//  Created by Eric Baur on 12/30/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "TKWebDocument.h"


@implementation TKWebDocument

- (NSString *)windowNibName
{
    return @"TKWebDocument";
}

- (NSData *)dataRepresentationOfType:(NSString *)type
{
	ENTRY( @"dataRepresentationOfType:" );
	NSMutableData *data;
	NSKeyedArchiver *archiver;
	BOOL result;

	data = [NSMutableData data];
	archiver = [[[NSKeyedArchiver alloc] initForWritingWithMutableData:data] autorelease];

	[archiver encodeObject:pageArray forKey:@"pageArray"];
	[archiver encodeObject:resourceArray forKey:@"resourceArray"];
	[archiver finishEncoding];
	
	return [data copy];
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type
{
	ENTRY( @"loadDataRepresentation:ofType:" );
	NSKeyedUnarchiver *unarchiver;

	unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];

	pageArray = [[unarchiver decodeObjectForKey:@"pageArray"] retain];
	resourceArray = [[unarchiver decodeObjectForKey:@"resourceArray"] retain];
	
	[unarchiver finishDecoding];
	[unarchiver release];
	
    return YES;
}

#pragma mark init methods

- (void)awakeFromNib
{
	
	[webView setGroupName:@"TKWebDocument"];
	if ([pageArray count]) {
		[pagesArrayController addObjects:pageArray];
		[startingPageField setStringValue:[[pageArray objectAtIndex:[pageArray count]-1] documentURLString] ];
	} else {
		[startingPageField setStringValue:@"http://"];
	}
}

- (id)init
{
	self = [super init];
	if (self) {
		pageArray = [[NSMutableArray alloc] init];
		resourceArray = [[NSMutableArray alloc] init];
		framesDict = [[NSMutableDictionary alloc] init];
		requestsDict = [[NSMutableDictionary alloc] init];
	}
	return self;
}

#pragma mark action methods

- (IBAction)go:(id)sender
{
	[statusField setStringValue:@""];

	NSString *tempString;
	if ([[startingPageField stringValue] rangeOfString:@"http"
		options:NSAnchoredSearch].location==NSNotFound )
	{
		tempString = [NSString stringWithFormat:@"http://%@",[startingPageField stringValue] ];
	} else {
		tempString = [startingPageField stringValue];
	}

	[[webView mainFrame]
		loadRequest:[NSURLRequest
			requestWithURL:[NSURL
				URLWithString:tempString
			]
		]
	];
}

- (void)loadURL:(NSURLRequest *)urlRequest
{
	INFO(NSLog( @"going to URL: %@", [urlRequest description] ));
	[[webView mainFrame] loadRequest:urlRequest];
}

- (void)setURLFromString:(NSString *)urlString
{
	ENTRY(NSLog( @"setting URL to string: %@", urlString ));
	if (urlString) {
		[startingPageField setStringValue:urlString];
		[self go:self];
	}
}

- (WebView *)webView
{
	return webView;
}

- (IBAction)addHistoryToReplay:(id)sender	//CURRENTLY ADD ALL
{
	//this might get more than I want (subResources & resources as well)
	NSEnumerator *en = [pageArray objectEnumerator];
	ResourceEvent *re;
	
	//clear out current array
	[replayArrayController removeObjects:[replayArrayController arrangedObjects] ];
	
	while ( re = [en nextObject] ) {
		[replayArrayController addObject:[[ReplayEvent alloc] initWithURL:[re valueForKey:@"resourceRequest"] ] ];
	}
/*	
	NSIndexSet *selectedRowIndexes = [resourceOutlineView selectedRowIndexes];
	if (![selectedRowIndexes count])
		return;
	
	int index = -1;
	while((index = [selectedRowIndexes indexGreaterThanIndex:index]) != NSNotFound) {
		NSLog( @"looking at index: %d", index );
	}
*/
}

#pragma mark frame delegate methods

- (void)webView:(WebView *)sender didReceiveTitle:(NSString *)title forFrame:(WebFrame *)frame
{
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];
	if (!currentPage) {
		WARNING( @"no current page to set title for!" );
	} else {
		[currentPage setTitle:title];
	}
}

- (void)webView:(WebView *)sender didStartProvisionalLoadForFrame:(WebFrame *)frame
{
	[statusField setStringValue:@""];
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];
	
	if ( currentPage && ![currentPage isDoneLoading] ) {
		WARNING( @"page not done loading" );
		[currentPage notFinishedLoadingWithDataSource:[frame dataSource] ];
		NSView *tempView = [[[sender mainFrame] frameView] documentView] ;
		[currentPage setPageImageData:
			[tempView dataWithPDFInsideRect:[tempView bounds] ]
		];
	}
	[currentPage release];
	currentPage = [[ResourceEvent
			resourceEventWithURLRequest:[[frame provisionalDataSource] request]
		] retain
	];
	//[pageArray addObject:currentPage];
	[pagesArrayController addObject:currentPage];
	[framesDict setObject:currentPage forKey:[frame description]];
	[progressBar setHidden:NO];
	
	if (currentPage &&[frame parentFrame] && ![[framesDict objectForKey:[[frame parentFrame] description]] isDoneLoading]) {
		ResourceEvent *tempEvent = [framesDict objectForKey:[[frame parentFrame] description]];
		[tempEvent addSubResourceEvent:currentPage];
	} else {
		[pageArray addObject:currentPage];
		//[pagesArrayController addObject:currentPage];
	}
}

- (void)webView:(WebView *)sender didCommitLoadForFrame:(WebFrame *)frame
{
	[[framesDict objectForKey:[frame description]] resourceCommitted];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	// I think we're going to want more (or different) stuff than this
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];
	[currentPage finishedLoadingWithDataSource:[frame dataSource] ];
	NSView *tempView = [[[sender mainFrame] frameView] documentView] ;
	[currentPage setPageImageData:
		[tempView dataWithPDFInsideRect:[tempView bounds] ]
	];
	[progressBar setHidden:YES];
	
	[sender setNeedsDisplay:YES];
	
	[delegate webDocument:self didFinishLoadingURL:[currentPage valueForKey:@"resourceRequest"] ];
}

#pragma mark frame delegate methods - errors

- (void)webView:(WebView *)sender serverRedirectedForDataSource:(WebFrame *)frame
{
	ENTRY( @"- (void)webView:(WebView *)sender serverRedirectedForDataSource:(WebFrame *)frame" );
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	WARNING( @"failed load" );
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];
	[currentPage finishedLoadingWithError:error];
	[statusField setStringValue:[error localizedDescription] ];
	[progressBar setHidden:YES];
}

- (void)webView:(WebView *)sender didFailProvisionalLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	WARNING( @"failed provisional load" );
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];
	[currentPage finishedLoadingWithError:error];
	[statusField setStringValue:[error localizedDescription] ];
	[progressBar setHidden:YES];
}

#pragma mark UI delegate methods
/*
- (WebView *)webView:(WebView *)sender createWebViewWithRequest:(NSURLRequest *)request
{
	ENTRY(( @"createWebViewWithRequest: %@", [request description] ));
    TKWebDocument *myDocument = [[NSDocumentController sharedDocumentController] newDocument:self];
	[myDocument setURLFromString:[[request URL] absoluteString] ];
    return [myDocument webView];
}
*/
- (void)webViewShow:(WebView *)sender
{
	ENTRY( @"webViewShow:" );
    id myDocument = [[NSDocumentController sharedDocumentController] documentForWindow:[sender window]];
    [myDocument showWindows];
}

#pragma mark policy delegate methods

- (void)webView:(WebView *)sender decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener
{
	//NSLog( @"--- checking %@ ---", type );
	if ([[exclusionsArrayController arrangedObjects] count]) {
		NSEnumerator *en = [[exclusionsArrayController arrangedObjects] objectEnumerator];
		NSDictionary *tempDict;
		NSString *tempString;
		while (tempDict=[en nextObject]) {
			tempString = [tempDict objectForKey:@"MIMEType"];
			NSLog( @"comparing %@ to %@", tempString, type );
			if (tempString && [type rangeOfString:tempString
				options:NSAnchoredSearch].location!=NSNotFound
			) {
				NSLog( @"skipping mime type: %@", type );
				[listener ignore];
			}
		}
	}
	[listener use];
	//NSLog( @"--- done checking ---" );
}

- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id)listener
{
	//NSLog( @"- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener" );
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];//WithDictionary:actionInformation];
	ResourceEvent *currentPage = [framesDict objectForKey:[frame description]];

	[listener use];
	
	[tempDict setObject:request forKey:@"NSURLRequest"];
	
	id tempObject;
	
	//things from actionInformation.WebActionElementKey
	if (tempObject = [actionInformation valueForKeyPath:@"WebActionElementKey.WebElementLinkURL"])
		[tempDict setObject:tempObject forKey:@"linkURL"];
	
	if (tempObject = [actionInformation valueForKeyPath:@"WebActionElementKey.WebElementLinkLabel"])
		[tempDict setObject:tempObject forKey:@"linkLabel"];
		
	if (tempObject = [actionInformation valueForKeyPath:@"WebActionElementKey.WebElementImageURL"])
		[tempDict setObject:tempObject forKey:@"imageURL"];
		
	if (tempObject = [actionInformation valueForKeyPath:@"WebActionElementKey.WebElementImageAltString"])
		[tempDict setObject:tempObject forKey:@"imageAltString"];
	
	//other things from actionInformation	
	if (tempObject = [actionInformation valueForKeyPath:@"WebActionOriginalURLKey"])
		[tempDict setObject:tempObject forKey:@"originalURL"];
	
	//things from NSURLRequest
	if (tempObject = [request HTTPMethod])
		[tempDict setObject:tempObject forKey:@"httpMethod"];
		
	if (tempObject = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding])
		[tempDict setObject:tempObject forKey:@"httpBodyString"];
	
	if (tempObject = [[request URL] absoluteString])
		[tempDict setObject:tempObject forKey:@"requestURLString"];
		
	if (tempObject = [[request mainDocumentURL] absoluteString])
		[tempDict setObject:tempObject forKey:@"documentURLString"];
	
	switch ([[actionInformation objectForKey:@"WebActionNavigationTypeKey"] intValue]) {
		case WebNavigationTypeLinkClicked:
			[tempDict setObject:@"Link Clicked" forKey:@"navigationString"];
			break;
		case WebNavigationTypeFormSubmitted:
			[tempDict setObject:@"Form Submitted" forKey:@"navigationString"];
			break;
		case WebNavigationTypeBackForward:
			[tempDict setObject:@"Back/Forward" forKey:@"navigationString"];
			break;
		case WebNavigationTypeReload:
			[tempDict setObject:@"Reload" forKey:@"navigationString"];
			break;
		case WebNavigationTypeFormResubmitted:
			[tempDict setObject:@"Form Resubmitted" forKey:@"navigationString"];
			break;
		case WebNavigationTypeOther:
			[tempDict setObject:@"Other" forKey:@"navigationString"];
			break;
		default:
			[tempDict setObject:@"-= Unknown =-" forKey:@"navigationString"];
	}

	[actionsArrayController addObject:tempDict];
	
	[[requestsDict objectForKey:request] addActionDictionary:tempDict];
	[currentPage addActionDictionary:tempDict];
}
/*
- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id)listener
{
	//NSLog( @"- (void)webView:(WebView *)sender decidePolicyForNewWindowAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request newFrameName:(NSString *)frameName decisionListener:(id<WebPolicyDecisionListener>)listener" );
	[listener use];
}

- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame
{
	NSLog( @"- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame" );
}
*/
#pragma mark resource delegate methods

- (id)webView:(WebView *)sender identifierForInitialRequest:(NSURLRequest *)request
	fromDataSource:(WebDataSource *)dataSource
{
	ResourceEvent *currentPage = [framesDict objectForKey:[[dataSource webFrame] description] ];
	ResourceEvent *tempEvent = [ResourceEvent resourceEventWithURLRequest:request];
	[currentPage addSubResourceEvent:tempEvent];
	[activityArrayController addObject:tempEvent];
	[requestsDict setObject:tempEvent forKey:request];

	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
	[tempDict setObject:request forKey:@"NSURLRequest"];
	id tempObject;
	
	//things from NSURLRequest
	if (tempObject = [request HTTPMethod])
		[tempDict setObject:tempObject forKey:@"httpMethod"];
		
	if (tempObject = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding])
		[tempDict setObject:tempObject forKey:@"httpBodyString"];
	
	if (tempObject = [[request URL] absoluteString])
		[tempDict setObject:tempObject forKey:@"reqeuestURLString"];
		
	if (tempObject = [[request mainDocumentURL] absoluteString])
		[tempDict setObject:tempObject forKey:@"documentURLString"];
	
	//a made up action/navigation string
	[tempDict setObject:@"Resource Request" forKey:@"navigationString"];

	[actionsArrayController addObject:tempDict];
	
	return tempEvent;
}

-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier
	willSendRequest:(NSURLRequest *)request
	redirectResponse:(NSURLResponse *)redirectResponse
	fromDataSource:(WebDataSource *)dataSource
{
	NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];//WithDictionary:actionInformation];
	
	[tempDict setObject:request forKey:@"NSURLRequest"];
	
	id tempObject;
		
	//things from NSURLRequest
	if (tempObject = [request HTTPMethod])
		[tempDict setObject:tempObject forKey:@"httpMethod"];
		
	if (tempObject = [[NSString alloc] initWithData:[request HTTPBody] encoding:NSASCIIStringEncoding])
		[tempDict setObject:tempObject forKey:@"httpBodyString"];
	
	if (tempObject = [[request URL] absoluteString])
		[tempDict setObject:tempObject forKey:@"requestURLString"];
		
	if (tempObject = [[request mainDocumentURL] absoluteString])
		[tempDict setObject:tempObject forKey:@"documentURLString"];
	
	//a made up action/navigation string
	[tempDict setObject:@"Resource Request" forKey:@"navigationString"];
	
	[actionsArrayController addObject:tempDict];
	
	[identifier addActionDictionary:tempDict];

	return request;
}

-(void)webView:(WebView *)sender resource:(id)identifier
	didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource
{
	//NSLog( @"-(void)webView:(WebView *)sender resource:(id)identifier didReceiveResponse:(NSURLResponse *)response fromDataSource:(WebDataSource *)dataSource" );
	[identifier resourceCommitted];
	[identifier setResponse:response];
	[activityArrayController removeObject:identifier];
}

-(void)webView:(WebView *)sender resource:(id)identifier
	didFinishLoadingFromDataSource:(WebDataSource *)dataSource
{
	[identifier finishedLoadingWithDataSource:dataSource ];
	[resourceOutlineView reloadData];
	[activityArrayController removeObject:identifier];
}

-(void)webView:(WebView *)sender resource:(id)identifier
	didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
	fromDataSource:(WebDataSource *)dataSource
{
	//NSLog( @"***webView:resource:didReceiveAuthenticationChallenge:fromDataSource:" );
}

#pragma mark resource delegate methods - errors

-(void)webView:(WebView *)sender resource:(id)identifier
	didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource
{
	//NSLog( @"webView:resource:didFailLoadingWithError:fromDataSource:" );
	[identifier finishedLoadingWithError:error];
	[activityArrayController removeObject:identifier];
}

#pragma mark outline view datasource methods

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if (item)
		return [item hasSubResources];
	else
		return NO;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (item) {
		return [item numberOfSubResources];
	} else {
		return [pageArray count];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item
{
	if (item)
		return [item subResourceAtIndex:index];
	else
		return [pageArray objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (item) {
		return [item valueForKey:[tableColumn identifier] ];	
	} else {
		return nil;
	}
}

#pragma mark outline view delegate methods

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if ([item isImage]) {
		[documentTabView selectTabViewItemWithIdentifier:@"graphics"];
		[documentImageView setImage:[[[NSImage alloc] initWithData:[item data]] autorelease] ];
	} else if ([item isPage]) {
		[documentTabView selectTabViewItemWithIdentifier:@"graphics"];
		[documentImageView setImage:[item pageImage] ];
	} else {
		[documentTabView selectTabViewItemWithIdentifier:@"text"];
		[[documentTextView textStorage] 
			replaceCharactersInRange:NSMakeRange(0,[[[documentTextView textStorage] string] length])
			withAttributedString:[item dataAsAttributedString]
		];
	}
	[pagesArrayController setSelectedObjects:[NSArray arrayWithObject:item] ];
	//[resourcesArrayController setSelectedObjects:[NSArray arrayWithObject:item] ];

	[self willChangeValueForKey:@"selectedItem"];
	selectedItem = [item retain];
	[self didChangeValueForKey:@"selectedItem"];
	
	return YES;
}

#pragma mark testing methods

- (void)webView:(WebView *)sender
	mouseDidMoveOverElement:(NSDictionary *)elementInformation
	modifierFlags:(unsigned int)modifierFlags
{
	//nothing for now...
}

@end
