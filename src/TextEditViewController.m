/**
 * File              : TextEditViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 04.05.2021
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "TextEditViewController.h"
#include "UIKit/UIKit.h"

@interface TextEditViewController ()

@end

@implementation TextEditViewController

- (void)viewDidLoad {
  [super viewDidLoad];
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];

    // Do any additional setup after loading the view.
	UIBarButtonItem *save = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPushed:)];	
	
	self.navigationItem.rightBarButtonItems=@[save];	 

	self.scrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
	self.scrollView.autoresizingMask = 
		UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	self.scrollView.contentSize=CGSizeMake(self.view.frame.size.width, self.view.frame.size.height);
	[self.scrollView setBackgroundColor:[UIColor whiteColor]];
	[self.view addSubview:self.scrollView];

	self.textView = [[UITextView alloc]initWithFrame:self.view.bounds];
	self.textView.autoresizingMask = 
		UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
	[self.textView setFont:[UIFont fontWithName:@"arial" size:18]];
	//self.textView.delegate=self;
	[self.scrollView addSubview:self.textView];
	if (self.text)
		[self.textView setAttributedText:self.text];	
}

-(void)keyboardWillShow:(NSNotification *)notification{
	NSDictionary *userInfo = [notification userInfo];
	NSValue *keyboardFrame = [userInfo valueForKey:UIKeyboardFrameEndUserInfoKey];
	CGRect keyboardRect = keyboardFrame.CGRectValue;

	CGRect scrollViewFrame = self.scrollView.frame;
	[self.scrollView setContentSize:CGSizeMake(scrollViewFrame.size.width, scrollViewFrame.size.height + keyboardRect.size.height)];
}

-(void)saveButtonPushed:(id)sender{
 if (self.delegate)
	 [self.delegate textEditViewControllerSaveText:self.textView.text];
 if (self.navigationController)
	 [self.navigationController popViewControllerAnimated:YES];
 else
	 [self dismissViewControllerAnimated:YES completion:nil];
}

@end
