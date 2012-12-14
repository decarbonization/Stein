//
//  stein_cli.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <readline/readline.h>

#import <Stein/Stein.h>
#import <Stein/NSObject+SteinTools.h> //For -[NSObject prettyDescription]

#pragma mark Tools

///Enumerations describing each of the options a user can specify in the Stein CLI.
typedef enum ProgramOptions {
    ///This field is set when the user has indicated they want each file to be compiled and printed, but not interpreted.
	kProgramOptionParseOnly = (1 << 1),
    
    ///This field is set when the user has indicated they want to run the REPL loop in a background thread, while the files they specified run in the main thread.
	kProgramOptionRunREPLInBackground = (1 << 2),
} ProgramOptions;

///Analyze the arguments given to the CLI when it was called from the command prompt, reporting the paths and options that were specified by the user in easily processable forms.
///
/// \param	argc		The length of the arguments given.
/// \param	argv		The arguments given. May not be NULL.
/// \param	outPaths	On return, will contain an array describing the paths the user specified.
/// \param	outOptions	On return, will contain a bit-or combined value describing the options the user specified.
static void AnalyzeProgramArguments(int argc, const char *argv[], NSArray **outPaths, ProgramOptions *outOptions)
{
	NSCParameterAssert(argv);
	NSCParameterAssert(outPaths);
	NSCParameterAssert(outOptions);
	
	ProgramOptions options = 0;
	NSMutableArray *paths = [NSMutableArray array];
	
	for (int index = 1; index < argc; index++)
	{
		const char *arg = argv[index];
		if(arg[0] == '-')
		{
			int lengthOfArgument = strlen(arg);
			if(lengthOfArgument < 2)
			{
				fprintf(stderr, "Unsupported option %s, ignoring.\n", arg);
				continue;
			}
			
			switch (arg[1])
			{
				case 'P':
				case 'p':
					options |= kProgramOptionParseOnly;
					break;
					
				case 'R':
				case 'r':
					options |= kProgramOptionRunREPLInBackground;
					break;
					
				default:
					fprintf(stderr, "Unsupported option %s, ignoring.\n", arg);
					break;
			}
		}
		else
		{
			[paths addObject:[[NSString stringWithUTF8String:arg] stringByExpandingTildeInPath]];
		}
	}
	
	*outOptions = options;
	*outPaths = paths;
}

#pragma mark -

///Print the usage information for the Stein command line interface.
static void Help()
{
	fprintf(stdout, "stein [-pr] [paths...]\n\n");
	fprintf(stdout, "\t-p\tOnly parse the files, printing the compiled structure.\n");
	fprintf(stdout, "\t-r\tRun the REPL on a background thread while the files are run on the main thread.\n");
}

#pragma mark -

int main (int argc, const char * argv[])
{
	if((argc >= 2) && (strcmp(argv[1], "help") == 0))
	{
		Help();
		
		return 0;
	}
	
	//If we're only given one argument (the path of your executable), then we enter REPL mode.
	if(argc == 1)
	{
		STRunREPL();
	}
	else
	{
		NSArray *paths = nil;
		ProgramOptions options = 0;
		AnalyzeProgramArguments(argc, argv, &paths, &options);
		
		if(ST_FLAG_IS_SET(options, kProgramOptionRunREPLInBackground))
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				STRunREPL();
				
				exit(EXIT_SUCCESS);
			});
		}
		
		NSError *error = nil;
		STScope *globalScope = STBuiltInFunctionScope();
		for (NSString *path in paths)
		{
			NSString *fileContents = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
			if(!fileContents)
			{
				fprintf(stderr, "Could not load file %s, skipping.\n", [path UTF8String]);
				continue;
			}
			
			@try
			{
				id expressions = STParseString(fileContents, path);
				
				//
				//	If we're in parse only mode, we simply print the
				//	data we parsed and go along our merry way.
				//
				if(ST_FLAG_IS_SET(options, kProgramOptionParseOnly))
				{
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[expressions prettyDescription] UTF8String]);
				}
				else
				{
					[globalScope setValue:path forVariableNamed:@"$file" searchParentScopes:NO];
					
					id result = STEvaluate(expressions, [STScope scopeWithParentScope:globalScope]);
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[result prettyDescription] UTF8String]);
				}
			}
			@catch (NSException *e)
			{
				fprintf(stderr, "Error in file %s: %s\n", [path UTF8String], [[e reason] UTF8String]);
			}
		}
	}
	
	return 0;
}
