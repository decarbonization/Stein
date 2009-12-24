//
//  STBridgedFunction.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

@class STFunctionInvocation;

/*!
 @class
 @abstract	The STBridgedFunction class is used to represent native functions in the Stein programming language.
 */
@interface STBridgedFunction : NSObject < STFunction >
{
	/* owner */	STFunctionInvocation *mInvocation;
	/* owner */	NSString *mFunctionName;
}
#pragma mark Initialization

/*!
 @method
 @abstract	Initialize the receiver with a specified function symbol, and a specified signature.
 @param		symbol		The symbol the receiver is to represent. May not be nil.
 @param		signature	The signature of the function the receiver is to represent. May not be nil.
 @result	A fully initialized bridged function object.
 */
- (id)initWithSymbol:(void *)symbol signature:(NSMethodSignature *)signature;

/*!
 @method
 @abstract	Initialize the receiver with a specified function symbol name, and a specified signature.
 @param		symbolName	The name of the symbol the receiver is to represent. May not be nil.
 @param		signature	The signature of the function the receiver is to represent. May not be nil.
 @result	A fully initailized bridged function object.
 */
- (id)initWithSymbolNamed:(NSString *)symbolName signature:(NSMethodSignature *)signature;

#pragma mark -
#pragma mark Properties

/*!
 @property
 @abstract	The name of the function this bridged-function object represents.
 */
@property (copy) NSString *functionName;

@end
