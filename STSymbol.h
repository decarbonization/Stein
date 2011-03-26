//
//  STSymbol.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef STSymbol_h
#define STSymbol_h 1

@class STSymbol;

/*!
 @function
 @abstract	Look up a symbol in the process-wide symbol cache. 
 */
ST_EXTERN STSymbol *STSymbolCachedSymbolWithName(NSString *name);

#define ST_SYM(string) STSymbolCachedSymbolWithName(string)

/*!
 @class
 @abstract	The STSymbol class is used to describe identifiers in the Stein programming language.
 */
@interface STSymbol : NSObject
{
	/* owner */	NSString *mString;
	/* n/a */	BOOL mIsQuoted;
	/* n/a */	STCreationLocation mCreationLocation;
}
#pragma mark Creation

/*!
 @method
 @abstract	Create a new autoreleased symbol with a string.
 @param		string	The string the symbol is to represent. May not be nil.
 @result	A new symbol object.
 */
+ (STSymbol *)symbolWithString:(NSString *)string;

/*!
 @method
 @abstract	Initialize a symbol with a string.
 @param		string	The string the symbol is to represent. May not be nil.
 @result	A fully initialized symbol object.
 */
- (id)initWithString:(NSString *)string;

#pragma mark -
#pragma mark Identity

/*!
 @method
 @abstract		Returns whether or not the receiver is equal to a specified object.
 @param			object	An STSymbol or NSString object to compare the receiver to.
 @result		YES if the receiver is equal to `object`; NO otherwise.
 */
- (BOOL)isEqualTo:(id)object;

/*!
 @method
 @abstract	Returns whether or not the receiver is equal to a specified symbol.
 */
- (BOOL)isEqualToSymbol:(STSymbol *)symbol;

/*!
 @method
 @abstract	Returns whether or not the receiver is equal to a specified string.
 */
- (BOOL)isEqualToString:(NSString *)string;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The string the symbol represents.
 */
@property (readonly) NSString *string;

/*!
 @property
 @abstract	Whether or not the symbol is quoted.
 */
@property BOOL isQuoted;

#pragma mark -

/*!
 @property
 @abstract	The location at which the list was created.
 */
@property STCreationLocation creationLocation;

@end

#endif /* STSymbol_h */
