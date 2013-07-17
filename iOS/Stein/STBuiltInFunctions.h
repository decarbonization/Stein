//
//  STBuiltInFunctions.h
//  stein
//
//  Created by Kevin MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STScope;
@protocol STFunction;

///Look up a built in function by a specified name.
ST_EXTERN id <STFunction> STBuiltInFunctionLookUp(NSString *name);
