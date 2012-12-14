//
//  STEnumerable.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/22.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

#pragma mark Enumerable Interface

@protocol STFunction;
@protocol STEnumerable

///Apply a function to each object in the receiver's contents.
///
/// \param		function	The function to apply to each object. May be nil.
/// \result		The receiver.
///
///It is expected that the function will be given at least one parameter in all cases.
///This parameter should be each object in the receiver. If the receiver can be indexed,
///a second parameter should be provided that specifies the index of the object in the
///first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
///then the first parameter should be each key, and the second each value.
///
///The receiver should expect, and react to both continue and break exceptions as appropriate.
- (id)foreach:(id < STFunction >)function;

///Apply a function to each object in the receiver's contents, and collect the result into a new enumerable object.
///
/// \param		function	The function to apply to each object. May not be nil.
/// \result		The result of applying the specified function to the receiver's contents.
///
///It is expected that the function will be given at least one parameter in all cases.
///This parameter should be each object in the receiver. If the receiver can be indexed,
///a second parameter should be provided that specifies the index of the object in the
///first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
///then the first parameter should be each key, and the second each value.
///
///The receiver should expect, and react to both continue and break exceptions as appropriate.
- (id)map:(id < STFunction >)function;

///Apply a function to each object in the receiver's contents, and filter out every object that the function returns false for.
///
/// \param		function	The function to apply to each object. May not be nil.
/// \result		The result of applying the specified function to the receiver's contents and,
///				filtering out every object that the function returned false for.
///
///It is expected that the function will be given at least one parameter in all cases.
///This parameter should be each object in the receiver. If the receiver can be indexed,
///a second parameter should be provided that specifies the index of the object in the
///first parameter. If the receiver contents are key-value pairs (like a hash/dictionary)
///then the first parameter should be each key, and the second each value.

///The receiver should expect, and react to both continue and break exceptions as appropriate.
- (id)filter:(id < STFunction >)function;

@end

#pragma mark -

@interface STBreakException : NSException
{
@private
	STCreationLocation *mCreationLocation;
}

+ (STBreakException *)breakExceptionFrom:(STCreationLocation *)creationLocation;

@property STCreationLocation *creationLocation;

@end

@interface STContinueException : NSException
{
@private
	STCreationLocation *mCreationLocation;
}

+ (STContinueException *)continueExceptionFrom:(STCreationLocation *)creationLocation;

@property STCreationLocation *creationLocation;

@end
