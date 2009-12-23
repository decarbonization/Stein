//
//  STSymbol.h
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface STSymbol : NSObject
{
	NSString *mString;
	BOOL mIsQuoted;
}
#pragma mark Creation

+ (STSymbol *)symbolWithString:(NSString *)string;
- (id)initWithString:(NSString *)string;

#pragma mark -
#pragma mark Properties

@property (readonly) NSString *string;
@property BOOL isQuoted;
@end
