//
//  ReplayEvent.h
//  Web Tool Kit
//
//  Created by Eric Baur on 10/23/05.
//  Copyright 2005 Eric Shore Baur. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ReplayEvent : NSObject {
	NSURLRequest *urlRequest;
	
	int step;
	//int current;
	int completed;
	//int total;

	double lastTime;
	double averageTime;
	double totalTime;
	double startTime;
	double stopTime;
	
	NSString *name;
	NSMutableArray *timingArray;
}

- (id)init;
- (id)initWithURL:(NSURLRequest *)url;
- (id)initWithSettingsFromDictionary:(NSDictionary *)settingsDict;

- (NSString *)identifier;

- (void)setName:(NSString *)newName;
- (void)addDictionaryToArray:(NSMutableArray *)objectArray;

- (void)start;
- (void)stop;

@end
