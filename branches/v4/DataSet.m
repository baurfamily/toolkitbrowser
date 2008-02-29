//
//  DataSet.m
//  GraphTest
//
//  Created by Eric Baur on 11/16/04.
//  Copyright 2004 Eric Shore Baur. All rights reserved.
//

#import "DataSet.h"

@implementation DataSet

+ (void)initialize
{
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"numberOfBins"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"binSize"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"histogramForCurrentIdentifier"];

	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"dataPointsForCurrentIdentifier"];
		
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"count"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"total"];

	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"arithmeticMean"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"populationStdDev"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"sampleStdDev"];

	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"mode"];

	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"domainMinimum"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"globalMinimum"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"minimum"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"firstQuartile"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"median"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"thirdQuartile"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"maximum"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"globalMaximum"];
	[self setKeys:[NSArray arrayWithObject:@"data"]
		triggerChangeNotificationsForDependentKey:@"domainMaximum"];
}

- (id)init
{
	self = [super init];
	if (self) {
		//currentIdentifier = @"";
		results = [[NSMutableDictionary alloc] init];
		
		//globalMin = globalMax = 0;
		binSize = 0;
		numberOfBins = 10;
	}
	return self;
}

#pragma mark accessor methods

- (void)setData:(NSArray *)newData
{
	//NSLog( @"[DataSet setData]" );
	if ([newData count]==0)
		return;
		
	[data release];
	data = [newData retain];
	
	[dataIdentifiers release];
	dataIdentifiers = [[[data objectAtIndex:0] allKeys] retain];
	[self resetViews];
		
	[self setNumberOfBins:numberOfBins];
	
	[results release];
	results = [[NSMutableDictionary alloc] init];
	[results setObject:[NSMutableDictionary dictionary] forKey:DSGlobalIdentifier];
	//[self sort];
}

- (NSArray *)data
{
	return data;
}

- (void)setCurrentIdentifier:(NSString *)newIdent
{
	//NSLog( @"[DataSet setCurrentIdentifier:@\"%@\"]", newIdent );
	[currentIdentifier release];
	currentIdentifier = [newIdent retain];
	
	if (![results valueForKey:currentIdentifier] && currentIdentifier) {
		[results setObject:[NSMutableDictionary dictionary] forKey:currentIdentifier];
	}
	//NSLog( @"results:\n%@", [results description] );
	
	//[self sort];
}

- (NSString *)currentIdentifier
{
	return currentIdentifier;
}

- (NSArray *)dataIdentifiers
{
	return dataIdentifiers;
}

- (void)setIndependentIdentifier:(NSString *)newIdentifier
{
	[independentIdentifier release];
	independentIdentifier = [newIdentifier retain];
}

- (NSString *)independentIdentifier
{
	return independentIdentifier;
}

- (void)removeIndependent
{
	[independentIdentifier release];
	independentIdentifier = nil;
}

- (BOOL)hasIndependent
{
	if (independentIdentifier)
		return YES;
	else
		return NO;
}

- (double)valueAtPoint:(double)inputValue forKey:(NSString *)outputKey
{
	NSLog( @"[DataSet valueAtPoint:forKey:] is not implemented yet" );
	return 0;
}

- (double)valueAtIndex:(double)inputIndex forKey:(NSString *)outputKey
{
	ENTRY(NSLog( @"[DataSet valueAtIndex:forKey:]" ));
	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""]) {
		NSLog( @"DataSet: no independent identifier set - returning bogus value" );
		return 0;
	}
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:[NSArray
		arrayWithObject:sortDescriptor]
	];
	[data release];
	data = [tempData retain];
	
	return [[[data objectAtIndex:inputIndex] valueForKey:outputKey] doubleValue];
}

#pragma mark view options

