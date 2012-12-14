//
//  STFrameworkLoader.h
//  stein
//
//  Created by Kevin MacWhinnie on 12/13/12.
//  Copyright (c) 2012 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>

///The STFrameworkLoader class encapsulates the loading of frameworks for the Stein programming language.
@interface STFrameworkLoader : NSObject

///Returns the shared framework loader, creating it if it doesn't already exist.
+ (instancetype)sharedFrameworkLoader;

#pragma mark - Managing Paths

///The search paths used by the framework loader.
@property (nonatomic, copy, readonly) NSArray *searchPaths;

///Add a search path to the framework loader.
///
///Search paths are added at the top of the array.
- (void)addSearchPath:(NSString *)searchPath;

///Remove a search path from the framework loader.
- (void)removeSearchPath:(NSString *)searchPath;

#pragma mark - Loading Frameworks

///The frameworks currently loaded.
@property (nonatomic, copy, readonly) NSArray *loadedFrameworks;

///Load a framework with a given filename using the search paths registered in the receiver.
///
/// \param  frameworkName       The name of the framework to load. Required.
///                             If the framework name begins with / or . it is treated as an absolute path.
/// \param  creationLocation    The location this method was called from for the purposes of error reporting. Required.
///
///This method will not load the same framework more than once.
- (void)loadFrameworkWithName:(NSString *)frameworkName fromLocation:(STCreationLocation *)creationLocation;

@end
