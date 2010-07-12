//
//  STBuiltInFunctions.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STScope;

/*!
 @abstract	Returns a new scope representing the built in function scope.
 */
ST_EXTERN STScope *STBuiltInFunctionScope();
