/*
 *  SteinDefines.h
 *  stein
 *
 *  Created by Peter MacWhinnie on 09/12/13.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */

#pragma once

#if __cplusplus
#	define ST_EXTERN extern "C"
#else
#	define ST_EXTERN extern
#endif /* __cplusplus */

#ifdef __OBJC__

#import <Foundation/Foundation.h>

ST_EXTERN NSBundle *SteinBundle();

#endif /* __OBJC__ */
