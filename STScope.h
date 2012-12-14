//
//  STScope.h
//  stein
//
//  Created by Peter MacWhinnie on 6/4/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <libkern/OSAtomic.h>

@class STModule;
@class STScopeNode;

///	The STScope class is used to represent levels of scoping in the Stein language.
///
///The internal storage of the STStorage class is a doubly linked list where each
///node contains a key, value, and a flag indicating whether or not the value is
///readonly. This storage was chosen due to ease of implementation and the ability
///to make reads and writes atomic, providing a basic amount of thread-safety.
@interface STScope : NSObject
{
@private
	//Internal:
	STScope *mParentScope;
	STScopeNode *mHead;
	STScopeNode *mLast;
	
	//Properties:
	NSString *mName;
	STModule *mModule;
}

#pragma mark Initialization

///Returns a new STScope with a specified parent scope.
+ (STScope *)scopeWithParentScope:(STScope *)parentScope;

///Initialize the receiver with a specified parent scope.
- (id)initWithParentScope:(STScope *)parentScope;

#pragma mark - Scope Chaining

///The scope that precedes this scope in the lookup chain.
@property STScope *parentScope;

#pragma mark - Variables

///	Adds values for all of the variables in a specified scope.
///
/// \param		scope	The scope to add the values from. Required.
///
///Parent scopes are searched when setting values.
- (void)setValuesForVariablesInScope:(STScope *)scope;

///Sets the value of a variable with a specified name in the receiver.
///
/// \param	value				The value of the variable. Required.
/// \param	name				The name to give the variable. Required.
/// \param	searchParentScopes	Whether or not the receiver should check its parent scopes
///								for variables with the specified name. If YES and a variable
///								is found in one of the parent scopes, then the variable will
///								be set in that parent scope.
- (void)setValue:(id)value forVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

///	Sets the value of a constant in the receiver.
///
/// \param		value	The value of the constant. Required.
/// \param		name	The name of the constant. Required.
///
///This method raises if there is an existing constant with the same name.
///This method *does not* search parent scopes for existing constants.
- (void)setValue:(id)value forConstantNamed:(NSString *)name;

///Removes the value of a variable with a specified name in the receiver.
///
/// \param	name				The name of the variable to remove. Required.
/// \param	searchParentScopes	Whether or not the receiver should check its parent scopes if
///								a variable by `name` cannot be found in the receiver's values.
- (void)removeValueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

///	Returns the value for a variable with a specified name.
/// \param		name				The name of the variable to look up. Required.
/// \param		searchParentScopes	Whether or not the receiver should search its parent scopes
///									if it does not have a variable with the specified name.
/// \result		The value for the variable with the specified name if one could be found; nil otherwise.
///
///It is safe to perform variable lookups from multiple threads.
- (id)valueForVariableNamed:(NSString *)name searchParentScopes:(BOOL)searchParentScopes;

#pragma mark -

///Returns the names of all of the variables in the receiver.
- (NSArray *)allVariableNames;

///Returns the values of all of the variables in the receiver.
- (NSArray *)allVariableValues;

///Applies a given block object to the entries of the receiver.
- (void)enumerateNamesAndValuesUsingBlock:(void (^)(NSString *name, id value, BOOL *stop))block;

#pragma mark - Identity

///Returns whether or not the receiver is equal to another scope.
- (BOOL)isEqualToScope:(STScope *)scope;

#pragma mark - Properties

///The name of the scope.
@property (copy) NSString *name;

///The module that this scope descends from.
@property (readonly) STModule *module;

@end
