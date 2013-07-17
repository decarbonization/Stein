//
//  PRTProjectManager.m
//  Stein
//
//  Created by Kevin MacWhinnie on 4/27/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTProjectManager.h"

static NSString *const kProjectsUserDefaultsKey = @"PRTProjectManager_projectsURLs";

@implementation PRTProjectManager {
    NSMutableArray *_projectURLs;
}

+ (instancetype)sharedProjectManager
{
    static PRTProjectManager *sharedProjectManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedProjectManager = [PRTProjectManager new];
    });
    
    return sharedProjectManager;
}

- (id)init
{
    if((self = [super init])) {
        NSData *archivedProjectURLs = [[NSUserDefaults standardUserDefaults] dataForKey:kProjectsUserDefaultsKey];
        if(archivedProjectURLs)
            _projectURLs = [NSKeyedUnarchiver unarchiveObjectWithData:archivedProjectURLs];
        else
            _projectURLs = [NSMutableArray array];
    }
    
    return self;
}

#pragma mark - Managing Projects

- (void)saveProjectURLs
{
    NSData *archivedProjectURLs = [NSKeyedArchiver archivedDataWithRootObject:_projectURLs];
    [[NSUserDefaults standardUserDefaults] setObject:archivedProjectURLs forKey:kProjectsUserDefaultsKey];
}

- (NSURL *)projectsDirectory
{
    static NSURL *projectsDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        NSError *error = nil;
        NSURL *documentsDirectory = [fileManager URLForDirectory:NSDocumentDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:YES
                                                           error:&error];
        NSAssert(documentsDirectory != nil, @"Documents directory does not exist. %@", error);
        
        projectsDirectory = [documentsDirectory URLByAppendingPathComponent:@"Stein Projects"];
        if(![projectsDirectory checkResourceIsReachableAndReturnError:nil])
        {
            NSAssert([fileManager createDirectoryAtURL:projectsDirectory
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:&error],
                     @"Could not create projects directory. %@", error);
        }
    });
    return projectsDirectory;
}

@synthesize projectURLs = _projectURLs;

#pragma mark -

static NSString *const kMainFileTemplate = (@"opts ()\n"
                                            @"\n"
                                            @";   \n"
                                            @";   %@ - %@\n"
                                            @";   Created on %@\n"
                                            @";   \n\n"
                                            @"let AppDelegate extend RTAppDelegate {\n"
                                            @"    \n"
                                            @"    - (BOOL)application:(UIApplication)application didFinishLaunchingWithOptions:(NSDictionary)launchOptions {\n"
                                            @"        true\n"
                                            @"    }\n"
                                            @"    \n"
                                            @"}\n");

- (NSString *)mainFileContentsWithInfoDictionary:(NSDictionary *)infoDictionary
{
    NSString *bundleName = infoDictionary[@"CFBundleName"];
    NSString *identifier = infoDictionary[@"CFBundleIdentifier"];
    return [NSString stringWithFormat:kMainFileTemplate, bundleName, identifier, [NSDate date]];
}

- (BOOL)createProjectWithInfoDictionary:(NSDictionary *)infoDictionary error:(NSError **)error
{
    NSParameterAssert(infoDictionary);
    
    NSString *bundleName = infoDictionary[@"CFBundleName"];
    NSAssert(bundleName != nil, @"Misssing CFBundleName");
    
    NSURL *projectURL = [self.projectsDirectory URLByAppendingPathComponent:[bundleName stringByAppendingPathExtension:@"stapp"]];
    return [self createProjectAtURL:projectURL infoDictionary:infoDictionary error:error];
}

- (BOOL)createProjectAtURL:(NSURL *)location infoDictionary:(NSDictionary *)info error:(NSError **)error
{
    NSParameterAssert(location);
    NSParameterAssert(info);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if(![fileManager createDirectoryAtURL:location withIntermediateDirectories:YES attributes:nil error:error])
        return NO;
    
    NSURL *mainLocation = [location URLByAppendingPathComponent:@"Main.st"];
    NSString *mainContents = [self mainFileContentsWithInfoDictionary:info];
    if(![mainContents writeToURL:mainLocation atomically:NO encoding:NSUTF8StringEncoding error:error])
        return NO;
    
    NSURL *infoLocation = [location URLByAppendingPathComponent:@"Info.plist"];
    NSData *infoData = nil;
    if(!(infoData = [NSPropertyListSerialization dataWithPropertyList:info format:NSPropertyListXMLFormat_v1_0 options:0 error:error]))
        return NO;
    
    if(![infoData writeToURL:infoLocation options:0 error:error])
        return NO;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self willChangeValueForKey:@"projectURLs"];
        [_projectURLs addObject:location];
        [self saveProjectURLs];
        [self didChangeValueForKey:@"projectURLs"];
    }];
    
    return YES;
}

- (BOOL)deleteProjectAtURL:(NSURL *)location error:(NSError **)error
{
    NSParameterAssert(location);
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    BOOL success = [fileManager removeItemAtURL:location error:error];
    if(success) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self willChangeValueForKey:@"projectURLs"];
            [_projectURLs removeObject:location];
            [self saveProjectURLs];
            [self didChangeValueForKey:@"projectURLs"];
        }];
    }
    
    return success;
}

@end
