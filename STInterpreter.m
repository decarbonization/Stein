//
//  STInterpreter.m
//  stein
//
//  Created by Peter MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STInterpreter.h"

#import <readline/readline.h>
#import "NSObject+Stein.h"

#import "STClosure.h"
#import "STFunction.h"
#import "STScope.h"

#import "STParser.h"
#import "STList.h"
#import "STSymbol.h"
#import "STStringWithCode.h"

#import "STBuiltInFunctions.h"

#pragma mark Evaluation

static id LambdaFromDefinition(STList *definition, STScope *scope)
{
	STList *prototype = [definition head];
	[prototype replaceValuesByPerformingSelectorOnEachObject:@selector(string)];
	
	STList *body = [definition tail];
	body.flags = kSTListFlagsNone;
	
	return [[STClosure alloc] initWithPrototype:prototype forImplementation:body inScope:scope];
}

static id EvaluateList(STList *list, STScope *scope)
{
	if(ST_FLAG_IS_SET(list.flags, kSTListFlagIsDefinition))
		return LambdaFromDefinition(list, scope);
	if(ST_FLAG_IS_SET(list.flags, kSTListFlagIsQuoted))
		return list;
	
	//An empty list is considered <null>
	NSUInteger listCount = list.count;
	if(listCount == 0)
		return STNull;
	else if(listCount == 1)
		return STEvaluate([list head], scope);
	
	id <STFunction> target = STEvaluate([list head], scope);
	if([target evaluatesOwnArguments])
		return [target applyWithArguments:[list tail] inScope:scope];
	
	STList *evaluatedArguments = [STList list];
	for (id expression in [list tail])
		[evaluatedArguments addObject:STEvaluate(expression, scope)];
	
	return [target applyWithArguments:evaluatedArguments inScope:scope];
}

id STEvaluate(id expression, STScope *scope)
{
	if([expression isKindOfClass:[NSArray class]])
	{
		id lastResult = nil;
		for (id subexpression in expression)
			lastResult = STEvaluate(subexpression, scope);
		
		return lastResult;
	}
	else if([expression isKindOfClass:[STList class]])
	{
		return EvaluateList(expression, scope);
	}
	else if([expression isKindOfClass:[STSymbol class]])
	{
		if([expression isQuoted])
			return expression;
		
		id result = [scope valueForVariableNamed:[expression string] searchParentScopes:YES];
		if(!result)
		{
			result = NSClassFromString([expression string]);
			if(!result)
				STRaiseIssue([expression creationLocation], @"Reference to unbound variable %@", [expression string]);
		}
		
		return result;
	}
	else if([expression isKindOfClass:[STStringWithCode class]])
	{
		return [expression applyInScope:scope];
	}
	else if([expression isKindOfClass:[NSString class]])
	{
		return [expression copy];
	}
	
	return expression;
}

#pragma mark -
#pragma mark Utilities

int STMain(int argc, const char *argv[], NSString *filename)
{
	NSCParameterAssert(filename);
	
	NSURL *mainFile = [[NSBundle mainBundle] URLForResource:filename withExtension:@"st"];
	NSCAssert((mainFile != nil), @"Could not find file %@ in main bundle.", filename);
	
	NSError *error = nil;
	NSString *source = [NSString stringWithContentsOfURL:mainFile encoding:NSUTF8StringEncoding error:&error];
	NSCAssert((source != nil), @"Could not load file %@ in main bundle. Error {%@}.", filename, error);
	
	id result = STEvaluate(STParseString(source), STBuiltInFunctionScope());
	if(!result)
		return EXIT_SUCCESS;
	
	return [result intValue];
}

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

void STRunREPL()
{
	//Initialize readline so we get history.
	rl_initialize();
	
	//Create a scope
	STScope *scope = STBuiltInFunctionScope();
	
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
			id result = STEvaluate(STParseString(line), scope);
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
