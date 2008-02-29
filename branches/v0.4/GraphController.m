//
//  GraphController.m
//  Web Tool Kit
//
//  Created by Eric Baur on 1/13/05.
//  Copyright 2005 Eric Shore Baur. All rights reserved.
//

#import "GraphController.h"


@implementation GraphController

- (IBAction)refresh:(id)sender
{
	[reArray release];
	if (sourceTag==GCPagesSourceTag) {
		if ([pagesArrayController selectionIndex]==NSNotFound) {
			reArray = [pagesArrayController arrangedObjects];
		} else {
			reArray = [pagesArrayController selectedObjects];
		}
	} else if (sourceTag==GCResourcesSourceTag) {
		if ([resourcesArrayController selectionIndex]==NSNotFound) {
			reArray = [resourcesArrayController arrangedObjects];
		} else {
			reArray = [resourcesArrayController selectedObjects];
		}
	}
	[reArray retain];
	
	[bandwidthGraphView reloadData];
	[bandwidthGraphView reloadAttributes];
	
	[timesGraphView reloadData];
	[timesGraphView reloadAttributes];
	
	/// BEGIN PIE CHART STUFF ///
	if (sourceTag==GCResourcesSourceTag) {
		[countedMIMETypes release];
		countedMIMETypes = [[NSCountedSet alloc] initWithArray:[reArray valueForKey:@"MIMEType"]];
	} else {
		NSEnumerator *en = [reArray objectEnumerator];
		NSMutableArray *tempArray = [NSMutableArray array];
		ResourceEvent *re;
		while (re=[en nextObject]) {
			[tempArray addObjectsFromArray:[re valueForKey:@"subResources"] ];
		}
		[countedMIMETypes release];
		countedMIMETypes = [[NSCountedSet alloc] initWithArray:[tempArray valueForKey:@"MIMEType"]];
	}
	[pieArray release];
	pieArray = [[countedMIMETypes allObjects] retain];
	INFO(( @"countedMIMETypes:\n%@", [countedMIMETypes description] ));
	[pieView reloadData];
	[pieView reloadAttributes];
	/// END PIE CHART STUFF ///	
}

- (void)setSourceTag:(GCSourceTag)newSource
{
	sourceTag = newSource;
	[self refresh:self];
}

#pragma mark SM2DGraphView datasource methods

- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{
	return 3;
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex
{
	NSColor *graphColor;
	

	if (inGraphView==timesGraphView) {
		switch( inLineIndex ) {
			case 0:	graphColor = [NSColor yellowColor];	break;
			case 1: graphColor = [NSColor greenColor];	break;
			case 2:	graphColor = [NSColor blueColor];	break;
			default: graphColor = [NSColor blackColor];
		}
	
		return [NSDictionary dictionaryWithObjectsAndKeys:
			graphColor,	NSForegroundColorAttributeName,
			@"on",	SM2DGraphBarStyleAttributeName,
			nil
		];
	} else {
		switch( inLineIndex ) {
			case 0:	graphColor = [NSColor redColor];	break;
			case 1: graphColor = [NSColor blackColor];	break;
			default: graphColor = [NSColor blackColor];
		}

		return [NSDictionary dictionaryWithObjectsAndKeys:
			graphColor,	NSForegroundColorAttributeName,
			nil
		];	
	}	
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex
{
	NSMutableArray *pointArray = [NSMutableArray array];
	ResourceEvent *re;
	
	int i;
	double value;
	int count = [reArray count];
	for (i=0; i<count; i++) {
		re = [reArray objectAtIndex:i];
		switch(inLineIndex) {
			case 0:
				value = (inGraphView==timesGraphView ? [re waittime] : [re bytesPerSecond] );
				break;
			case 1:
				value = (inGraphView==timesGraphView ? [re loadtime] : [re effectiveBytesPerSecond] );
				break;
			case 2:
				value = (inGraphView==timesGraphView ? [re totaltime] : 0);
				break;
			default:
				value = 0;
		}
		[pointArray addObject:NSStringFromPoint( NSMakePoint(i, value) )];
	}
	DEBUG(( @"pointArray:\n%@", [pointArray description] ));
	return pointArray;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis
{
	if ( ![reArray count] )
		return 5;
		
	if ( inAxis==kSM2DGraph_Axis_Y ) {
		NSEnumerator *en = [reArray objectEnumerator];
		ResourceEvent *re;
		double value, max;
		max = 1;
		while ( re = [en nextObject] ) {
			value = (inGraphView==timesGraphView ? [re totaltime] : [re bytesPerSecond] );
			if (max<value) max=value;
		}
		return max * 1.1;
	} else if ( inAxis==kSM2DGraph_Axis_X ) {
		return [reArray count];
	} else {
		return 1;
	}
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
            forAxis:(SM2DGraphAxisEnum)inAxis
{
	return 0;
}

#pragma mark SMPieChartView datasource methods

- (unsigned int)numberOfSlicesInPieChartView:(SMPieChartView *)inPieChartView
{
	return [pieArray count];
}
/*
- (NSDictionary *)pieChartView:(SMPieChartView *)inPieChartView attributesForSliceIndex:(unsigned int)inSliceIndex
{
	//not sure how I want to do this... so I'll let the class choose for now
}
*/

- (double)pieChartView:(SMPieChartView *)inPieChartView dataForSliceIndex:(unsigned int)inSliceIndex
{
	return [countedMIMETypes countForObject:[pieArray objectAtIndex:inSliceIndex] ];
}

- (NSString *)pieChartView:(SMPieChartView *)inPieChartView labelForSliceIndex:(unsigned int)inSliceIndex;
{
	id temp = [pieArray objectAtIndex:inSliceIndex];
	if ([temp isEqualTo:[NSNull null]])
		return @"<unknown>";
	else
		return temp;
}
@end
