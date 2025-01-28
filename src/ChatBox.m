#import "ChatBox.h"
#include "UIKit/UIKit.h"

@implementation ChatBox  

//@synthesize textView;

- (id)init
{
	if (self = [super init]) {
		self.textView = [[UITextView alloc]init];	
		self.textView.inputAccessoryView = self;
		self.textView.delegate = self;
		self.textView.text = @"test";
		self.textView.editable = YES;
		self.textView.frame = self.bounds;
		self.textView.autoresizingMask = 
			UIViewAutoresizingFlexibleWidth|
			UIViewAutoresizingFlexibleHeight;
		[self addSubview:self.textView];
	}
	return self;
}

//- (void)setFrame:(CGRect)frame {
	//self.textView.frame = CGRectMake(
			//30, 10,
			//frame.size.width - 30, 
			//frame.size.height - 10); 
//}

- (void)textViewDidChange:(UITextView *)textView {
	[textView sizeToFit];
}

@end

// vim:ft=objc
