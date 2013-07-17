//
//  STInterpreter.m
//  stein
//
//  Created by Kevin MacWhinnie on 7/11/10.
//  Copyright 2010 Stein Language. All rights reserved.
//

#import "STInterpreter.h"
#import "NSObject+SteinTools.h"

#import "STClosure.h"
#import "STFunction.h"
#import "STScope.h"
#import "STEnumerable.h"

#import "STParser.h"
#import "STList.h"
#import "STSymbol.h"
#import "STStringWithCode.h"

#import "STBuiltInFunctions.h"
#import "SteinException.h"

#pragma mark Evaluation

static id LambdaFromDefinition(STList *definition, STScope *scope)
{
	STList *prototype = nil;
	STList *body = nil;
	if(ST_FLAG_IS_SET([[definition head] flags], kSTListFlagIsDefinitionParameters))
	{
		prototype = [definition head];
		[prototype replaceValuesByPerformingSelectorOnEachObject:@selector(string)];
		
		body = [definition tail];
	}
	else
	{
		prototype = [[STList alloc] init];
		body = definition;
	}
	
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
	
	STList *evaluatedArguments = [[STList alloc] init];
	for (id expression in [list tail])
		[evaluatedArguments addObject:STEvaluate(expression, scope)];
	
	return [target applyWithArguments:evaluatedArguments inScope:scope];
}

id STEvaluate(id expression, STScope *scope)
{
	@try
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
			
			if([expression isEqual:@"$here"])
				return scope;
			
            NSString *expressionString = [expression string];
            if([expressionString hasPrefix:@"@"])
            {
                id self = [scope valueForVariableNamed:@"self" searchParentScopes:YES];
                if(!self)
                    STRaiseIssue([expression creationLocation], @"Attempting to access an ivar outside of class scope.");
                
                return [self valueForIvarNamed:[expression string]];
            }
            
			id result = [expressionString rangeOfString:@"."].location != NSNotFound? [scope valueForKeyPath:expressionString] : [scope valueForKey:expressionString];
			if(!result)
			{
                result = STBuiltInFunctionLookUp(expressionString);
                if(!result)
                {
                    if([expressionString hasPrefix:@"PRT"])
                        STRaiseIssue([expression creationLocation], @"Cannot access classes in the PRT (private runtime) namespace.");
                    else if([expressionString hasPrefix:@"$__"])
                        STRaiseIssue([expression creationLocation], @"Cannot access classes with randomized names.");
                    
                    result = NSClassFromString(expressionString);
                    if(!result)
                        STRaiseIssue([expression creationLocation], @"Reference to unbound variable %@", expressionString);
                }
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
	}
	@catch (STBreakException *e)
	{
		STRaiseIssue(e.creationLocation, @"break called outside of enumerable context");
	}
	@catch (STContinueException *e)
	{
		STRaiseIssue(e.creationLocation, @"continue called outside of enumerable context");
	}
	@catch (SteinException *e)
	{
		@throw;
	}
	@catch (NSException *e)
	{
		@throw [[SteinException alloc] initWithException:e];
	}
	
	return expression;
}

#pragma mark - Core Scope

STScope *STGetSharedRootScope()
{
    static STScope *sharedRootScope = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedRootScope = [STScope new];
        sharedRootScope.name = @"$global-scope";
        
        [sharedRootScope setValue:[NSDecimalNumber minimumDecimalNumber] forConstantNamed:@"$min-number"];
        [sharedRootScope setValue:[NSDecimalNumber maximumDecimalNumber] forConstantNamed:@"$max-number"];
        
        [sharedRootScope setValue:[[NSProcessInfo processInfo] arguments] forConstantNamed:@"$args"];
        [sharedRootScope setValue:[[NSProcessInfo processInfo] environment] forConstantNamed:@"$env"];
        
        [sharedRootScope setValue:STTrue forConstantNamed:@"true"];
        [sharedRootScope setValue:STFalse forConstantNamed:@"false"];
        [sharedRootScope setValue:STNull forConstantNamed:@"nil"];
        [sharedRootScope setValue:ST_SYM(@"_") forConstantNamed:@"_"];
        
        [sharedRootScope setValue:@"" forVariableNamed:@"$file" searchParentScopes:NO];
    });
    
    return sharedRootScope;
}
