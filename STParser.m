//
//  STParser.m
//  stein
//
//  Created by Peter MacWhinnie on 2009/12/11.
//  Copyright 2009 Stein Language. All rights reserved.
//

#import "STParser.h"
#import "STSymbol.h"
#import "STList.h"
#import "STStringWithCode.h"

#pragma mark Forward Declarations

typedef struct STParserState {
	NSString *string;
	NSUInteger stringLength;
	
	STCreationLocation creationLocation;
	NSUInteger index;
} STParserState;

static STList *GetExpressionAt(STParserState *parserState, BOOL usingDoNotation, BOOL isUnbordered);

#pragma mark -
#pragma mark Tools

static inline unichar SafelyGetCharacterAtIndex(NSString *string, NSUInteger index)
{
	if(index >= [string length])
		return 0;
	
	return [string characterAtIndex:index];
}

#pragma mark -
#pragma mark Character Definitions

#define LIST_QUOTE_CHARACTER				'\''

#define LIST_OPEN_CHARACTER					'('
#define LIST_CLOSE_CHARACTER				')'

#define DO_LIST_OPEN_CHARACTER				'{'
#define DO_LIST_CLOSE_CHARACTER				'}'

#define STRING_OPEN_CHARACTER				'"'
#define STRING_CLOSE_CHARACTER				'"'

#define SINGLELINE_COMMENT_CHARACTER		';'
#define	MULTILINE_COMMENT_OPEN_CHARACTER	'`'
#define	MULTILINE_COMMENT_CLOSE_CHARACTER	'`'

#define UNBORDERED_LIST_CLOSE_CHARACTER		','

#define CHAIN_SEPERATOR_CHARACTER			'!'

#pragma mark -
#pragma mark Checkers

ST_INLINE BOOL IsCharacterWhitespace(unichar character)
{
	return (character == ' ' || character == '\t' || character == '\n' || character == '\r');
}

ST_INLINE BOOL IsCharacterNewline(unichar character)
{
	return (character == '\n' || character == '\r');
}

ST_INLINE BOOL IsCharacterPartOfNumber(unichar character, BOOL isFirstCharacter)
{
	return isnumber(character) || (!isFirstCharacter && character == '.');
}

ST_INLINE BOOL IsCharacterPartOfIdentifier(unichar character, BOOL isFirstCharacter)
{
	return ((character != LIST_QUOTE_CHARACTER && 
			 character != LIST_OPEN_CHARACTER && 
			 character != LIST_CLOSE_CHARACTER &&
			 character != DO_LIST_OPEN_CHARACTER &&
			 character != DO_LIST_CLOSE_CHARACTER &&
			 character != UNBORDERED_LIST_CLOSE_CHARACTER &&
			 !IsCharacterWhitespace(character)) ||
			(!isFirstCharacter && IsCharacterPartOfNumber(character, NO)));
}

#pragma mark -

ST_INLINE void STParserStateUpdateCreationLocation(STParserState *parserState, unichar character)
{
	if(IsCharacterNewline(character))
	{
		parserState->creationLocation.offset = 1;
		parserState->creationLocation.line++;
	}
	else
	{
		parserState->creationLocation.offset++;
	}
}

#pragma mark -
#pragma mark Parsers

static void IgnoreCommentAt(STParserState *parserState, BOOL isMultiline)
{
	//If we're skipping a multi-line comment, we need to ignore the
	//opening character or we'll end up causing an infinite loop.
	if(isMultiline)
	{
		parserState->index++;
		STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
	}
	
	for (NSUInteger index = parserState->index; index < parserState->stringLength; index++)
	{
		unichar character = [parserState->string characterAtIndex:index];
		
		if(character == '\\')
		{
			continue;
		}
		else if((isMultiline && character == MULTILINE_COMMENT_CLOSE_CHARACTER) || 
				(!isMultiline && IsCharacterNewline(character)))
		{
			if(isMultiline)
				parserState->index = index;
			else
				parserState->index = index - 1;
			
			return;
		}
		
		STParserStateUpdateCreationLocation(parserState, character);
	}
	
	//We only reach here if we EOF without finding a newline.
	parserState->index = parserState->stringLength - 1;
}

#pragma mark -