- (void)addViewIdentifier:(NSString *)newViewIdent
{
	ENTRY(NSLog( @"[DataSet addViewIdentifier:%@ ]", newViewIdent ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	if (![newViewIdent isEqualToString:independentIdentifier])
		[tempArray addObject:newViewIdent];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)addViewIdentifiersFromArray:(NSArray *)newViewIdents
{
	ENTRY(NSLog( @"[DataSet addViewIdentifiersFromArray:]" ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	[tempArray addObjectsFromArray:newViewIdents];
	[tempArray removeObject:independentIdentifier];	//this may not work (object, not string?)
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)setViewIdentifiers:(NSArray *)newViewIdents
{
	[self removeAllViews];
	[self addViewIdentifiersFromArray:newViewIdents];
}

- (void)removeViewIdentifier:(NSString *)oldViewIdent
{
	ENTRY(NSLog( @"[DataSet removeViewIdentifier:%@ ]", oldViewIdent ));
	NSMutableArray *tempArray = [viewIdentifiers mutableCopy];
	[tempArray removeObject:oldViewIdent];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
}

- (void)removeAllViews
{
	ENTRY(NSLog( @"[DataSet removeAllViews]" ));
	[viewIdentifiers release];
	viewIdentifiers = [[NSArray alloc] init];
}

- (void)resetViews
{
	NSMutableArray *tempArray = [dataIdentifiers mutableCopy];
	[tempArray removeObject:independentIdentifier];
	[viewIdentifiers release];
	viewIdentifiers = [[tempArray copy] retain];
	ENTRY(NSLog( @"[DataSet resetViews]\n%@", [viewIdentifiers description] ));
}

- (NSArray *)viewIdentifiers
{
	return [viewIdentifiers copy];
}

#pragma mark histogram and graphing methods

- (void)setNumberOfBins:(int)newNumberOfBins
{
	ENTRY(NSLog( @"[DataSet setNumberOfBins:%d", newNumberOfBins ));
	numberOfBins = newNumberOfBins;
	binSize = ([self globalMaximum]-[self globalMinimum])/numberOfBins;
}

- (int)numberOfBins
{
	return numberOfBins;
}

- (void)setBinSize:(double)newBinSize
{
	ENTRY(NSLog( @"[DataSet setBinSize:%f]", newBinSize ));
	binSize = newBinSize;
	numberOfBins = ([self globalMaximum]-[self globalMinimum])/binSize + 1;	//do I need the +1?
}

- (double)binSize
{
	return binSize;
}

- (NSArray *)histogramForCurrentIdentifier
{
	ENTRY(NSLog( @"[DataSet historgramForCurrentIdentifier]" ));
	if ( binSize==0 || [currentIdentifier isEqualToString:@""]
		|| [currentIdentifier isEqualToString:independentIdentifier]) {
		return nil;
	}

	NSEnumerator *en = [data objectEnumerator];
	id tempID;
	
	int binValues[ numberOfBins ];
	double check;
	int i;
	BOOL foundPlacement;
	double globalMin = [self globalMinimum];
	double globalMax = [self globalMaximum];
	
	INFO(NSLog( @"Globals: ( %f, %f )", globalMin, globalMax ));
	INFO(NSLog( @"Histogram using %d bins of size: %f", numberOfBins, binSize ));
	for(i=0; i<numberOfBins; i++)
		binValues[i] = 0;
	
	while (tempID=[en nextObject]) {
		check =  [[tempID valueForKey:currentIdentifier] doubleValue];
		foundPlacement = NO;
		for (i=0; i<numberOfBins; i++) {
			if ( check>=(globalMin+i*binSize) && check<(globalMin+(i+1)*binSize) ) {
				binValues[i]++;
				foundPlacement = YES;
			}
		}
		if (!foundPlacement && check==globalMax)	//might be a better way to do this...
			binValues[i]++;
		else if (!foundPlacement)
			NSLog( @"couldn't find place for: %f", check );
	}
	NSMutableArray *tempArray = [NSMutableArray array];
	for (i=0; i<numberOfBins; i++) {
		[tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:i],								@"bin",
				[NSNumber numberWithInt:binValues[i] ],					@"value",
				[NSNumber numberWithDouble:(globalMin+i*binSize)],		@"min",
				[NSNumber numberWithDouble:(globalMin+(i+1)*binSize)],	@"max",
				nil
			]
		];
	}
	return [tempArray copy];
}

- (NSArray *)dataPointsForCurrentIdentifier
{
	return [self dataPointsForCurrentIdentifierStartingAt:0 endingAt:0];
}

- (NSArray *)dataPointsForCurrentIdentifierStartingAt:(double)startingNum endingAt:(double)endingNum
{
	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return nil;
		
	if (currentIdentifier==nil || [currentIdentifier isEqualToString:@""])
		return nil;
		
	NSSortDescriptor *independentSort = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSSortDescriptor *currentSort = [[[NSSortDescriptor alloc]
		initWithKey:currentIdentifier ascending:YES] autorelease
	];

	NSArray *tempData = [data sortedArrayUsingDescriptors:[NSArray
			arrayWithObjects:independentSort, currentSort, nil
		]
	];
	NSMutableArray *pointTable = [NSMutableArray array];
	
	NSEnumerator *en = [tempData objectEnumerator];
	id tempID;
	double tempNum;
	while (tempID=[en nextObject]) {
		if (startingNum==endingNum) {
			[pointTable addObject: NSStringFromPoint(
					NSMakePoint(
						[[tempID valueForKey:independentIdentifier] doubleValue],
						[[tempID valueForKey:currentIdentifier] doubleValue]
					)
				)
			];
		} else {
			tempNum = [[tempID valueForKey:independentIdentifier] doubleValue];
			if ( tempNum >= startingNum && tempNum <= endingNum )
				[pointTable addObject: NSStringFromPoint(
						NSMakePoint(
							[[tempID valueForKey:independentIdentifier] doubleValue],
							[[tempID valueForKey:currentIdentifier] doubleValue]
						)
					)
				];
		}
	}
	//NSLog( @"pointTable:\n%@", [pointTable description] );
	return [pointTable copy];
}

#pragma mark statistics methods

- (void)sort
{
	ENTRY(NSLog( @"[DataSet sort]" ));
	if (currentIdentifier==nil || [currentIdentifier isEqualToString:@""])
		return;
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:currentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:[NSArray
		arrayWithObject:sortDescriptor]
	];
	[data release];
	data = [tempData retain];
}

- (int)count
{	//might not need the cached result here (unless we use it to return all at once)
	return [data count];
}

- (double)total
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"total"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"total"] doubleValue];
		
	ENTRY(NSLog( @"[DataSet total]" ));
	NSEnumerator *en = [data objectEnumerator];
	id tempID;
	
	double total = 0;
	
	while (tempID=[en nextObject]) {
		total += [[tempID valueForKey:currentIdentifier] doubleValue];
	}
	
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:total]
		forKey:@"total"
	];
	return total;
}

