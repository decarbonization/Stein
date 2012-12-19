//
//  STBridgedFunction.h
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stein/STFunction.h>

@class STFunctionInvocation;

///The STBridgedFunction class is used to represent native functions in the Stein programming language.
@interface STBridgedFunction : NSObject <STFunction>
{
	STFunctionInvocation *mInvocation;
	NSString *mFunctionName;
}
#pragma mark Initialization

///Initialize the receiver with a specified function symbol, and a specified signature.
///
/// \param	symbol		The symbol the receiver is to represent. May not be nil.
/// \param	signature	The signature of the function the receiver is to represent. May not be nil.
/// \result	A fully initialized bridged function object.
- (id)initWithSymbol:(void *)symbol signature:(NSMethodSignature *)signature;

///Initialize the receiver with a specified function symbol name, and a specified signature.
///
/// \param	symbolName	The name of the symbol the receiver is to represent. May not be nil.
/// \param	signature	The signature of the function the receiver is to represent. May not be nil.
/// \result	A fully initailized bridged function object.
- (id)initWithSymbolNamed:(NSString *)symbolName signature:(NSMethodSignature *)signature;

#pragma mark - Properties

///The name of the function this bridged-function object represents.
@property (copy) NSString *functionName;

@end
