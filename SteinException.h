//
//  SteinException.h
//  stein
//
//  Created by Peter MacWhinnie on 7/13/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SteinException : NSException
{
	NSException *mOriginalException;
	NSMutableArray *mRelevantExpressions;
}

#pragma mark Initialization

///Initialize the receiver with a specified exception.
- (id)initWithException:(NSException *)exception;

#pragma mark - Properties

///The exception for which the Stein exception was raised.
@property (readonly) NSException *originalException;

///Expressions relevant to why this Stein exception was raised.
@property (readonly) NSMutableArray *relevantExpressions;

///Adds a relevant expression to the receiver.
- (void)addRelevantExpression:(id)expression;

@end
