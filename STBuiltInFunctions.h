//
//  STBuiltInFunctions.h
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class STScope;

///To create a Stein scope that contains all of the core functions required for Stein to be useful.
ST_EXTERN STScope *STBuiltInFunctionScope();