- (double)arithmeticMean
{	//might not need to cached result here (unless we use it to return a large data set all at once)
	//NSLog( @"[DataSet arithmeticMean] = %f", [self total] / [data count] );
	return ( [self total] / [data count] );
}

- (double)populationStdDev
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"populationStdDev"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"populationStdDev"] doubleValue];
		
	double avg = [self arithmeticMean  ];
	double total = 0;
	double x;
	
	NSEnumerator *en = [data objectEnumerator];
	id tempID;
	
	while (tempID=[en nextObject]) {
		x = [[tempID valueForKey:currentIdentifier] doubleValue];
		total += (x-avg)*(x-avg);
	}
	double stddev = sqrt( total / [data count] );
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:stddev]
		forKey:@"populationStdDev"
	];
	return stddev;
}

- (double)sampleStdDev
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"sampleStdDev"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"sampleStdDev"] doubleValue];
		
	double avg = [self arithmeticMean  ];
	double total = 0;
	double x;
	
	NSEnumerator *en = [data objectEnumerator];
	id tempID;
	
	while (tempID=[en nextObject]) {
		x = [[tempID valueForKey:currentIdentifier] doubleValue];
		total += (x-avg)*(x-avg);
	}
	
	double stddev = sqrt( total / ([data count]-1) );
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:stddev]
		forKey:@"sampleStdDev"
	];
	return stddev;
}

