//
//  STScope.h
//  stein
//
//  Created by Peter MacWhinnie on 6/4/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libkern/OSAtomic.h>

/*!
 @abstract	The opaque type used to represent the contents of a STScope object.
 */
typedef struct STScopeNode * STScopeNodeRef;

#pragma mark -

/*!
 @abstract	The STScope class is used to represent levels of scoping in the Stein language.
 */
@interface STScope : NSObject
{
@private
	STScope *mParentScope;
	STScopeNodeRef mHead;
	STScopeNodeRef mLast;
}

#pragma mark Scope Chaining

/*!
 @abstract	The scope that precedes this scope in the lookup chain.
 */
@property STScope *parentScope;

#pragma mark -
#pragma mark Variables

/*!
 @abstract	Sets the value of a variable with a specified name in the receiver.
 @param		value				The value of the variable. Required.
 @param		name				The name to give the variable. Required.
 @param		searchParentScopes	Whether or not the receiver should check its parent scopes
								for variables with the specified name. If YES and a variable
								is found in one of the parent scopes, then the variable will
								be set in that parent scope.
 */
- (void)setValue:(id)value forVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

/*!
 @abstract	Removes the value of a variable with a specified name in the receiver.
 @param		name				The name of the variable to remove. Required.
 @param		searchParentScopes	Whether or not the receiver should check its parent scopes if
								a variable by `name` cannot be found in the receiver's values.
 */
- (void)removeValueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

/*!
 @abstract		Returns the value for a variable with a specified name.
 @param			name				The name of the variable to look up. Required.
 @param			searchParentScopes	Whether or not the receiver should search its parent scopes
									if it does not have a variable with the specified name.
 @result		The value for the variable with the specified name if one could be found; nil otherwise.
 @discussion	It is safe to perform variable lookups from multiple threads.
 */
- (id)valueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

#pragma mark -
#pragma mark Identity

/*!
 @abstract	Returns whether or not the receiver is equal to another scope.
 */
- (BOOL)isEqualToScope:(STScope *)scope;

@end
