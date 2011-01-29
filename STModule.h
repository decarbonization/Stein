//
//  STModule.h
//  stein
//
//  Created by Peter MacWhinnie on 1/29/11.
//  Copyright 2011 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Stein/STScope.h>

@interface STModule : STScope
{
}

///Initialize the receiver with a specified name and superscope;
- (id)initWithName:(NSString *)name superscope:(STScope *)scope;

@end
