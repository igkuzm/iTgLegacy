/*
 *  UIInputToolbar.h
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

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "BHExpandingTextView.h"

@protocol BHInputToolbarDelegate <BHExpandingTextViewDelegate>
@optional
-(void)inputButtonPressed:(NSString *)inputText;
-(void)recordButtonStart;
-(void)recordButtonStop;
-(void)attachButtonPressed;
-(void)cancelButtonPressed;
@end

@interface BHInputToolbar : UIToolbar <BHExpandingTextViewDelegate>

- (void)drawRect:(CGRect)rect;

@property (nonatomic, strong) BHExpandingTextView *textView;
@property (nonatomic, strong) UIBarButtonItem *entry;
@property (nonatomic, strong) UIBarButtonItem *flexItem;
@property (nonatomic, strong) UIBarButtonItem *inputButton;
@property (nonatomic, strong) UIBarButtonItem *recordButton;
@property (nonatomic, strong) UIBarButtonItem *attachButton;
@property (nonatomic, strong) UILabel         *progressLabel;
@property (nonatomic, strong) UIBarButtonItem *label;
@property (nonatomic, strong) UIProgressView  *progressView;
@property (nonatomic, strong) UIBarButtonItem *progress;
@property (nonatomic, strong) UIBarButtonItem *cancel;
@property (nonatomic, weak) id<BHInputToolbarDelegate> inputDelegate;

-(void)setToolbarWithProgress;
-(void)setToolbarDefault;
-(void)setToolbarEmpty;
-(void)setToolbarEntry;

@end

// vim:ft=objc