static NSNumber *GetNumberAt(STParserState *parserState)
{
	NSRange numberRange;
	numberRange.location = parserState->index;
	numberRange.length = NSNotFound;
	
	for (NSUInteger index = parserState->index; index < parserState->stringLength; index++)
	{
		unichar character = [parserState->string characterAtIndex:index];
		
		//If we're at the beginning of the number, and there's a
		//minus sign, we just add that to our range and continue.
		if(character == '-' && index == parserState->index)
		{
			STParserStateUpdateCreationLocation(parserState, character);
			continue;
		}
		
		if(!IsCharacterPartOfNumber(character, (index == parserState->index)))
		{
			numberRange.length = (index - numberRange.location);
			parserState->index = index - 1;
			
			break;
		}
		
		STParserStateUpdateCreationLocation(parserState, character);
	}
	if(numberRange.length == NSNotFound)
	{
		numberRange.length = ([parserState->string length] - parserState->index);
		parserState->index = [parserState->string length];
	}
	
	return [NSNumber numberWithDouble:[[parserState->string substringWithRange:numberRange] doubleValue]];
}

static id GetStringAt(STParserState *parserState)
{
	NSMutableString *resultString = [NSMutableString string];
	STStringWithCode *resultStringWithCode = nil;
	
	parserState->index++;
	STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
	
	for (NSUInteger index = parserState->index; index < parserState->stringLength; index++)
	{
		unichar character = [parserState->string characterAtIndex:index];
		
		if(character == STRING_CLOSE_CHARACTER)
		{
			parserState->index = index;
			
			break;
		}
		
		STParserStateUpdateCreationLocation(parserState, character);
		
		if(character == '\\')
		{
			unichar escapeCharacter = SafelyGetCharacterAtIndex(parserState->string, index + 1);
			NSCAssert((escapeCharacter != 0), @"Escape token found at end of file.");
			
			switch (escapeCharacter)
			{
				case 'a':
					[resultString appendString:@"\a"];
					break;
					
				case 'b':
					[resultString appendString:@"\b"];
					break;
					
				case 'f':
					[resultString appendString:@"\f"];
					break;
					
				case 'n':
					[resultString appendString:@"\n"];
					break;
					
				case 'r':
					[resultString appendString:@"\r"];
					break;
					
				case 't':
					[resultString appendString:@"\t"];
					break;
					
				case 'v':
					[resultString appendString:@"\v"];
					break;
					
				case '\'':
					[resultString appendString:@"\'"];
					break;
					
				case '"':
					[resultString appendString:@"\""];
					break;
					
				case '\\':
					[resultString appendString:@"\\"];
					break;
					
				case '?':
					[resultString appendString:@"\?"];
					break;
				
				case '%':
					[resultString appendString:@"%"];
					break;
					
				default:
					break;
			}
			
			//Move past the escape sequence
			index++;
		}
		else if(character == '%' && SafelyGetCharacterAtIndex(parserState->string, index + 1) == '(')
		{
			//Find the closing bracket.
			NSRange codeRange = NSMakeRange(index - 1, 0);
			NSUInteger numberOfNestedParentheses = 0;
			for (NSUInteger parentheseSearchIndex = index; parentheseSearchIndex < parserState->stringLength; parentheseSearchIndex++)
			{
				unichar innerCharacter = [parserState->string characterAtIndex:parentheseSearchIndex];
				[resultString appendFormat:@"%C", innerCharacter];
				
				if(innerCharacter == '(')
				{
					numberOfNestedParentheses++;
				}
				else if(innerCharacter == ')')
				{
					numberOfNestedParentheses--;
					if(numberOfNestedParentheses == 0)
					{
						codeRange.length = parentheseSearchIndex - codeRange.location;
						index = parentheseSearchIndex;
						
						break;
					}
				}
				
				STParserStateUpdateCreationLocation(parserState, innerCharacter);
			}
			
			NSString *expressionString = [parserState->string substringWithRange:NSMakeRange(codeRange.location + 3, 
																							 codeRange.length - 3)];
			STParserState expressionState = {
				.string = expressionString,
				.stringLength = [expressionString length],
				.creationLocation = {1, 1},
				.index = 0,
			};
			id expression = GetExpressionAt(&expressionState, NO, YES);
			if(!resultStringWithCode)
				resultStringWithCode = [STStringWithCode new];
			
			[resultStringWithCode addExpression:expression 
										inRange:NSMakeRange([resultString length] - [expressionString length] - 3, [expressionString length] + 3)];
		}
		else
		{
			[resultString appendFormat:@"%C", character];
		}
	}
	
	if(resultStringWithCode)
	{
		resultStringWithCode.string = resultString;
		return resultStringWithCode;
	}
	
	return resultString;
}

