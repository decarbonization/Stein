//
//  STFunction.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Stein/STScope.h>

@class STList;

///The STFunction protocol defines the methods required for an object to be used as a function in Stein.
@protocol STFunction < NSObject >

///Apply the receiver with a list of arguments (evaluated if -[STFunction evaluatesOwnArguments] returns YES) within a specified scope, returning the result.
/// \param	arguments	The arguments passed to the function.
/// \param	scope		The scope in which the receiver is being applied.
/// \result	The result of applying the receiver as a function.
- (id)applyWithArguments:(STList *)arguments inScope:(STScope *)scope;

#pragma mark -

///Returns YES if the receiver intends to evaluate the arguments passed to it by itself; NO if the receiver would like to be passed arguments suitable for regular use.
@property (readonly) BOOL evaluatesOwnArguments;

///The enclosing scope the receiver was created in. This is used to implement closures.
@property (readonly) STScope *superscope;

@end

#pragma mark -

///Apply a specified object implementing the STFunction protocol with a specified argument list.
///
/// \param	function	The function to apply.
/// \param	arguments	The arguments to pass to the function.
/// \result	The result of applying the function.
ST_INLINE id STFunctionApply(id < STFunction > function, STList *arguments)
{
    @autoreleasepool {
        STScope *scope = [STScope scopeWithParentScope:[function superscope]];
        return [function applyWithArguments:arguments inScope:scope];
    }
}