- (double)mode
{
	NSLog( @"[DataSet mode] : not implemented" );
	return 0;
}

- (double)domainMinimum
{
	if ([[results valueForKey:independentIdentifier] valueForKey:@"domainMinimum"])
		return [[[results valueForKey:independentIdentifier] valueForKey:@"domainMinimum"] doubleValue];

	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return 0;
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:[NSArray
		arrayWithObject:sortDescriptor]
	];
		
	double domainMinimum = [[[tempData objectAtIndex:0] valueForKey:independentIdentifier] doubleValue];
	[[results valueForKey:independentIdentifier]
		setObject:[NSNumber numberWithDouble:domainMinimum]
		forKey:@"domainMinimum"
	];
	ENTRY(NSLog( @"[DataSet domainMinimum] = %f", domainMinimum ));
	return domainMinimum;
}

- (double)globalMinimum
{
	if ([[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMinimum"])
		return [[[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMinimum"] doubleValue];
	ENTRY(NSLog( @"[DataSet globalMinimum]" ));
	[self findGlobalMinAndMax];
	
	return [[[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMinimum"] doubleValue];
}

- (double)minimum
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"minimum"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"minimum"] doubleValue];

	[self sort];

	double minimum = [[[data objectAtIndex:0] valueForKey:currentIdentifier] doubleValue];
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:minimum]
		forKey:@"minimum"
	];
	ENTRY(NSLog( @"[DataSet minimum] = %f", minimum ));
	return minimum;
}

- (double)firstQuartile
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"firstQuartile"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"firstQuartile"] doubleValue];

	ENTRY(NSLog( @"[DataSet firstQuartile]" ));
	[self sort];
		
	int count = [data count];
	if (count<2)
		return [self minimum];
	int middle = count/4;
	double firstQuartile;
	switch (count%4) {
		case 0:
			firstQuartile = ( 
				[[[data objectAtIndex:middle-1] valueForKey:currentIdentifier] doubleValue] +
				[[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue]
			) / 2;
			break;
		case 1:
			firstQuartile = ( 
				[[[data objectAtIndex:middle-1] valueForKey:currentIdentifier] doubleValue] +
				[[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue]
			) / 2;
			break;
		case 2:
			firstQuartile = [[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue];
			break;
		case 3:
			firstQuartile = [[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue];
			break;
		default:
			NSLog( @"should never get here (bad case in [DataSet firstQuartile] - count: %d %% 4 = %d)",count,count%4 );
			return 0;		
	}
	
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:firstQuartile]
		forKey:@"firstQuartile"
	];
	return firstQuartile;
}

- (double)median
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"median"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"median"] doubleValue];
	
	ENTRY(NSLog( @"[DataSet media]" ));
	[self sort];
	
	int count = [data count];
	int middle =  count/2;
	double median = 0;
	if (count%2) {
		median = [[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue];
	} else {
		median = ( 
			[[[data objectAtIndex:middle-1] valueForKey:currentIdentifier] doubleValue] +
			[[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue]
		) / 2;
	}
	
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:median]
		forKey:@"median"
	];
	return median;
}

- (double)thirdQuartile
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"thirdQuartile"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"thirdQuartile"] doubleValue];

	ENTRY(NSLog( @"[DataSet thirdQuartile]" ));
	[self sort];
		
	int count = [data count];
	if (count<2)
		return [self maximum];
	int middle = 3*count/4;
	double thirdQuartile;
	switch (count%4) {
		case 0:
			thirdQuartile = ( 
				[[[data objectAtIndex:middle-1] valueForKey:currentIdentifier] doubleValue] +
				[[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue]
			) / 2;
			break;
		case 1:
			thirdQuartile = ( 
				[[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue] +
				[[[data objectAtIndex:middle+1] valueForKey:currentIdentifier] doubleValue]
			) / 2;
			break;
		case 2:
			thirdQuartile = [[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue];
			break;
		case 3:
			thirdQuartile = [[[data objectAtIndex:middle] valueForKey:currentIdentifier] doubleValue];
			break;
		default:
			NSLog( @"should never get here (bad case in [DataSet thirdQuartile] - count: %d %% 4 = %d)",count,count%4 );
			return 0;
	}
	
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:thirdQuartile]
		forKey:@"thirdQuartile"
	];
	return thirdQuartile;
}

