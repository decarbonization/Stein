//
//  STLibraryLoader.m
//  stein
//
//  Created by Kevin MacWhinnie on 12/13/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import "STLibraryLoader.h"
#import "SteinDefines.h"
#import "STInterpreter.h"

@implementation STLibraryLoader {
    NSMutableArray *_searchPaths;
    NSMutableArray *_loadedLibraries;
}

+ (instancetype)sharedLibraryLoader
{
    static STLibraryLoader *sharedLibraryLoader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLibraryLoader = [STLibraryLoader new];
    });
    
    return sharedLibraryLoader;
}

- (id)init
{
    if((self = [super init]))
    {
        _searchPaths = [NSMutableArray arrayWithObjects:
                        @"./",
                        @"./SteinLibrary",
                        @"~/Library/SteinLibrary",
                        @"/Library/SteinLibrary", nil];
        
        _loadedLibraries = [NSMutableArray array];
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

#pragma mark - Loading Files

@synthesize loadedLibraries = _loadedLibraries;

- (void)loadFileWithName:(NSString *)filename inScope:(STScope *)scope fromLocation:(STCreationLocation *)creationLocation
{
    NSParameterAssert(filename);
    NSParameterAssert(scope);
    
    if([self.loadedLibraries containsObject:filename])
        return;
    
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSString *fullPath = nil;
    
    if([filename hasPrefix:@"/"] || [filename hasPrefix:@"."])
    {
        fullPath = filename;
    }
    else
    {
        if(![filename pathExtension])
        {
            filename = [filename stringByAppendingPathExtension:@"st"];
        }
        
        for (NSString *searchPath in _searchPaths)
        {
            NSString *testFullPath = [searchPath stringByAppendingPathComponent:filename];
            
            BOOL isDirectory = NO;
            if(([defaultManager fileExistsAtPath:testFullPath isDirectory:&isDirectory]))
            {
                if(isDirectory)
                {
                    NSString *initPath = [testFullPath stringByAppendingPathComponent:@"Prelude.st"];
                    if([defaultManager fileExistsAtPath:initPath])
                        fullPath = initPath;
                    else
                        STRaiseIssue(creationLocation, @"Library at path %@ is missing Prelude.st", fullPath);
                }
                else
                {
                    fullPath = testFullPath;
                }
                
                break;
            }
            else
            {
                continue;
            }
        }
    }
    
    NSError *error = nil;
    NSString *fileContents = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:&error];
    if(!fileContents)
        STRaiseIssue(creationLocation, @"Could not load file %@ for require", fullPath);
    
    STEvaluate(fileContents, scope);
    
    [self willChangeValueForKey:@"loadedLibraries"];
    [_loadedLibraries addObject:fullPath];
    [self didChangeValueForKey:@"loadedLibraries"];
}

@end
