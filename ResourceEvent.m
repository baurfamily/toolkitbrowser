//
//  ResourceEvent.m
//  Web Tool Kit
//
//  Created by Eric Baur on 12/30/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "ResourceEvent.h"

@implementation ResourceEvent

+ (void)initilize
{
	resourceIDcount = 0;
}

+ (id)resourceEventWithURLRequest:(NSURLRequest *)urlRequest
{
	ResourceEvent *tempEvent;
	tempEvent = [[[ResourceEvent alloc] initWithResourceURLRequest:urlRequest] autorelease];
	return tempEvent;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeInt32:resourceID forKey:@"resourceID"];

	[encoder encodeObject:startDate forKey:@"startDate"];
	[encoder encodeObject:commitDate forKey:@"commitDate"];
	[encoder encodeObject:endDate forKey:@"endDate"];

	[encoder encodeInt32:resourceType forKey:@"resourceType"];
	
	[encoder encodeObject:resourceData forKey:@"resourceData"];
	[encoder encodeObject:resourceRequest forKey:@"resourceRequest"];
	[encoder encodeObject:resourceResponse forKey:@"resourceResponse"];
	
	[encoder encodeObject:resourceURL forKey:@"resourceURL"];
	[encoder encodeObject:resourceTitle forKey:@"resourceTitle"];
	[encoder encodeObject:resourceFilename forKey:@"resourceFilename"];
	[encoder encodeObject:resourceMIMEType forKey:@"resourceMIMEType"];

	if ([resourceRepresentation respondsToSelector:@selector(encodeObject:forKey:)])
		[encoder encodeObject:resourceRepresentation forKey:@"resourceRepresentation"];
		
	[encoder encodeObject:pageImageData forKey:@"pageImageData"];

	[encoder encodeObject:resourceErrorString forKey:@"resourceErrorString"];

	[encoder encodeObject:subResources forKey:@"subResources"];
	[encoder encodeObject:actionsArray forKey:@"actionsArray"];
	
	[encoder encodeObject:httpHeaderFieldsDict forKey:@"httpHeaderFieldsDict"];
	[encoder encodeObject:cookiesArray forKey:@"cookiesArray"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	if (self) {
		resourceID = [decoder decodeInt32ForKey:@"resourceID"];

		startDate = [[decoder decodeObjectForKey:@"startDate"] retain];
		commitDate = [[decoder decodeObjectForKey:@"commitDate"] retain];
		endDate = [[decoder decodeObjectForKey:@"endDate"] retain];

		resourceType = [decoder decodeInt32ForKey:@"resourceType"];
		
		resourceData = [[decoder decodeObjectForKey:@"resourceData"] retain];
		resourceRequest = [[decoder decodeObjectForKey:@"resourceRequest"] retain];
		resourceResponse = [[decoder decodeObjectForKey:@"resourceResponse"] retain];
		
		resourceURL = [[decoder decodeObjectForKey:@"resourceURL"] retain];
		resourceTitle = [[decoder decodeObjectForKey:@"resourceTitle"] retain];
		resourceFilename = [[decoder decodeObjectForKey:@"resourceFilename"] retain];
		resourceMIMEType = [[decoder decodeObjectForKey:@"resourceMIMEType"] retain];

		resourceRepresentation = [[decoder decodeObjectForKey:@"resourceRepresentation"] retain];
		pageImageData = [[decoder decodeObjectForKey:@"pageImageData"] retain];

		resourceErrorString = [[decoder decodeObjectForKey:@"resourceErrorString"] retain];

		subResources = [[decoder decodeObjectForKey:@"subResources"] retain];
		actionsArray = [[decoder decodeObjectForKey:@"actionsArray"] retain];
		
		httpHeaderFieldsDict = [[decoder decodeObjectForKey:@"httpHeaderFieldsDict"] retain];
		cookiesArray = [[decoder decodeObjectForKey:@"cookiesArray"] retain];
	}
	return self;
}

- (id)init
{
	NSLog( @"[ResourceEvent init] - can't have an empty URL!" );
	return nil;
}

