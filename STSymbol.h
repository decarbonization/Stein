//
//  STSymbol.h
//  stein
//
//  Created by Peter MacWhinnie on 09/12/11.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface STSymbol : NSObject
{
	NSString *mString;
}
#pragma mark Creation

+ (STSymbol *)symbolWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

#pragma mark Destruction

@property (readonly) NSString *string;
@end
