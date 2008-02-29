//
//  ReplayEvent.m
//  Web Tool Kit
//
//  Created by Eric Baur on 10/23/05.
//  Copyright 2005 Eric Shore Baur. All rights reserved.
//

#import "ReplayEvent.h"

static unsigned int replayEventCount;

@implementation ReplayEvent

#pragma mark initilization methods

+ (void)initialize
{
	replayEventCount = 0;
	
	[self setKeys:[NSArray arrayWithObject:@"start"]
		triggerChangeNotificationsForDependentKey:@"startTime"];
	
	[self setKeys:[NSArray arrayWithObject:@"stop"]
		triggerChangeNotificationsForDependentKey:@"endTime"];
	[self setKeys:[NSArray arrayWithObject:@"stop,endTime"]
		triggerChangeNotificationsForDependentKey:@"lastTime"];
	[self setKeys:[NSArray arrayWithObject:@"stop,endTime"]
		triggerChangeNotificationsForDependentKey:@"totalTime"];
	[self setKeys:[NSArray arrayWithObject:@"stop,endTime"]
		triggerChangeNotificationsForDependentKey:@"averageTime"];
	[self setKeys:[NSArray arrayWithObject:@"stop,endTime"]
		triggerChangeNotificationsForDependentKey:@"completed"];
		
}

- (id)init
{
	self = [super init];
	if (self) {
		step = replayEventCount++;
		//current = 0;
		//total = 1;
		
		lastTime = 0;
		averageTime = 0;
		
		name = nil;
		urlRequest = nil;

		timingArray = [[NSMutableArray array] retain];
	}
	return self;
}

- (id)initWithURL:(NSURLRequest *)url
{
	self = [self init];
	if (self ) {
		INFO(NSLog( @"set URL to: %@", url ));
		urlRequest = [url retain];
	}
	return self;
}

- (id)initWithSettingsFromDictionary:(NSDictionary *)settingsDict
{
	self = [self init];
	if (self) {	
		NSMutableURLRequest *tempURL = [NSMutableURLRequest
			requestWithURL:[settingsDict valueForKey:@"url"]
		];
		[tempURL setHTTPMethod:[settingsDict valueForKey:@"method"] ];
		[tempURL setHTTPBody:[[settingsDict valueForKey:@"body"] dataUsingEncoding:NSASCIIStringEncoding] ];
		urlRequest = [tempURL copy];
		
		name = [settingsDict valueForKey:@"identifier"];
		if ([name isEqualToString:[settingsDict valueForKey:@"url"] ])
			name = nil;
		[name retain];
	}
	
	return self;
}

#pragma mark accessor methods

- (NSString *)identifier
{
	if (name)
		return name;
	else
		return [[urlRequest URL] absoluteString];
}

- (void)setIdentifier:(NSString *)newIdentifier
{
	[self setName:newIdentifier];
}

- (void)setName:(NSString *)newName
{
	[name release];
	name = [newName retain];
}

- (void)addDictionaryToArray:(NSMutableArray *)objectArray
{
	NSString *bodyString = [[[NSString alloc]
			initWithData:[urlRequest HTTPBody]
			encoding:NSASCIIStringEncoding
		] autorelease
	];
	[objectArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[self identifier],					@"identifier",
			[[urlRequest URL] absoluteString],	@"url",
			[urlRequest HTTPMethod],			@"method",
			bodyString,							@"body",
			nil
		]
	];
}

#pragma mark action methods

- (void)start
{
	startTime = [[NSDate date] timeIntervalSince1970];
	INFO(NSLog( @"startTime: %f", startTime ));
}

- (void)stop
{
	stopTime = [[NSDate date] timeIntervalSince1970];
	completed++;
	lastTime = stopTime - startTime;
	totalTime += lastTime;
	averageTime = totalTime / completed;
	
	
	INFO(NSLog( @"stopTime: %f", stopTime ));
	INFO(NSLog( @"completed: %d\nlastTime: %f\ntotalTime: %f\naverageTime: %f", completed, lastTime, totalTime, averageTime ));
}

@end
