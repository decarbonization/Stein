//
//  STSymbol.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STSymbol.h"

@implementation STSymbol

#pragma mark Destruction

- (void)dealloc
{
	[mString release];
	mString = nil;
	
	[super dealloc];
}

#pragma mark -
#pragma mark Creation

+ (STSymbol *)symbolWithString:(NSString *)string
{
	return [[[self alloc] initWithString:string] autorelease];
}

- (id)initWithString:(NSString *)string
{
	if((self = [super init]))
	{
		mString = [string copy];
		return self;
	}
	return nil;
}

- (id)init
{
	if((self = [super init]))
	{
		mString = @"";
		return self;
	}
	return nil;
}

#pragma mark -
#pragma mark Coding

- (id)initWithCoder:(NSCoder *)decoder
{
	NSAssert([decoder allowsKeyedCoding], @"Non-keyed coder (%@) given to -[STSymbol initWithCoder:].", decoder);
	
	if((self = [super init]))
	{
		mString = [[decoder decodeObjectForKey:@"mString"] retain];
		mIsQuoted = [decoder decodeBoolForKey:@"mIsQuoted"];
		
		return self;
	}
	return nil;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	NSAssert([encoder allowsKeyedCoding], @"Non-keyed coder (%@) given to -[STSymbol encodeWithCoder:].", encoder);
	
	[encoder encodeObject:mString forKey:@"mString"];
	[encoder encodeBool:mIsQuoted forKey:@"mIsQuoted"];
}

#pragma mark -
#pragma mark Properties

@synthesize string = mString;
@synthesize isQuoted = mIsQuoted;

#pragma mark -

@synthesize creationLocation = mCreationLocation;

#pragma mark -
#pragma mark Identity

- (BOOL)isEqualTo:(id)object
{
	if([object respondsToSelector:@selector(string)])
		return [mString isEqualToString:[object string]];
	else if([object isKindOfClass:[NSString class]])
		return [mString isEqualToString:object];
	
	return [super isEqualTo:object];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@%@>", [self className], self, mIsQuoted? @"'" : @"", mString];
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"%@%@", mIsQuoted? @"'" : @"", mString];
}

@end
