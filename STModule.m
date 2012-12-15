//
//  STModule.m
//  stein
//
//  Created by Kevin MacWhinnie on 1/29/11.
//  Copyright 2011 Stein Language. All rights reserved.
//

#import "STModule.h"

@implementation STModule

- (id)initWithName:(NSString *)name superscope:(STScope *)scope
{
	if((self = [super initWithParentScope:scope]))
	{
		self.name = name;
	}
	
	return self;
}

@end
