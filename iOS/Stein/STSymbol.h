//
//  STSymbol.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef STSymbol_h
#define STSymbol_h 1

@class STSymbol;
@class STCreationLocation;

///Look up a symbol in the process-wide symbol cache. 
ST_EXTERN STSymbol *STSymbolCachedSymbolWithName(NSString *name);

#define ST_SYM(string) STSymbolCachedSymbolWithName(string)

///The STSymbol class is used to describe identifiers in the Stein programming language.
@interface STSymbol : NSObject
{
	NSString *mString;
	BOOL mIsQuoted;
	STCreationLocation *mCreationLocation;
}
#pragma mark Creation

///Initialize a symbol with a string.
///
/// \param	string	The string the symbol is to represent. May not be nil.
///
/// \result	A fully initialized symbol object.
- (id)initWithString:(NSString *)string;

#pragma mark - Identity

///Returns whether or not the receiver is equal to a specified object.
///
/// \param		object	An STSymbol or NSString object to compare the receiver to.
///
/// \result		YES if the receiver is equal to `object`; NO otherwise.
- (BOOL)isEqual:(id)object;

///Returns whether or not the receiver is equal to a specified symbol.
- (BOOL)isEqualToSymbol:(STSymbol *)symbol;

///Returns whether or not the receiver is equal to a specified string.
- (BOOL)isEqualToString:(NSString *)string;

#pragma mark - Properties

///The string the symbol represents.
@property (readonly) NSString *string;

///Whether or not the symbol is quoted.
@property BOOL isQuoted;

#pragma mark -

///The location at which the list was created.
@property STCreationLocation *creationLocation;

@end

#endif /* STSymbol_h */
