//
//  SteinException.m
//  stein
//
//  Created by Peter MacWhinnie on 7/13/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "SteinException.h"

@implementation SteinException

#pragma mark Initialization

- (id)initWithName:(NSString *)aName reason:(NSString *)aReason userInfo:(NSDictionary *)aUserInfo
{
	if((self = [super initWithName:aName reason:aReason userInfo:aUserInfo]))
	{
		mOriginalException = self;
		mRelevantExpressions = [NSMutableArray new];
	}
	
	return self;
}

- (id)initWithException:(NSException *)exception
{
	if((self = [self initWithName:[exception name] reason:[exception reason] userInfo:[exception userInfo]]))
	{
		mOriginalException = exception;
	}
	
	return self;
}

#pragma mark -
#pragma mark Properties

@synthesize originalException = mOriginalException;
@synthesize relevantExpressions = mRelevantExpressions;

- (void)addRelevantExpression:(id)expression
{
	NSParameterAssert(expression);
	
	[mRelevantExpressions addObject:expression];
}

@end
