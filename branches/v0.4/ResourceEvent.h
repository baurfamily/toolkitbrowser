//
//  ResourceEvent.h
//  Web Tool Kit
//
//  Created by Eric Baur on 12/30/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

typedef enum {
	REUndeterminedResourceType	=-2,
	REUnknownResourceType		=-1,
	REPageReourceType			=0,
	REImageResourceType			=1,
	REStylesheetResourceType	=2,
	REJavascriptResourceType	=3,
	RETextResourceType			=4
} REResourceType;

static unsigned int resourceIDcount;

@interface ResourceEvent : NSObject {
	unsigned int resourceID;

	NSDate *startDate;
	NSDate *commitDate;
	NSDate *endDate;
	
	REResourceType resourceType;
	
	NSData *resourceData;
	NSURLRequest *resourceRequest;
	NSURLResponse *resourceResponse;

	NSDictionary *httpHeaderFieldsDict;
	NSArray *cookiesArray;
	
	NSString *resourceURL;
	NSString *resourceTitle;
	NSString *resourceFilename;
	NSString *resourceMIMEType;
	
	id resourceRepresentation;
	NSData *pageImageData;
	
	NSString *resourceErrorString;
	
	NSMutableArray *subResources;
	NSMutableArray *actionsArray;
}

+ (id)resourceEventWithURLRequest:(NSURLRequest *)urlRequest;
//+ (id)resourceEventWithURLString:(NSString *)URLString;

- (id)init;
- (id)initWithResourceURLRequest:(NSURLRequest *)urlRequest;
//- (id)initWithResourceURLString:(NSString *)URLString;

- (void)finishedLoadingWithError:(NSError *)error;
- (void)resourceCommitted;
- (void)finishedLoadingWithDataSource:(WebDataSource *)dataSource;
- (void)notFinishedLoadingWithDataSource:(WebDataSource *)dataSource;
- (void)setResponse:(NSURLResponse *)response;
- (void)setPageImageData:(NSData *)data;

- (void)addSubResourceEvent:(ResourceEvent *)newEvent;

- (void)addActionDictionary:(NSDictionary *)actionDict;

//accessor fuctions

- (NSArray *)allActionsArray;

- (void)setTitle:(NSString *)title;

- (NSDate *)startDate;
- (NSDate *)endDate;

- (double)waittime;
- (double)loadtime;
- (double)totaltime;

- (double)bytesPerSecond;
- (double)effectiveBytesPerSecond;

- (int)numberOfSubResources;
- (ResourceEvent *)subResourceAtIndex:(int)index;

- (NSString *)url;
- (NSString *)title;
- (NSString *)name;
- (NSString *)suggestedFilename;
- (NSString *)MIMEType;
- (NSString *)requestBody;
- (NSString *)documentURLString;
- (NSString *)requestMethod;

- (NSString *)dataAsString;
- (NSAttributedString *)dataAsAttributedString;
- (NSImage *)pageImage;
- (NSString *)error;
- (unsigned int)ID;

- (BOOL)isPage;
- (BOOL)isImage;

- (BOOL)isDoneLoading;
- (BOOL)hasSubResources;

- (BOOL)hasTitle;
@end
