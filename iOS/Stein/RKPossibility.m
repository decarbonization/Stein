//
//  RKPossibility.m
//  RoundaboutKit
//
//  Created by Kevin MacWhinnie on 12/20/12.
//  Copyright (c) 2012 Roundabout Software, LLC. All rights reserved.
//

#import "RKPossibility.h"

@implementation RKPossibility {
	id _value;
	NSError *_error;
    RKPossibilityState _state;
}

- (id)initWithValue:(id)value
{
	if((self = [super init])) {
		_value = value;
        _state = kRKPossibilityStateValue;
	}
	
	return self;
}

- (id)initWithError:(NSError *)error
{
	if((self = [super init])) {
		_error = error;
        _state = kRKPossibilityStateError;
	}
	
	return self;
}

- (id)initEmpty
{
    if((self = [super init])) {
        _state = kRKPossibilityStateEmpty;
    }
    
    return self;
}

- (id)init
{
    return [self initEmpty];
}

#pragma mark - Properties

@synthesize value = _value;
@synthesize error = _error;
@synthesize state = _state;

@end

RK_OVERLOADABLE RKPossibility *RKRefinePossibility(RKPossibility *possibility,
                                                   RKPossibility *(^valueRefiner)(id value),
                                                   RKPossibility *(^emptyRefiner)(),
                                                   RKPossibility *(^errorRefiner)(NSError *error))
{
    if(!possibility)
        return nil;
    
    if(!valueRefiner) valueRefiner = ^(id value) { return [[RKPossibility alloc] initWithValue:value]; };
    if(!emptyRefiner) emptyRefiner = ^{ return [[RKPossibility alloc] initEmpty]; };
    if(!errorRefiner) errorRefiner = ^(NSError *error) { return [[RKPossibility alloc] initWithError:error]; };
    
    if(possibility.state == kRKPossibilityStateValue) {
        return valueRefiner(possibility.value);
    } else if(possibility.state == kRKPossibilityStateEmpty) {
        return emptyRefiner();
    } else if(possibility.state == kRKPossibilityStateError) {
        return errorRefiner(possibility.error);
    }
    
    NSCAssert(0, @"RKPossibility is in an undefined state.");
    
    return nil;
}

RK_OVERLOADABLE void RKMatchPossibility(RKPossibility *possibility,
                                        void(^value)(id value),
                                        void(^empty)(),
                                        void(^error)(NSError *error))
{
    if(!possibility)
        return;
    
    if(possibility.state == kRKPossibilityStateValue) {
        if(value)
            value(possibility.value);
    } else if(possibility.state == kRKPossibilityStateEmpty) {
        if(empty)
            empty();
    } else if(possibility.state == kRKPossibilityStateError) {
        if(error)
            error(possibility.error);
    } else {
        NSCAssert(0, @"RKPossibility is in an undefined state.");
    }
}

#pragma mark - Collection Tools

RK_OVERLOADABLE void RKPossibilitiesIterateValues(NSArray *possibilities, void(^callback)(id value, NSUInteger index, BOOL *stop))
{
    NSCParameterAssert(callback);
    
    [possibilities enumerateObjectsUsingBlock:^(RKPossibility *possibility, NSUInteger index, BOOL *stop) {
        if(possibility.state != kRKPossibilityStateValue)
            return;
        
        callback(possibility.value, index, stop);
    }];
}

RK_OVERLOADABLE void RKPossibilitiesIterateErrors(NSArray *possibilities, void(^callback)(NSError *error, NSUInteger index, BOOL *stop))
{
    NSCParameterAssert(callback);
    
    [possibilities enumerateObjectsUsingBlock:^(RKPossibility *possibility, NSUInteger index, BOOL *stop) {
        if(possibility.state != kRKPossibilityStateError)
            return;
        
        callback(possibility.error, index, stop);
    }];
}
