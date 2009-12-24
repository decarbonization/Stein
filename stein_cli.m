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

/*!
 @defined
 @abstract	Indicate whether or not a flag is set in an options bit-field.
 */
#define FlagIsSet(options, flag) ((options & flag) == flag)

/*!
 @function
 @abstract		Analyze a string read from the REPL, and indicate the number of unbalanced parentheses and unbalanced brackets found.
 @param			numberOfUnbalancedParentheses	On return, an integer describing the number of unbalanced parentheses in the specified string.
 @param			numberOfUnbalancedBrackets		On return, an integer describing the number of unbalanced brackets in the specified string.
 @param			string							The string to analyze.
 @discussion	All parameters are required.
 */
static void FindUnbalancedExpressions(NSInteger *numberOfUnbalancedParentheses, NSInteger *numberOfUnbalancedBrackets, NSString *string)
{
	NSCParameterAssert(numberOfUnbalancedParentheses);
	NSCParameterAssert(numberOfUnbalancedBrackets);
	NSCParameterAssert(string);
	
	NSUInteger stringLength = [string length];
	for (NSUInteger index = 0; index < stringLength; index++)
	{
		switch ([string characterAtIndex:index])
		{
			case '(':
				(*numberOfUnbalancedParentheses)++;
				break;
				
			case ')':
				(*numberOfUnbalancedParentheses)--;
				break;
			
			case '[':
				(*numberOfUnbalancedBrackets)++;
				break;
				
			case ']':
				(*numberOfUnbalancedBrackets)--;
				break;
				
			default:
				break;
		}
	}
}

#pragma mark -
#pragma mark Implementation

/*!
 @function
 @abstract	Run a read-evaluate-print loop (REPL) with a specified evaluator until the user asks to exit.
 */
static void RunREPL(STEvaluator *evaluator)
{
	//Initialize readline so we get history.
	rl_initialize();
	
	printf("stein ready [version %s]\n", [[SteinBundle() objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String]);
	for (;;)
	{
		//Break away if we've been told to quit|exit|EOF.
		char *rawLine = readline("Stein> ");
		if(!rawLine || (strlen(rawLine) == 0) || (strcmp(rawLine, "quit") == 0) || (strcmp(rawLine, "exit") == 0))
		{
			free(rawLine);
			fprintf(stdout, "goodbye\n");
			break;
		}
		
		@try
		{
			//Convert the line we just read into an NSString and free it. We use a mutable
			//string so we can append at a later time for the case of partial lines.
			NSMutableString *line = [NSMutableString stringWithUTF8String:rawLine];
			
			
			//Handle unbalanced pairs of parentheses and brackets.
			NSInteger numberOfUnbalancedParentheses = 0, numberOfUnbalancedBrackets = 0;
			FindUnbalancedExpressions(&numberOfUnbalancedParentheses, &numberOfUnbalancedBrackets, line);
			
			while (numberOfUnbalancedParentheses > 0)
			{
				char *partialLine = readline("... ");
				
				for (int i = 0; i < strlen(partialLine); i++)
				{
					if(partialLine[i] == '(')
						numberOfUnbalancedParentheses++;
					else if(partialLine[i] == ')')
						numberOfUnbalancedParentheses--;
				}
				
				[line appendFormat:@"%s", partialLine];
				free(partialLine);
			}
			
			while (numberOfUnbalancedBrackets > 0)
			{
				char *partialLine = readline("... ");
				
				for (int i = 0; i < strlen(partialLine); i++)
				{
					if(partialLine[i] == '[')
						numberOfUnbalancedBrackets++;
					else if(partialLine[i] == ']')
						numberOfUnbalancedBrackets--;
				}
				
				[line appendFormat:@"%s", partialLine];
				free(partialLine);
			}
			
			
			//Parse and evaluate the data we just read in from the user, and print out the result.
			id result = [evaluator parseAndEvaluateString:line];
			fprintf(stdout, "=> %s\n", [[result prettyDescription] UTF8String]);
		}
		@catch (NSException *e)
		{
			fprintf(stderr, "Error: %s\n", [[e reason] UTF8String]);
		}
		@finally
		{
			free(rawLine);
		}
	}
}

#pragma mark -

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
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	if((argc >= 2) && (strcmp(argv[1], "help") == 0))
	{
		Help();
		
		[pool drain];
		return 0;
	}
	
	//If we're only given one argument (the path of your executable), then we enter REPL mode.
	if(argc == 1)
	{
		STEvaluator *evaluator = [STEvaluator new];
		RunREPL(evaluator);
		[evaluator release];
	}
	else
	{
		NSArray *paths = nil;
		ProgramOptions options = 0;
		AnalyzeProgramArguments(argc, argv, &paths, &options);
		
		STEvaluator *evaluator = [STEvaluator new];
		if(FlagIsSet(options, kProgramOptionRunREPLInBackground))
		{
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				if(FlagIsSet(options, kProgramOptionSandboxEachFile))
				{
					STEvaluator *replEvaluator = [STEvaluator new];
					RunREPL(replEvaluator);
					[replEvaluator release];
				}
				else
				{
					RunREPL(evaluator);
				}
				
				exit(EXIT_SUCCESS);
			});
		}
		
		NSError *error = nil;
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
				NSArray *expressions = [evaluator parseString:fileContents];
				
				//
				//	If we're in parse only mode, we simply print the
				//	data we parsed and go along our merry way.
				//
				if(FlagIsSet(options, kProgramOptionParseOnly))
				{
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[expressions prettyDescription] UTF8String]);
				}
				else
				{
					id result = [evaluator evaluateExpression:expressions inScope:nil];
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[result prettyDescription] UTF8String]);
				}
				
				//
				//	If we're sandboxing each file, we release the evaluator we have
				//	going now and create a new one in it's place. This prevents the
				//	next file from accssing something from the old evaluator.
				//
				//	This does not guarantee the old evaluator is gone, it will stick
				//	around if there are any valid closures or classes that were created
				//	through it.
				//
				if(FlagIsSet(options, kProgramOptionSandboxEachFile))
				{
					[evaluator release];
					evaluator = [STEvaluator new];
				}
			}
			@catch (NSException *e)
			{
				fprintf(stderr, "Error in file %s: %s\n", [path UTF8String], [[e reason] UTF8String]);
			}
		}
		
		[evaluator release];
	}
	
	[pool drain];
	return 0;
}