static STSymbol *GetIdentifierAt(STParserState *parserState)
{
	STCreationLocation symbolCreationLocation = parserState->creationLocation;
	
	NSRange identifierRange;
	identifierRange.location = parserState->index;
	identifierRange.length = NSNotFound;
	
	for (NSUInteger index = parserState->index; index < parserState->stringLength; index++)
	{
		unichar character = [parserState->string characterAtIndex:index];
		
		if(!IsCharacterPartOfIdentifier(character, (index == identifierRange.location)) || (character == ':'))
		{
			if(character == ':')
			{
				index++;
				STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:index]);
			}
			
			identifierRange.length = (index - identifierRange.location);
			parserState->index = index - 1;
			
			break;
		}
		
		STParserStateUpdateCreationLocation(parserState, character);
	}
	if(identifierRange.length == NSNotFound)
	{
		identifierRange.length = ([parserState->string length] - parserState->index);
		parserState->index = parserState->stringLength;
	}
	
	STSymbol *symbol = [STSymbol symbolWithString:[parserState->string substringWithRange:identifierRange]];
	symbol.creationLocation = symbolCreationLocation;
	return symbol;
}

static STList *GetExpressionAt(STParserState *parserState, BOOL usingDoNotation, BOOL isUnbordered)
{
	STList *expression = [STList list];
	expression.creationLocation = parserState->creationLocation;
	
	if(usingDoNotation)
	{
		parserState->index++;
		
		expression.flags |= kSTListFlagIsQuoted | kSTListFlagIsDefinition;
	}
	else if(!isUnbordered)
	{
		parserState->index++;
		
		if([parserState->string characterAtIndex:parserState->index] == LIST_QUOTE_CHARACTER)
		{
			parserState->index++;
			STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
			
			expression.flags |= kSTListFlagIsQuoted;
		}
	}
	
	for (; parserState->index < parserState->stringLength; parserState->index++)
	{
		unichar character = [parserState->string characterAtIndex:parserState->index];
		
		if(character == DO_LIST_CLOSE_CHARACTER)
		{
			//If we're unbordered then we need to move back one character
			//so that any containing do-dot statement will see it's closing
			//character. This will also result in error reporting when a
			//dot is used outside of a do-dot statement.
			if(isUnbordered)
			{
				parserState->index--;
				STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
			}
			
			break;
		}
		
		//If we're unbordered and we've encountered a newline, our expression is done.
		if(isUnbordered && (character == UNBORDERED_LIST_CLOSE_CHARACTER || IsCharacterNewline(character)))
		{
			STParserStateUpdateCreationLocation(parserState, character);
			break;
		}
		if(isUnbordered && (character == CHAIN_SEPERATOR_CHARACTER))
		{
			parserState->index++;
			STParserStateUpdateCreationLocation(parserState, character);
			
			//The chain separator causes the current expression to be used as the
			//head of a new expression. This allows clean message chaining.
			STList *oldExpression = expression;
			
			expression = [STList list];
			expression.creationLocation = parserState->creationLocation;
			
			[expression addObject:oldExpression];
			
			//A chain separator followed immediately by a newline will result in that newline being ignored.
			if(IsCharacterNewline(SafelyGetCharacterAtIndex(parserState->string, parserState->index)))
			{
				parserState->index++;
				STParserStateUpdateCreationLocation(parserState, character);
			}
			
			continue;
		}
		//If we encounter whitespace we just ignore it.
		else if(IsCharacterWhitespace(character))
		{
			STParserStateUpdateCreationLocation(parserState, character);
			continue;
		}
		//If we encounter a backslash, we skip the next character
		else if(character == '\\')
		{
			parserState->index++;
			
			continue;
		}
		//If we encounter a comment, we just move to the end of it, ignoring it's contents.
		else if(character == SINGLELINE_COMMENT_CHARACTER || character == MULTILINE_COMMENT_OPEN_CHARACTER)
		{
			IgnoreCommentAt(parserState, (character == MULTILINE_COMMENT_OPEN_CHARACTER));
		}
		//If we encounter the word 'do' at the end of a line, we start do-notation expression parsing.
		else if(character == DO_LIST_OPEN_CHARACTER)
		{
			[expression addObject:GetExpressionAt(parserState, YES, NO)];
		}
		//If we're in do-notation, and we've gotten this far, we're looking for subexpressions.
		else if(usingDoNotation)
		{
			[expression addObject:GetExpressionAt(parserState, NO, YES)];
		}
		//If we find part of a number, we read it and add it to our expression.
		else if(IsCharacterPartOfNumber(character, YES) || 
				(character == '-' && IsCharacterPartOfNumber(SafelyGetCharacterAtIndex(parserState->string, parserState->index + 1), YES)))
		{
			[expression addObject:GetNumberAt(parserState)];
		}
		//If we find a string, we read it and add it to our expression.
		else if(character == STRING_OPEN_CHARACTER)
		{
			[expression addObject:GetStringAt(parserState)];
		}
		//If we find part of an identifier, we read it and add it to our expression.
		else if(IsCharacterPartOfIdentifier(character, YES))
		{
			[expression addObject:GetIdentifierAt(parserState)];
		}
		//If we find a quote character we scan the next subexpression as a quoted list.
		else if(character == LIST_QUOTE_CHARACTER)
		{
			//If there's another quote two characters away, we assume we're looking at a character literal.
			//Character literals can only be one character long, we do not support the weirdness that is 'abcd'.
			if(SafelyGetCharacterAtIndex(parserState->string, parserState->index + 2) == LIST_QUOTE_CHARACTER)
			{
				[expression addObject:[NSNumber numberWithLong:SafelyGetCharacterAtIndex(parserState->string, parserState->index + 1)]];
				
				//Move past the character and the closing quote.
				parserState->index += 2;
				STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
				
				continue;
			}
			
			unichar secondCharacter = SafelyGetCharacterAtIndex(parserState->string, parserState->index + 1);
			NSCAssert((secondCharacter != 0), 
					  @"Unexpected quote token at the end of a file.");
			
			if(secondCharacter == LIST_OPEN_CHARACTER)
			{
				[expression addObject:GetExpressionAt(parserState, NO, NO)];
			}
			else
			{
				//Move past the opening quote.
				parserState->index++;
				STParserStateUpdateCreationLocation(parserState, [parserState->string characterAtIndex:parserState->index]);
				
				STSymbol *identifier = GetIdentifierAt(parserState);
				identifier.isQuoted = YES;
				[expression addObject:identifier];
			}
		}
		//If we encounter the list open character we scan the next subexpression.
		else if(character == LIST_OPEN_CHARACTER)
		{
			[expression addObject:GetExpressionAt(parserState, NO, NO)];
		}
		//If we encounter the list close character, we're done this expression and return.
		else if(character == LIST_CLOSE_CHARACTER)
		{
			STParserStateUpdateCreationLocation(parserState, character);
			break;
		}
		//If we reach here, we've encountered an unexpected token.
		else
		{
			STRaiseIssue(parserState->creationLocation, @"Unexpected token «%C» when parsing.", character);
		}
	}
	
	return expression;
}

