//
//  NSObject+SteinInternalSupport.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>
#import <Stein/STObjectBridge.h>

//
//	category	NSObject+SteinInternalSupport
//	purpose		To add messaging to NSObject, to add infix notation support through \
//				the STMethodMissing protocol, and to add high level instance variable \
//				access/mutation support.
//
@interface NSObject (SteinInternalSupport) <STMethodMissing>

#pragma mark -
#pragma mark Ivars

//
//	method		setValue:forIvarNamed:
//	intention	To assign a given value to an ivar with a specified name.
//	note		Stein will first look for an ivar with the specified name, \
//				if it cannot find one it will store it in the object's ivar \
//				dictionary.
//
- (void)setValue:(id)value forIvarNamed:(NSString *)name;
+ (void)setValue:(id)value forIvarNamed:(NSString *)name;

//
//	method		valueForIvarNamed:
//	intention	To return the value for an ivar with a given name.
//	note		Stein will first look for an ivar with the specified name, \
//				if one cannot be found it will check the object's ivar dictionary.
//
- (id)valueForIvarNamed:(NSString *)name;
+ (id)valueForIvarNamed:(NSString *)name;

#pragma mark -
#pragma mark Operators

//
//	method		operatorAdd:
//	intention	To provide an object's implementation of the + operator (prefix and infix).
//	note		The default implementation of this method just raises an exception.
//
- (id)operatorAdd:(id)rightOperand;

//
//	method		operatorSubtract:
//	intention	To provide an object's implementation of the - operator (prefix and infix).
//	note		The default implementation of this method just raises an exception.
//
- (id)operatorSubtract:(id)rightOperand;

//
//	method		operatorMultiply:
//	intention	To provide an object's implementation of the * operator (prefix and infix).
//	note		The default implementation of this method just raises an exception.
//
- (id)operatorMultiply:(id)rightOperand;

//
//	method		operatorDivide:
//	intention	To provide an object's implementation of the / operator (prefix and infix).
//	note		The default implementation of this method just raises an exception.
//
- (id)operatorDivide:(id)rightOperand;

//
//	method		operatorPower:
//	intention	To provide an object's implementation of the ^ operator (prefix and infix).
//	note		The default implementation of this method just raises an exception.
//
- (id)operatorPower:(id)rightOperand;

@end
