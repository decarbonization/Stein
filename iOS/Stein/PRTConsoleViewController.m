//
//  REPLViewController.m
//  Stein
//
//  Created by Kevin MacWhinnie on 1/12/13.
//  Copyright (c) 2013 Kevin MacWhinnie. All rights reserved.
//

#import "PRTConsoleViewController.h"

///Analyze a string read from the REPL, and indicate the number of unbalanced parentheses and unbalanced brackets found.
///
/// \param		numberOfUnbalancedParentheses	On return, an integer describing the number of unbalanced parentheses in the specified string.
/// \param		numberOfUnbalancedBrackets		On return, an integer describing the number of unbalanced brackets in the specified string.
/// \param		string							The string to analyze.
///
///All parameters are required.
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
				
			case '{':
				(*numberOfUnbalancedBrackets)++;
				break;
				
			case '}':
				(*numberOfUnbalancedBrackets)--;
				break;
				
			default:
				break;
		}
	}
}

static NSUInteger const kHistoryMaxCount = 25;

@interface PRTConsoleViewController ()

@property (nonatomic) STScope *rootScope;

@property (nonatomic) NSString *prompt;

@property (nonatomic) NSUInteger lastPromptLocation;

@property (nonatomic) NSMutableString *multiLineBuffer;

@property (nonatomic) NSMutableArray *history;

@property (nonatomic) NSInteger historyCursor;

@end

@implementation PRTConsoleViewController

+ (instancetype)sharedConsoleViewController
{
    static PRTConsoleViewController *sharedREPLViewController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedREPLViewController = [PRTConsoleViewController new];
    });
    
    return sharedREPLViewController;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]))
    {
        self.multiLineBuffer = [NSMutableString string];
        self.prompt = @"> ";
        self.historyCursor = -1;
        self.history = [NSMutableArray array];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.textView.inputAccessoryView = self.inputAccessoryView;
    
    [self reset:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShowNotification:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillChangeFrameNotification:)
                                                 name:UIKeyboardWillChangeFrameNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideNotification:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [self.textView becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Interactivity

- (NSString *)lastLine
{
    NSString *paperTape = self.textView.text;
    return [paperTape substringWithRange:NSMakeRange(self.lastPromptLocation, paperTape.length - self.lastPromptLocation)];
}

- (void)deleteRange:(NSRange)range
{
    NSString *paperTape = self.textView.text;
    self.textView.text = [paperTape substringWithRange:range];
}

- (void)write:(NSString *)text
{
    self.textView.text = [self.textView.text stringByAppendingString:text];
}

- (void)writeLine:(NSString *)text
{
    [self write:[text stringByAppendingString:@"\n"]];
}

- (void)writePrompt
{
    [self write:self.prompt];
    self.lastPromptLocation = self.textView.text.length;
}

#pragma mark - UIKeyboard

- (void)keyboardWillShowNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.contentInset = UIEdgeInsetsMake(0.0, 0.0, CGRectGetHeight(keyboardFrame), 0.0);
        self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, CGRectGetHeight(keyboardFrame), 0.0);
    }];
}

