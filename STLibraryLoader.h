//
//  STLibraryLoader.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/13/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STScope, STCreationLocation;

///The STLibraryLoader class encapsulates library loading for the Stein language.
@interface STLibraryLoader : NSObject

///Returns the shared library loader, creating it if it doesn't already exist.
+ (instancetype)sharedLibraryLoader;

#pragma mark - Managing Paths

///The search paths used by the library loader.
@property (nonatomic, copy, readonly) NSArray *searchPaths;

///Add a search path to the library loader.
///
///Search paths are added at the top of the array.
- (void)addSearchPath:(NSString *)searchPath;

///Remove a search path from the library loader.
- (void)removeSearchPath:(NSString *)searchPath;

#pragma mark - Loading Files

///The libraries currently loaded.
@property (nonatomic, copy, readonly) NSArray *loadedLibraries;

///Load a file with a given filename using the search paths registered in the receiver.
///
/// \param  filename            The name of the file to load. Required.
///                             If the filename begins with / or . it is treated as an absolute path.
/// \param  scope               The scope to evaluate the file under. Required.
/// \param  creationLocation    The location this method was called from for the purposes of error reporting. Required.
///
///This method will not load the same file multiple times.
- (void)loadFileWithName:(NSString *)filename
                 inScope:(STScope *)scope
            fromLocation:(STCreationLocation *)creationLocation;

@end