- (double)maximum
{
	if ([[results valueForKey:currentIdentifier] valueForKey:@"maximum"])
		return [[[results valueForKey:currentIdentifier] valueForKey:@"maximum"] doubleValue];

	if ([data count]<2)
		return [self minimum];

	[self sort];
	
	double maximum = [[[data objectAtIndex:[data count]-1] valueForKey:currentIdentifier] doubleValue];
	[[results valueForKey:currentIdentifier]
		setObject:[NSNumber numberWithDouble:maximum]
		forKey:@"maximum"
	];
	ENTRY(NSLog( @"[DataSet maximum] = %f", maximum ));
	return maximum;
}

- (double)globalMaximum
{
	if ([[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMaximum"])
		return [[[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMaximum"] doubleValue];
	INFO(NSLog( @"[DataSet globalMaximum]" ));
	[self findGlobalMinAndMax];
	
	return [[[results valueForKey:DSGlobalIdentifier] valueForKey:@"globalMaximum"] doubleValue];
}

- (double)domainMaximum
{
	if ([[results valueForKey:independentIdentifier] valueForKey:@"domainMaximum"])
		return [[[results valueForKey:independentIdentifier] valueForKey:@"domainMaximum"] doubleValue];

	if (independentIdentifier==nil || [independentIdentifier isEqualToString:@""])
		return 0;
		
	if ([data count]<2)
		return [self domainMinimum];
		
	NSSortDescriptor *sortDescriptor = [[[NSSortDescriptor alloc]
		initWithKey:independentIdentifier ascending:YES] autorelease
	];
	NSArray *tempData = [data sortedArrayUsingDescriptors:[NSArray
		arrayWithObject:sortDescriptor]
	];
	
	double domainMaximum = [[[tempData objectAtIndex:[tempData count]-1] valueForKey:independentIdentifier] doubleValue];
	[[results valueForKey:independentIdentifier]
		setObject:[NSNumber numberWithDouble:domainMaximum]
		forKey:@"domainMaximum"
	];
	ENTRY(NSLog( @"[DataSet domainMaximum] = %f", domainMaximum ));
	return domainMaximum;
}

- (void)findGlobalMinAndMax
{
	ENTRY(NSLog( @"[DataSet findGlobalMinAndMax]" ));
	NSString *origIdent = currentIdentifier;
	double check, globalMin, globalMax;
	NSEnumerator *en = [dataIdentifiers objectEnumerator];
	NSString *tempString;
	tempString = [en nextObject];
	if ([tempString isEqualToString:independentIdentifier])
		tempString = [en nextObject];
	[self setCurrentIdentifier:tempString];
	globalMin = [self minimum];
	globalMax = [self maximum];
	while (tempString=[en nextObject]) {
		if (![tempString isEqualToString:independentIdentifier]) {		
			[self setCurrentIdentifier:tempString];
			check = [self minimum];
			if (check<globalMin)
				globalMin = check;
			check = [self maximum];
			if (check>globalMax)
				globalMax = check;
		}
	}
	[self setCurrentIdentifier:origIdent];
	INFO(NSLog( @"calculated globals( %f, %f )", globalMin, globalMax ));
	[[results valueForKey:DSGlobalIdentifier]
		setObject:[NSNumber numberWithDouble:globalMin]
		forKey:@"globalMinimum"
	];
	[[results valueForKey:DSGlobalIdentifier]
		setObject:[NSNumber numberWithDouble:globalMax]
		forKey:@"globalMaximum"
	];
}


@end
