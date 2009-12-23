//
//  STBridgedFunction.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/15.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STFunction.h>

@class STFunctionInvocation;
@interface STBridgedFunction : NSObject < STFunction >
{
	STFunctionInvocation *mInvocation;
}
- (id)initWithSymbol:(void *)symbol signature:(NSMethodSignature *)signature;
- (id)initWithSymbolNamed:(NSString *)symbolName signature:(NSMethodSignature *)signature;
@end
