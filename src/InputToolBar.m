#import "InputToolBar.h"
#include "UIKit/UIKit.h"

@interface  InputToolBar()
{
}
@end

@implementation InputToolBar
- (id)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		self.textView = [[UITextView alloc]initWithFrame: CGRectMake(
					35, 7, 
					self.bounds.size.width - 84, 26)];
    self.textView.scrollIndicatorInsets = UIEdgeInsetsMake(
				4.0f, 0.0f, 10.0f, 0.0f);
    self.textView.autoresizingMask = 
			UIViewAutoresizingFlexibleRightMargin |
		 	UIViewAutoresizingFlexibleWidth |
		 	UIViewAutoresizingFlexibleHeight ;
		self.textView.inputAccessoryView = self;
		self.textView.delegate = self;
		[self addSubview:self.textView];

		//self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
		//[self.sendButton setBackgroundImage:
				//[UIImage imageNamed:@"send"] forState:UIControlStateNormal];
		//[self addSubview:self.sendButton];
	}
	return self;
}

#pragma mark <UITextView Delegate>
-(void)textViewSetHeight:(UITextView *)textView{
	CGRect frame = self.frame;

	int numLines = 
		textView.contentSize.height / textView.font.lineHeight;

	if (numLines < 8){
		//CGFloat height = textView.contentSize.height;
		frame.size.height += numLines*textView.font.lineHeight; 
		self.frame = frame;
		textView.showsVerticalScrollIndicator = NO;
	} else
		textView.showsVerticalScrollIndicator = YES;
}

- (void)textViewDidChange:(UITextView *)textView {
	[self textViewSetHeight:self.textView];
	[self.textView sizeToFit];
}

@end

// vim:ft=objc
