#import "ChatViewCell.h"
#include "TGMessage.h"
#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "QuartzCore/QuartzCore.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
#import "../libtg/tg/peer.h"
#import "../libtg/tg/files.h"
#include "UIImage+Utils/UIImage+Utils.h"

@implementation ChatViewCell
- (id)init
{
	if (self = [super init]) {
		self.avatarView = [[UIImageView alloc]init];
		[self.imageView addSubview:self.avatarView];

		self.textView = [[UITextView alloc] init];
		self.textView.editable = NO;
		self.textView.dataDetectorTypes = UIDataDetectorTypeAll;
		self.textView.scrollEnabled = NO;
    self.textView.font = 
			[UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.textView.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:self.textView];
    
		self.timeLabael = [[UILabel alloc] init];
		[self.contentView addSubview:self.timeLabael];
		
		self.photoView = [[UIImageView alloc] init];
		[self.contentView addSubview:self.photoView];
	}
	return self;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];

	CGFloat x;
	if (self.message.mine){
		x = frame.size.width - 220;
	} else {
		x = 40;
		
		[self.avatarView setFrame:CGRectMake(
				0, 
				0, 
				40, 
				40)];
	}

	if (self.photoHeight){
		[self.photoView setFrame:CGRectMake(
				x, 
				0, 
				220, 
				self.photoHeight)];
	}

	if (self.textHeight){
		[self.text setFrame:CGRectMake(
				x, 
				self.photoHeight, 
				220, 
				self.textHeight)];
	}
}

- (NSDateComponents *)dateCompFromDate:(NSDate *)date{
	NSInteger c = NSHourCalendarUnit|NSMinuteCalendarUnit|
		NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit;
	
	return [[NSCalendar currentCalendar]
		components: c
		fromDate:date];
}

@end
// vim:ft=objc
