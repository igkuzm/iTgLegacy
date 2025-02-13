/*
 *  UIInputToolbar.m
 *
 *  Created by Brandon Hamilton on 2011/05/03.
 *  Copyright 2011 Brandon Hamilton.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 */

#import "BHInputToolbar.h"
#include "UIKit/UIKit.h"

@implementation BHInputToolbar

-(void)inputButtonPressed
{
		NSString *text = self.textView.text;
    
		/* Remove the keyboard and clear the text */
    [self.textView resignFirstResponder];
    [self.textView.internalTextView resignFirstResponder];
    [self.textView clearText];
		self.textView.internalTextView.text = @"";

		if ([self.inputDelegate respondsToSelector:
									@selector(inputButtonPressed:)])
    {
        [self.inputDelegate inputButtonPressed:text];
    }
}

-(void)setupToolbar:(NSString *)buttonLabel
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
    self.tintColor = [UIColor lightGrayColor];

    /* Create custom send button*/
    //UIImage *buttonImage = [UIImage imageNamed:@"buttonbg.png"];
    UIImage *buttonImage = [UIImage imageNamed:@"Send"];
    //buttonImage          = [buttonImage stretchableImageWithLeftCapWidth:floorf(buttonImage.size.width/2) topCapHeight:floorf(buttonImage.size.height/2)];

		UIButton *button               = [UIButton buttonWithType:
																					UIButtonTypeCustom];
		//button.titleLabel.font         = [UIFont boldSystemFontOfSize:15.0f];
		//button.titleLabel.shadowOffset = CGSizeMake(0, -1);
		//button.titleEdgeInsets         = UIEdgeInsetsMake(0, 2, 0, 2);
		//button.contentStretch          = CGRectMake(0.5, 0.5, 0, 0);
		//button.contentMode             = UIViewContentModeScaleToFill;

		[button setBackgroundImage:buttonImage 
											forState:UIControlStateNormal];
		//[button setTitle:buttonLabel forState:UIControlStateNormal];
		[button addTarget:self 
							 action:@selector(inputButtonPressed) 
		 forControlEvents:UIControlEventTouchDown];
		[button sizeToFit];

		//self.inputButton = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"Send"]	
		//style:UIBarButtonItemStyleDone 
		//target:self action:@selector(inputButtonPressed)];

    self.inputButton = [[UIBarButtonItem alloc] 
			initWithCustomView:button];
    self.inputButton.customView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    /* Disable button initially */
    self.inputButton.enabled = NO;

		// record button
		self.recordButton = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"ios-mic-32"] 
						style:UIBarButtonItemStyleBordered
					 target:self action:@selector(recordSwitch:)];
    self.recordButton.customView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    /* Disable button initially */

		// attach button
    UIImage *attachImage = [UIImage 
			imageNamed:@"InputAttachmentsSeparatorAttachments"];
		UIButton *attachButton = [UIButton buttonWithType:
																					UIButtonTypeCustom];
		[attachButton setBackgroundImage:attachImage 
														forState:UIControlStateNormal];
		[attachButton addTarget:self 
										 action:@selector(onAdd:) 
					 forControlEvents:UIControlEventTouchDown];
		[attachButton sizeToFit];
		
		self.attachButton = [[UIBarButtonItem alloc]
			initWithCustomView:attachButton];
		//initWithImage:[UIImage imageNamed:@"InputAttachmentsSeparatorAttachments"]	
		//style:UIBarButtonItemStylePlain 
		//target:self action:@selector(onAdd:)];
    self.attachButton.customView.autoresizingMask = 
			UIViewAutoresizingFlexibleTopMargin;

    /* Create UIExpandingTextView input */
    self.textView = [[BHExpandingTextView alloc] initWithFrame:
			CGRectMake(35, 7, self.bounds.size.width - 84, 26)];
    self.textView.internalTextView.scrollIndicatorInsets = UIEdgeInsetsMake(4.0f, 0.0f, 10.0f, 0.0f);
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    self.textView.delegate = self;
		self.textView.placeholder = @"enter message...";
		//self.entry = 
			//[[UIBarButtonItem alloc]initWithCustomView:self.textView];
    [self addSubview:self.textView];
		self.textView.internalTextView.inputAccessoryView = self;

		// progress
		self.cancel = [[UIBarButtonItem alloc]
			initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
			target:self action:@selector(onCancel:)];
		
		self.progressLabel = [[UILabel alloc]
			initWithFrame:CGRectMake(0, 0, 60, 40)];
		self.progressLabel.numberOfLines = 2;
		self.progressLabel.lineBreakMode = NSLineBreakByCharWrapping;
		self.progressLabel.backgroundColor = [UIColor clearColor];
		self.progressLabel.font = [UIFont systemFontOfSize:8];
		self.label = [[UIBarButtonItem alloc]
			initWithCustomView:self.progressLabel];

		self.progressView = [[UIProgressView alloc]
			initWithProgressViewStyle:UIProgressViewStyleBar];
		self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.progress = [[UIBarButtonItem alloc]
			initWithCustomView:self.progressView];

    /* Right align the toolbar button */
    self.flexItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];

		[self setToolbarDefault];
}

-(id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        [self setupToolbar:@"Send"];
    }
    return self;
}

