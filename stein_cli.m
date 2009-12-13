#import <Foundation/Foundation.h>
#import <Stein/Stein.h>
#import <readline/readline.h>

#define FLAG_IS_SET(options, flag) ((options & flag) == flag)

void RunREPL()
{
	STEvaluator *evaluator = [STEvaluator new];
	
	//Initialize readline so we get history.
	rl_initialize();
	
	printf("stein ready [version %s]\n", [[SteinBundle() objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String]);
	for (;;)
	{
		const char *rawLine = readline("Stein> ");
		if(!rawLine || (strlen(rawLine) == 0) || (strcmp(rawLine, "quit") == 0) || (strcmp(rawLine, "exit") == 0))
		{
			fprintf(stdout, "goodbye\n");
			break;
		}
		
		@try
		{
			NSString *line = [NSString stringWithUTF8String:rawLine];
			id result = [evaluator parseAndEvaluateString:line];
			fprintf(stdout, "=> %s\n", [[result description] UTF8String]);
		}
		@catch (NSException *e)
		{
			fprintf(stderr, "Error: %s\n", [[e reason] UTF8String]);
		}
	}
	
	[evaluator release];
}

#pragma mark -

typedef enum ProgramOptions {
	kProgramOptionSandboxEachFile = (1 << 0),
	kProgramOptionParseOnly = (1 << 1),
} ProgramOptions;

void AnalyzeProgramArguments(int argc, const char *argv[], NSArray **outPaths, ProgramOptions *outOptions)
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
				case 's':
					options |= kProgramOptionSandboxEachFile;
					break;
					
				case 'p':
					options |= kProgramOptionParseOnly;
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

int main (int argc, const char * argv[])
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	//If we're only given one argument (the path of your executable), then we enter REPL mode.
	if(argc == 1)
	{
		RunREPL();
	}
	else
	{
		NSArray *paths = nil;
		ProgramOptions options = 0;
		AnalyzeProgramArguments(argc, argv, &paths, &options);
		
		NSError *error = nil;
		STEvaluator *evaluator = [STEvaluator new];
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
				if(FLAG_IS_SET(options, kProgramOptionParseOnly))
				{
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[expressions description] UTF8String]);
				}
				else
				{
					id result = [evaluator evaluateExpression:expressions];
					fprintf(stdout, "%s => %s\n", [path UTF8String], [[result description] UTF8String]);
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
				if(FLAG_IS_SET(options, kProgramOptionSandboxEachFile))
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
