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
 @method
 @abstract		Parse a specified string as Stein code, producing an array of lists, symbols,
				strings, and numbers suitable for use with an evaluator object.
 @param			string			The string to parse as Stein code. May not be nil.
 @param			targetEvaluator	The evaluator the result will be passed into. May be nil, but is strongly recommended.
				By providing a value for this parameter, all lists returned will have an evaluator associated with
				them which allows them to be used by the control flow methods in NSObject+Stein.
 @result		An array of lists, symbols, strings, and numbers.
 @discussion	This function is thread safe.
 */
ST_EXTERN NSArray *STParseString(NSString *string);
