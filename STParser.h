//
//  STParser.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#pragma once

/*!
 @abstract		Parse a specified string as Stein code, producing an array of lists, symbols,
				strings, and numbers suitable for use with an evaluator object.
 @param			string	The string to parse as Stein code. Required.
 @param			file	The path of the file that's being parsed. Optional.
 @result		An array of lists, symbols, strings, and numbers.
 @discussion	This function is thread safe.
 */
ST_EXTERN NSArray *STParseString(NSString *string, NSString *file);
