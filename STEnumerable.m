//
//  STEnumerable.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/22.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STEnumerable.h"

@implementation STBreakException

+ (STBreakException *)breakExceptionFrom:(STCreationLocation *)creationLocation
{
	STBreakException *e = (STBreakException *)[super exceptionWithName:@"break" reason:@"break" userInfo:nil];
	e.creationLocation = creationLocation;
	return e;
}

@synthesize creationLocation = mCreationLocation;

@end

@implementation STContinueException

+ (STContinueException *)continueExceptionFrom:(STCreationLocation *)creationLocation
{
	STContinueException *e = (STContinueException *)[super exceptionWithName:@"continue" reason:@"continue" userInfo:nil];
	e.creationLocation = creationLocation;
	return e;
}

@synthesize creationLocation = mCreationLocation;

@end
