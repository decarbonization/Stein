/*
 *  SteinDefines.m
 *  stein
 *
 *  Created by Kevin MacWhinnie on 2009/12/13.
 *  Copyright 2009 Stein Language. All rights reserved.
 *
 */

#import "SteinDefines.h"
#import <stdarg.h>

#pragma mark Tools

NSString *const kSTSuperclassVariableName = @"$__superclass";
NSString *const kSTClassNameVariableName = @"$__steinClassName";

#pragma mark - Types

@implementation STCreationLocation

- (id)initWithFile:(NSString *)file
{
    if((self = [super init]))
    {
        self.file = file;
    }
    
    return self;
}

@end

#pragma mark - Errors

void STRaiseIssue(STCreationLocation *expressionLocation, NSString *format, ...)
{
	va_list formatArguments;
	va_start(formatArguments, format);
	
	NSString *errorString = [[NSString alloc] initWithFormat:format arguments:formatArguments];
	
	va_end(formatArguments);
	
	[SteinException raise:NSInternalInconsistencyException 
				   format:@"Error on line %d in %@: %@", expressionLocation.line, expressionLocation.file, errorString];
}