- (void)keyboardWillChangeFrameNotification:(NSNotification *)notification
{
    CGRect keyboardFrame = [self.textView convertRect:[notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
    
    self.textView.contentInset = UIEdgeInsetsMake(0.0, 0.0, CGRectGetHeight(keyboardFrame), 0.0);
    self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0.0, CGRectGetHeight(keyboardFrame), 0.0);
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    [UIView animateWithDuration:duration animations:^{
        self.textView.contentInset = UIEdgeInsetsZero;
        self.textView.scrollIndicatorInsets = UIEdgeInsetsZero;
    }];
}

#pragma mark - <UITextViewDelegate>

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if(range.location < self.lastPromptLocation)
    {
        if(range.length > 0)
        {
            self.textView.selectedRange = NSMakeRange(self.textView.text.length, 0);
        }
        else
        {
            textView.text = [textView.text stringByAppendingString:text];
        }
        
        return NO;
    }
    
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    if([textView.text hasSuffix:@"\n"])
    {
        self.historyCursor = -1;
        
        NSString *line = [self lastLine];
        if([self.multiLineBuffer length] > 0)
        {
            [self.multiLineBuffer appendString:line];
            line = self.multiLineBuffer;
        }
        
        //Handle unbalanced pairs of parentheses and brackets.
        NSInteger numberOfUnbalancedParentheses = 0, numberOfUnbalancedBrackets = 0;
        FindUnbalancedExpressions(&numberOfUnbalancedParentheses, &numberOfUnbalancedBrackets, line);
        if(numberOfUnbalancedBrackets > 0 || numberOfUnbalancedParentheses > 0)
        {
            if([self.multiLineBuffer length] == 0)
                [self.multiLineBuffer appendString:line];
            
            self.prompt = @"";
        }
        else
        {
            if([self.multiLineBuffer length] > 0)
            {
                line = [self.multiLineBuffer copy];
                
                self.prompt = @"> ";
                self.multiLineBuffer.string = @"";
            }
            
            @try
            {
                id result = STEvaluate(STParseString(line, @"REPL"), _rootScope);
                [self writeLine:[result ?: STNull prettyDescription]];
            }
            @catch (NSException *exception)
            {
                [self writeLine:[exception reason]];
            }
            @catch (id object)
            {
                [self writeLine:[NSString stringWithFormat:@"Caught non-exception object %@", object]];
            }
            
            [self.history addObject:line];
            if([self.history count] > kHistoryMaxCount)
            {
                NSUInteger difference = self.history.count - kHistoryMaxCount;
                [self.history removeObjectsInRange:NSMakeRange(0, difference)];
            }
        }
        
        [self writePrompt];
    }
}

#pragma mark - Actions

- (IBAction)clear:(id)sender
{
    self.textView.text = [[self.textView.text componentsSeparatedByString:@"\n"] lastObject];
}

- (IBAction)reset:(id)sender
{
    self.textView.text = @"";
    
    self.rootScope = STGetSharedRootScope();
    
    NSError *error = nil;
    NSURL *cwd = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                        inDomain:NSUserDomainMask
                                               appropriateForURL:nil
                                                          create:YES 
                                                           error:&error];
    if(!cwd)
    {
        cwd = [NSURL URLWithString:NSHomeDirectory()];
        [self writeLine:[NSString stringWithFormat:@"*** warning: could not find default working directory. %@", error]];
    }
    
    [self.rootScope setValue:cwd forConstantNamed:@"$__Console_CWD_Default"];
    [self.rootScope setValue:cwd forVariableNamed:@"$__Console_CWD" searchParentScopes:NO];
    
    NSURL *consolePreludeLocation = [[NSBundle mainBundle] URLForResource:@"ConsolePrelude" withExtension:@"st"];
    
    NSString *consolePrelude = [NSString stringWithContentsOfURL:consolePreludeLocation
                                                        encoding:NSUTF8StringEncoding
                                                           error:&error];
    if(!consolePrelude)
    {
        [self write:@"stein not ready."];
        return;
    }
    
    STEvaluate(STParseString(consolePrelude, @"ConsolePrelude.st"), self.rootScope);
    
    [self writePrompt];
}

#pragma mark -

- (IBAction)insertSpecialCharacterFrom:(UIButton *)sender
{
    [self write:[sender titleForState:UIControlStateNormal]];
}

- (IBAction)insertTab:(id)sender
{
    [self write:@"    "];
}

#pragma mark -

- (IBAction)moveUpThroughHistory:(id)sender
{
    if(self.history.count == 0 || self.multiLineBuffer.length > 0)
        return;
    
    NSString *lastLine = [self lastLine];
    if(lastLine.length == 0)
    {
        NSString *recalledString = [self.history lastObject];
        self.historyCursor = self.history.count - 1;
        [self write:recalledString];
    }
    else if(self.historyCursor != -1 && self.historyCursor > 0)
    {
        [self deleteRange:NSMakeRange(self.lastPromptLocation, lastLine.length)];
        
        NSString *recalledString = self.history[--self.historyCursor];
        [self write:recalledString];
    }
}

- (IBAction)moveDownThroughHistory:(id)sender
{
    if(self.history.count == 0 || self.multiLineBuffer.length > 0)
        return;
    
    if(self.historyCursor != -1 && self.historyCursor < self.history.count)
    {
        NSString *lastLine = [self lastLine];
        [self deleteRange:NSMakeRange(self.lastPromptLocation, lastLine.length)];
        
        NSString *recalledString = self.history[++self.historyCursor];
        [self write:recalledString];
    }
}

@end
