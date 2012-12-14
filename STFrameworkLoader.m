//
//  STFrameworkLoader.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/13/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "STFrameworkLoader.h"

@implementation STFrameworkLoader {
    NSMutableArray *_searchPaths;
    NSMutableArray *_loadedFrameworks;
}

+ (instancetype)sharedFrameworkLoader
{
    static STFrameworkLoader *sharedFrameworkLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedFrameworkLoader = [STFrameworkLoader new];
    });
    
    return sharedFrameworkLoader;
}

- (id)init
{
    if((self = [super init]))
    {
        _searchPaths = [NSMutableArray arrayWithObjects:
                        @"./",
                        @"~/Library/Frameworks",
                        @"/Library/Frameworks",
                        @"/System/Library/Frameworks", nil];
        
        _loadedFrameworks = [NSMutableArray arrayWithObjects:
                             @"/System/Library/Frameworks/Foundation.framework",
                             @"/System/Library/Frameworks/ApplicationServices.framework", nil];
    }
    
    return self;
}

#pragma mark - Managing Paths

@synthesize searchPaths = _searchPaths;

- (void)addSearchPath:(NSString *)searchPath
{
    [_searchPaths insertObject:searchPath atIndex:0];
}

- (void)removeSearchPath:(NSString *)searchPath
{
    [_searchPaths removeObject:searchPath];
}

#pragma mark - Loading Frameworks

@synthesize loadedFrameworks = _loadedFrameworks;

- (void)loadFrameworkWithName:(NSString *)frameworkName fromLocation:(STCreationLocation *)creationLocation
{
    NSParameterAssert(frameworkName);
    
    if([self.loadedFrameworks containsObject:frameworkName])
        return;
    
    NSString *fullPath = nil;
    
    if([frameworkName hasPrefix:@"/"] || [frameworkName hasPrefix:@"."])
    {
        fullPath = frameworkName;
    }
    else
    {
        if(![frameworkName pathExtension])
        {
            frameworkName = [frameworkName stringByAppendingPathExtension:@"framework"];
        }
        
        for (NSString *searchDirectory in _searchPaths)
        {
            NSString *testFullPath = [searchDirectory stringByAppendingPathComponent:frameworkName];
            
            if([[NSFileManager defaultManager] fileExistsAtPath:fullPath])
            {
                fullPath = testFullPath;
                break;
            }
            else
            {
                continue;
            }
        }
        
        if(!fullPath)
            return;
        
        NSError *error = nil;
        if(![[NSBundle bundleWithPath:fullPath] loadAndReturnError:&error])
            STRaiseIssue(creationLocation, @"Could not load framework. Error %@", error);
        
        [self willChangeValueForKey:@"loadedFrameworks"];
        [_loadedFrameworks addObject:fullPath];
        [self didChangeValueForKey:@"loadedFrameworks"];
    }
}

@end
