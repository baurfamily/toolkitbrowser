//
//  GraphController.h
//  Web Tool Kit
//
//  Created by Eric Baur on 1/13/05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SM2DGraphView/SM2DGraphView.h>
#import <SM2DGraphView/SMPieChartView.h>

#import "ResourceEvent.h"

typedef enum {
	GCPagesSourceTag = 0,
	GCResourcesSourceTag = 1
} GCSourceTag;

@interface GraphController : NSObject
{
	IBOutlet SM2DGraphView *bandwidthGraphView;
	IBOutlet SM2DGraphView *timesGraphView;
	IBOutlet SMPieChartView *pieView;
	IBOutlet NSArrayController *pagesArrayController;
	IBOutlet NSArrayController *resourcesArrayController;
	
	GCSourceTag sourceTag;
	
	NSArray *reArray;
	NSArray *pieArray;
	NSCountedSet *countedMIMETypes;
}

- (IBAction)refresh:(id)sender;

- (void)setSourceTag:(GCSourceTag)newSource;

@end
