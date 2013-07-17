//
//  STModule.h
//  stein
//
//  Created by Kevin MacWhinnie on 1/29/11.
//  Copyright 2011 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STScope.h"

@interface STModule : STScope
{
}

///Initialize the receiver with a specified name and superscope;
- (id)initWithName:(NSString *)name superscope:(STScope *)scope;

@end
