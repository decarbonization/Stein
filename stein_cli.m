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
#import <Stein/NSObject+Stein.h> //For -[NSObject prettyDescription]

#pragma mark Tools

typedef enum ProgramOptions {
	/*!
	 @enum		ProgramOptions
	 @abstract	Enumerations describing each of the options a user can specify in the Stein CLI.
	 
	 @constant	kProgramOptionSandboxEachFile
					This field is set when the user has asked for each file to be run in its own interpreter.
	 
	 @constant	kProgramOptionSandboxEachFile
					This field is set when the user has indicated they want each file to be compiled and printed, but not interpreted.
	 
	 @constant	kProgramOptionRunREPLInBackground
					This field is set when the user has indicated they want to run the REPL loop in a background thread, while the files they specified run in the main thread.
	 */
	kProgramOptionSandboxEachFile = (1 << 0),
	kProgramOptionParseOnly = (1 << 1),
	kProgramOptionRunREPLInBackground = (1 << 2),
} ProgramOptions;

/*!
 @function
 @abstract	Analyze the arguments given to the CLI when it was called from the command prompt, reporting the paths and options that were specified by the user in easily processable forms.
 @param		argc		The length of the arguments given.
 @param		argv		The arguments given. May not be NULL.
 @param		outPaths	On return, will contain an array describing the paths the user specified.
 @param		outOptions	On return, will contain a bit-or combined value describing the options the user specified.
 */
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
				case 'S':
				case 's':
					options |= kProgramOptionSandboxEachFile;
					break;
					
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

/*!
 @function
 @abstract	Print the usage information for the Stein command line interface.
 */
static void Help()
{
	fprintf(stdout, "stein [-spr] [paths...]\n\n");
	fprintf(stdout, "\t-s\tRun each file in it's own evaluator, isolating their environments from each other.\n");
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
				id expressions = STParseString(fileContents);
				
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
					id result = STEvaluate(expressions, [STScope scopeWithParentScope:globalScope]);
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[result prettyDescription] UTF8String]);
				}
				
				//
				//	If we're sandboxing each file, we discard the evaluator we have
				//	going now and create a new one in it's place. This prevents the
				//	next file from accssing something from the old evaluator.
				//
				//	This does not guarantee the old evaluator is gone, it will stick
				//	around if there are any valid closures or classes that were created
				//	through it.
				//
				if(ST_FLAG_IS_SET(options, kProgramOptionSandboxEachFile))
				{
					globalScope = STBuiltInFunctionScope();
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
