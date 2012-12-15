//
//  STSymbol.m
//  stein
//
//  Created by Kevin MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STSymbol.h"
#import <libkern/OSAtomic.h>

STSymbol *STSymbolCachedSymbolWithName(NSString *name)
{
	NSCParameterAssert(name);
	
	@synchronized(@"mutex")
	{
		static NSMutableDictionary *symbolCache = nil;
		if(!symbolCache)
			symbolCache = [NSMutableDictionary new];
		
		
		STSymbol *cachedSymbol = [symbolCache objectForKey:name];
		if(cachedSymbol)
			return cachedSymbol;
		
		
		STSymbol *newSymbol = [[STSymbol alloc] initWithString:name];
		[symbolCache setObject:newSymbol forKey:name];
		
		return newSymbol;
	}
}

@implementation STSymbol

#pragma mark Creation

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

#pragma mark - Coding

- (id)initWithCoder:(NSCoder *)decoder
{
	NSAssert([decoder allowsKeyedCoding], @"Non-keyed coder (%@) given to -[STSymbol initWithCoder:].", decoder);
	
	if((self = [super init]))
	{
		mString = [decoder decodeObjectForKey:@"mString"];
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

#pragma mark - Properties

@synthesize string = mString;
@synthesize isQuoted = mIsQuoted;

#pragma mark -

@synthesize creationLocation = mCreationLocation;

#pragma mark - Identity

- (BOOL)isEqualTo:(id)object
{
	if([object respondsToSelector:@selector(string)])
		return [mString isEqualToString:[object string]];
	
	return [super isEqualTo:object];
}

- (BOOL)isEqualToSymbol:(STSymbol *)symbol
{
	return [mString isEqualToString:symbol.string];
}

- (BOOL)isEqualToString:(NSString *)string
{
	return [mString isEqualToString:string];
}

#pragma mark -

- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@:%p %@%@>", [self className], self, mIsQuoted? @"'" : @"", mString];
}

- (NSString *)prettyDescription
{
	return [NSString stringWithFormat:@"%@%@", mIsQuoted? @"'" : @"", mString];
}

@end