- (id)initWithResourceURLRequest:(NSURLRequest *)urlRequest
{
	ENTRY( @"[ResourceEvent initWithURLRequest:]" );
	self = [super init];
	if (self) {
		startDate = [[NSDate alloc] init];
		endDate = nil;
		resourceData = nil;
		resourceType = REUndeterminedResourceType;
		resourceURL = [[[urlRequest URL] absoluteString] retain];
		resourceRequest = [urlRequest retain];
		
		DEBUG(( @"HTTPHeaderFields:\n%@", [[urlRequest allHTTPHeaderFields] description] ));
		DEBUG(( @"HTTPBody:\n%@", [[urlRequest HTTPBody] description] ));
		DEBUG(( @"HTTPMethod:\n%@", [[urlRequest HTTPMethod] description] ));
		
		httpHeaderFieldsDict = [[urlRequest allHTTPHeaderFields] retain];
		cookiesArray = [[[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[urlRequest URL] ] retain];
		
		resourceErrorString = nil;
		
		subResources = [[NSMutableArray array] retain];
		actionsArray = [[NSMutableArray array] retain];
		resourceID = resourceIDcount++;
	}
	return self;
}

#pragma mark processing methods

- (void)resourceCommitted
{
	if (!commitDate)
		commitDate = [[NSDate alloc] init];
}

- (void)finishedLoadingWithError:(NSError *)error
{
	ENTRY( @"[ResourceEvent finishedLoadingWithError:]" );
	WARNING( [error localizedDescription] );
	endDate = [[NSDate alloc] init];
	resourceErrorString = [[error localizedDescription] retain];
}

- (void)finishedLoadingWithDataSource:(WebDataSource *)dataSource
{
	ENTRY( @"[ResourceEvent finishedLoadingWithDataSource:]" );
	endDate = [[NSDate alloc] init];

	resourceRequest = [[dataSource request] retain];	
	resourceRepresentation = [[dataSource representation] retain];
}

- (void)notFinishedLoadingWithDataSource:(WebDataSource *)dataSource
{
	[self finishedLoadingWithDataSource:dataSource];
}

- (void)setResponse:(NSURLResponse *)response
{
	ENTRY( @"[ResourceEvent setResponse:]" );
	resourceResponse = [response retain];
	
	resourceFilename = [[resourceResponse suggestedFilename] retain];
	resourceMIMEType = [[resourceResponse MIMEType] retain];
	
	if ([resourceMIMEType rangeOfString:@"image" options:NSAnchoredSearch].location!=NSNotFound) {
		resourceType = REImageResourceType;
	}
	
	resourceData = [[NSData dataWithContentsOfURL:[resourceResponse URL]] retain];
}

- (void)setPageImageData:(NSData *)data
{
	if (pageImageData) {
		NSLog( @"[ResourceEvent setPageImage:] - already have a page image" );
		[pageImageData release];
	}
	pageImageData = [data retain];
	resourceType = REPageReourceType;
}

- (void)addSubResourceEvent:(ResourceEvent *)newEvent
{
	[subResources addObject:newEvent];
}

- (void)addActionDictionary:(NSDictionary *)actionDict
{
	ENTRY( @"addActionDictionary:" );
	[actionsArray addObject:actionDict];
}

- (void)setTitle:(NSString *)title
{
	ENTRY( @"[ResourceEvent setTitle:]" );
	if (resourceTitle) {
		NSLog( @"[ResourceEvent setTitle:] - title already set" );
		[resourceTitle release];
	}
	resourceTitle = [title retain];
	resourceType = REPageReourceType;
}

#pragma mark meta-accessor methods

- (NSArray *)allActionsArray
{
	NSMutableArray *tempArray;
	
	tempArray = [actionsArray mutableCopy];

	ResourceEvent *re;
	NSEnumerator *en = [subResources objectEnumerator];
	while ( re = [en nextObject] ) {
		[tempArray addObjectsFromArray:[re valueForKeyPath:@"actionsArray"] ];
	}

	
	return [tempArray copy];
}

#pragma mark value methods

- (id)valueForUndefinedKey:(NSString *)key
{
	WARNING(( @"ResourceEvent - couldn't find key: %@", key ));
	return @"no value";
}

- (NSDate *)startDate
{
	return startDate;
}

- (NSDate *)endDate
{
	return endDate;
}

- (double)waittime
{
	//this should return a negative value if the resource is not done loading yet
	if (commitDate) {
		return [commitDate timeIntervalSinceDate:startDate];
	} else if (endDate) {
		return [endDate timeIntervalSinceDate:startDate];
	} else {
		return [startDate timeIntervalSinceNow];
	}
}

- (double)loadtime
{
	//this should return a negative value if the resource is not done loading yet
	if (endDate) {
		return [endDate timeIntervalSinceDate:commitDate];
	} else {
		return [commitDate timeIntervalSinceNow];
	}
}

- (double)totaltime
{
	//this should return a negative value if the resource is not done loading yet
	if (endDate) {
		return [endDate timeIntervalSinceDate:startDate];
	} else {
		return [startDate timeIntervalSinceNow];
	}
}

- (double)bytesPerSecond
{
	return [resourceData length] / [self loadtime] / 1024;
}

- (double)effectiveBytesPerSecond
{
	return [resourceData length] / [self totaltime] / 1024;
}

- (int)numberOfSubResources
{
	return [subResources count];
}

- (ResourceEvent *)subResourceAtIndex:(int)index
{
	return [subResources objectAtIndex:index];
}

- (NSString *)url
{
	return resourceURL;
}

- (NSString *)title
{
	if (resourceTitle)
		return resourceTitle;
	else
		return resourceFilename;
}

- (NSString *)name	//this may not be necessary
{
	NSArray *tempArray = [resourceURL pathComponents];
	return [tempArray objectAtIndex:[tempArray count]-1];
}

- (NSString *)suggestedFilename
{
	return resourceFilename;
}

- (NSString *)MIMEType
{
	return resourceMIMEType;
}

- (NSString *)requestBody
{
	return [[[NSString alloc] initWithData:[resourceRequest HTTPBody] encoding:NSASCIIStringEncoding] autorelease];
}

- (NSString *)documentURLString
{
	return [[resourceRequest mainDocumentURL] absoluteString];
}

- (NSString *)requestMethod
{
	return [resourceRequest HTTPMethod];
}

#pragma mark data value methods

- (NSData *)data
{
	return resourceData;
}

- (NSString *)dataAsString
{
	return [[[NSString alloc] initWithData:resourceData encoding:NSASCIIStringEncoding] autorelease];
}

- (NSAttributedString *)dataAsAttributedString
{
	NSMutableAttributedString *tempString = [[[NSMutableAttributedString alloc] init] autorelease];

	[tempString 
		appendAttributedString:[[[NSAttributedString alloc]
			initWithString:[[[NSString alloc]
				initWithData:resourceData
				encoding:NSASCIIStringEncoding
			] autorelease]
			attributes:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSColor blackColor], NSForegroundColorAttributeName,
				[NSFont fontWithName:@"Courier" size:12.0], NSFontAttributeName,
				nil
			]
		] autorelease]
	];
	
	return [tempString copy];
}

- (NSImage *)pageImage
{
	return [[[NSImage alloc] initWithData:pageImageData] autorelease];
}

- (NSString *)error
{
	return resourceErrorString;
}

- (unsigned int)ID
{
	return resourceID;
}

#pragma mark boolean methods

- (BOOL)isPage
{
	return (resourceType==REPageReourceType);
}

- (BOOL)isImage
{
	return (resourceType==REImageResourceType);
}

- (BOOL)isDoneLoading
{
	return (endDate!=nil);
}

- (BOOL)hasSubResources
{
	return ( [subResources count] > 0 );
}

- (BOOL)hasTitle
{
	return (resourceTitle!=nil);
}

@end
