//
//  STSymbol.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

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
