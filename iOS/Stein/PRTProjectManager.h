//
//  PRTProjectManager.h
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import <Foundation/Foundation.h>

///The PRTProjectManager class is responsible for managing projects on the file system for Stein.
@interface PRTProjectManager : NSObject

///Returns the shared project manager, creating it if it does not already exist.
+ (instancetype)sharedProjectManager;

#pragma mark - Managing Projects

///The location of the projects directory.
@property (readonly) NSURL *projectsDirectory;

///The locations of the projects being managed.
@property (copy, readonly) NSArray *projectURLs;

#pragma mark -

///Creates a project with a specified Info.plist.
///
/// \param  infoDictionary  The Info.plist of the project. Must include a CFBundleName key.
/// \param  error       On return, an error describing any issues that occurred.
///
/// \result YES if the project could be created; NO otherwise.
///
///This method asynchronously updates the `projectURLs` property on the main thread.
///This method can safely be called from any thread.
- (BOOL)createProjectWithInfoDictionary:(NSDictionary *)infoDictionary error:(NSError **)error;

///Creates a project at a specified location.
///
/// \param  location    The location of the project to create. Required.
/// \param  info        The contents of the Info.plist. Required.
/// \param  error       On return, an error describing any issues that occurred.
///
/// \result YES if the project could be created; NO otherwise.
///
///This method asynchronously updates the `projectURLs` property on the main thread.
///This method can safely be called from any thread.
- (BOOL)createProjectAtURL:(NSURL *)location infoDictionary:(NSDictionary *)info error:(NSError **)error;

#pragma mark -

///Delete a specified project at a specified location.
///
/// \param  location    The location of the project to delete. Required.
/// \param  error       On return, an error describing any issues that occurred.
///
/// \result YES if the project could be deleted; NO otherwise.
///
///This method asynchronously updates the `projectURLs` property on the main thread.
///This method can safely be called from any thread.
- (BOOL)deleteProjectAtURL:(NSURL *)location error:(NSError **)error;

@end
