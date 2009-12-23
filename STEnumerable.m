//
//  STEnumerable.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/22.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STEnumerable.h"

@implementation STBreakException

+ (STBreakException *)breakException
{
	return (STBreakException *)[super exceptionWithName:@"STBreakException" reason:@"break" userInfo:nil];
}

@end

STBuiltInFunctionDefine(Break, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	@throw [STBreakException breakException];
	return STNull;
});

#pragma mark -

@implementation STContinueException

+ (STContinueException *)continueException
{
	return (STContinueException *)[super exceptionWithName:@"STContinueException" reason:@"continue" userInfo:nil];
}

@end

STBuiltInFunctionDefine(Continue, YES, ^id(STEvaluator *evaluator, STList *arguments, NSMutableDictionary *scope) {
	@throw [STContinueException continueException];
	return STNull;
});
