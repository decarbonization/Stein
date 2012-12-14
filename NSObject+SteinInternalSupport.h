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

///To add messaging to NSObject, to add infix notation support through
///the STMethodMissing protocol, and to add high level instance variable
///access/mutation support.
@interface NSObject (SteinInternalSupport) <STMethodMissing>

#pragma mark - Ivars

///To assign a given value to an ivar with a specified name.
///
///Stein will first look for an ivar with the specified name,
///if it cannot find one it will store it in the object's ivar
///dictionary.
- (void)setValue:(id)value forIvarNamed:(NSString *)name;
+ (void)setValue:(id)value forIvarNamed:(NSString *)name;

///To return the value for an ivar with a given name.
///
///Stein will first look for an ivar with the specified name,
///if one cannot be found it will check the object's ivar dictionary.
- (id)valueForIvarNamed:(NSString *)name;
+ (id)valueForIvarNamed:(NSString *)name;

#pragma mark - Operators

///To provide an object's implementation of the + operator (prefix and infix).
///
///The default implementation of this method just raises an exception.
- (id)operatorAdd:(id)rightOperand;

///To provide an object's implementation of the - operator (prefix and infix).
///
///The default implementation of this method just raises an exception.
- (id)operatorSubtract:(id)rightOperand;

///To provide an object's implementation of the * operator (prefix and infix).
///
///The default implementation of this method just raises an exception.
- (id)operatorMultiply:(id)rightOperand;

///To provide an object's implementation of the / operator (prefix and infix).
///
///The default implementation of this method just raises an exception.
- (id)operatorDivide:(id)rightOperand;

///To provide an object's implementation of the ^ operator (prefix and infix).
///
///The default implementation of this method just raises an exception.
- (id)operatorPower:(id)rightOperand;

@end