-(id)init
{
    if ((self = [super init])) {
        [self setupToolbar:@"Send"];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    /* Draw custon toolbar background */
    UIImage *backgroundImage = [UIImage imageNamed:@"toolbarbg.png"];
    backgroundImage = [backgroundImage stretchableImageWithLeftCapWidth:floorf(backgroundImage.size.width/2) topCapHeight:floorf(backgroundImage.size.height/2)];
    [backgroundImage drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];

    CGRect i = self.inputButton.customView.frame;
    i.origin.y = self.frame.size.height - i.size.height - 7;
    self.inputButton.customView.frame = i;

		CGRect k = self.attachButton.customView.frame;
    k.origin.y = self.frame.size.height - k.size.height - 7;
    self.attachButton.customView.frame = k;
}

#pragma mark -
#pragma mark UIExpandingTextView delegate

-(void)expandingTextView:(BHExpandingTextView *)expandingTextView willChangeHeight:(float)height
{
    /* Adjust the height of the toolbar when the input component expands */
    float diff = (self.textView.frame.size.height - height);
    CGRect r = self.frame;
    r.origin.y += diff;
    r.size.height -= diff;
    self.frame = r;
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //[self.inputDelegate expandingTextView:expandingTextView willChangeHeight:height];
    //}
}

-(void)expandingTextViewDidChange:(BHExpandingTextView *)expandingTextView
{
    /* Enable/Disable the button */
	if ([expandingTextView.text length] > 0){ 
		self.inputButton.enabled = YES;
	} else{
    self.inputButton.enabled = NO;
    //if ([self.inputDelegate respondsToSelector:@selector(expandingTextViewDidChange:)])
        //[self.inputDelegate expandingTextViewDidChange:expandingTextView];
	}
}

- (BOOL)expandingTextViewShouldReturn:(BHExpandingTextView *)expandingTextView
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //return [self.inputDelegate expandingTextViewShouldReturn:expandingTextView];
    //}
    
    return YES;
}

- (BOOL)expandingTextViewShouldBeginEditing:(BHExpandingTextView *)expandingTextView
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //return [self.inputDelegate expandingTextViewShouldBeginEditing:expandingTextView];
    //}
    return YES;
}

- (BOOL)expandingTextViewShouldEndEditing:(BHExpandingTextView *)expandingTextView
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //return [self.inputDelegate expandingTextViewShouldEndEditing:expandingTextView];
    //}
    return YES;
}

- (void)expandingTextViewDidBeginEditing:(BHExpandingTextView *)expandingTextView
{
	[self setToolbarEntry];
	[self.textView.internalTextView becomeFirstResponder];
	//if ([self.inputDelegate respondsToSelector:_cmd]) {
			//[self.inputDelegate expandingTextViewDidBeginEditing:expandingTextView];
	//}
}

- (void)expandingTextViewDidEndEditing:(BHExpandingTextView *)expandingTextView
{
		[self setToolbarDefault];

    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //[self.inputDelegate expandingTextViewDidEndEditing:expandingTextView];
    //}
}

- (BOOL)expandingTextView:(BHExpandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //return [self.inputDelegate expandingTextView:expandingTextView shouldChangeTextInRange:range replacementText:text];
    //}
    return YES;
}

- (void)expandingTextView:(BHExpandingTextView *)expandingTextView didChangeHeight:(float)height
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //[self.inputDelegate expandingTextView:expandingTextView didChangeHeight:height];
    //}
}

- (void)expandingTextViewDidChangeSelection:(BHExpandingTextView *)expandingTextView
{
    //if ([self.inputDelegate respondsToSelector:_cmd]) {
        //[self.inputDelegate expandingTextViewDidChangeSelection:expandingTextView];
    //}
}

-(void)recordSwitch:(id)sender{
	//UISwitch *s = sender;
	UIBarButtonItem *record = sender;
	if (record.style == UIBarButtonItemStyleBordered){
		record.style = UIBarButtonItemStyleDone;
		self.textView.editable = NO;
		self.textView.text = @"";
		self.textView.placeholder = @"Recording audio...";
		if (self.inputDelegate)
			if ([self.inputDelegate respondsToSelector:@selector(recordButtonStart)])
				[self.inputDelegate recordButtonStart];
	}
	else {
		record.style = UIBarButtonItemStyleBordered;
		if (self.inputDelegate)
			if ([self.inputDelegate respondsToSelector:@selector(recordButtonStop)])
				[self.inputDelegate recordButtonStop];
		self.textView.editable = YES;
		self.textView.text = @"";
		self.textView.placeholder = @"Enter message...";
	}
}

- (void)onAdd:(id)sender{
		if (self.inputDelegate)
			if ([self.inputDelegate respondsToSelector:@selector(attachButtonPressed)])
				[self.inputDelegate attachButtonPressed];
}

- (void)onCancel:(id)sender{
		if (self.inputDelegate)
			if ([self.inputDelegate respondsToSelector:@selector(cancelButtonPressed)])
				[self.inputDelegate cancelButtonPressed];
}

-(void)setToolbarWithProgress{
	self.textView.hidden = YES;
	NSArray *items = [NSArray arrayWithObjects: 
		self.progress, self.label, self.flexItem, self.cancel, nil];
    
	[self setItems:items animated:YES];
}

-(void)setToolbarDefault{
	self.textView.hidden = NO;
	NSArray *items = [NSArray arrayWithObjects: 
		self.attachButton, self.flexItem, self.recordButton, nil];
	[self setItems:items animated:YES];
}

-(void)setToolbarEmpty{
	self.textView.hidden = YES;
	[self setItems:nil animated:YES];
}

-(void)setToolbarEntry{
	self.textView.hidden = NO;
	NSArray *items = 
		[NSArray arrayWithObjects: 
		self.attachButton, self.flexItem, self.inputButton, nil];
	[self setItems:items animated:YES];
    self.inputButton.customView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
}

@end

// vim:ft=objc