#pragma mark -
#pragma mark Exported Interface

NSArray *STParseString(NSString *string)
{
	NSCParameterAssert(string);
	
	NSMutableArray *expressions = [NSMutableArray array];
	
	STParserState parserState = {
		.string = string,
		.stringLength = [string length],
		
		.index = 0,
		
		.creationLocation = { .line = 1, .offset = 1 },
	};
	for (; parserState.index < parserState.stringLength; parserState.index++)
	{
		unichar character = [parserState.string characterAtIndex:parserState.index];
		STParserStateUpdateCreationLocation(&parserState, character);
		
		//We ignore whitespace, it doesn't really do anything.
		if(IsCharacterWhitespace(character))
		{
			continue;
		}
		//If we encounter a backslash, we skip the next character
		else if(character == '\\')
		{
			parserState.index++;
			
			continue;
		}
		//When we encounter comments, we move to the end of them and ignore their contents.
		else if(character == SINGLELINE_COMMENT_CHARACTER || character == MULTILINE_COMMENT_OPEN_CHARACTER)
		{
			IgnoreCommentAt(&parserState, (character == MULTILINE_COMMENT_OPEN_CHARACTER));
		}
		//When we reach this clause it's time to start parsing the line as though it's an expression.
		else
		{
			[expressions addObject:GetExpressionAt(&parserState, NO, YES)];
		}
	}
	
	return expressions;
}
