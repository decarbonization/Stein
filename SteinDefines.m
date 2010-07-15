/*
 *  SteinDefines.m
 *  stein
 *
 *  Created by Peter MacWhinnie on 2009/12/13.
 *  Copyright 2009 Stein Language. All rights reserved.
 *
 */

#import "SteinDefines.h"
#import <stdarg.h>

#pragma mark Tools

NSBundle *SteinBundle()
{
	return [NSBundle bundleWithIdentifier:@"com.petermacwhinnie.Stein"];
}

NSString *const kSTSuperclassVariableName = @"$__superclass";

#pragma mark -
#pragma mark Errors

void STRaiseIssue(STCreationLocation expressionLocation, NSString *format, ...)
{
	va_list formatArguments;
	va_start(formatArguments, format);
	
	NSString *errorString = [[[NSString alloc] initWithFormat:format arguments:formatArguments] autorelease];
	
	va_end(formatArguments);
	
	[SteinException raise:NSInternalInconsistencyException 
				   format:@"Error on line %ld in %@: %@", expressionLocation.line, expressionLocation.file, errorString];
}
