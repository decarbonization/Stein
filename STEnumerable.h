//
//  STEnumerable.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/22.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>
#import <Stein/STBuiltInFunctions.h>

#pragma mark Control Flow Exceptions

/*!
 @class
 @abstract	This exception is raised when the break built in function is called in Stein.
 */
@interface STBreakException : NSException
{
}

/*!
 @method
 @abstract		Create a break exception, ready for raising.
 @discussion	This is the only way you should create a break exception.
 */
+ (STBreakException *)breakException;

@end

//The implementation of the 'break' operator.
STBuiltInFunctionExport(Break);

#pragma mark -

/*!
 @class
 @abstract	This exception is raised when the continue built in function is called in Stein.
 */
@interface STContinueException : NSException
{
}

/*!
 @method
 @abstract		Create a continue exception, ready for raising.
 @discussion	This is the only way you should create a continue exception.
 */
+ (STContinueException *)continueException;

@end

//The implementation of the 'continue' operator.
STBuiltInFunctionExport(Continue);

#pragma mark -
#pragma mark Enumerable Interface

@protocol STFunction;
@protocol STEnumerable

/*!
 @method
 @abstract		Apply a function to each object in the receiver's contents.
 
 @param			function	The function to apply to each object. May be nil.
 @result		The receiver.
 
 @discussion	It is expected that the function will be given at least one parameter in all cases.
				This parameter should be each object in the receiver. If the receiver can be indexed,
				a second parameter should be provided that specifies the index of the object in the
				first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
				then the first parameter should be each key, and the second each value.
				
				The receiver should expect, and react to both continue and break exceptions as appropriate.
 */
- (id)foreach:(id < STFunction >)function;

/*!
 @method
 @abstract		Apply a function to each object in the receiver's contents, and collect the result into a new enumerable object.
 
 @param			function	The function to apply to each object. May not be nil.
 @result		The result of applying the specified function to the receiver's contents.
 
 @discussion	It is expected that the function will be given at least one parameter in all cases.
				This parameter should be each object in the receiver. If the receiver can be indexed,
				a second parameter should be provided that specifies the index of the object in the
				first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
				then the first parameter should be each key, and the second each value.

				The receiver should expect, and react to both continue and break exceptions as appropriate.
 */
- (id)map:(id < STFunction >)function;

/*!
 @method
 @abstract		Apply a function to each object in the receiver's contents, and filter out every object that the function returns false for.
 
 @param			function	The function to apply to each object. May not be nil.
 @result		The result of applying the specified function to the receiver's contents and, 
				filtering out every object that the function returned false for.
 
 @discussion	It is expected that the function will be given at least one parameter in all cases.
				This parameter should be each object in the receiver. If the receiver can be indexed,
				a second parameter should be provided that specifies the index of the object in the
				first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
				then the first parameter should be each key, and the second each value.

				The receiver should expect, and react to both continue and break exceptions as appropriate.
 */
- (id)filter:(id < STFunction >)function;

@end
