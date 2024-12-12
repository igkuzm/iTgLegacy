#import "DialogViewCell.h"
#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "QuartzCore/QuartzCore.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
#import "../libtg/tg/peer.h"
#import "../libtg/tg/files.h"

@implementation DialogViewCell
- (id)init
{
	if (self = [super init]) {
		self.title = [[UILabel alloc] init];
		[self.contentView addSubview:self.title];
		self.message = [[UILabel alloc] init];
		[self.contentView addSubview:self.message];
    self.time = [[UILabel alloc] init];
		[self.contentView addSubview:self.time];
		self.unreadView = [[UIView alloc] init];
		[self.contentView addSubview:self.unreadView];
		self.unread = [[UILabel alloc] init];
		[self.unreadView addSubview:self.unread];
	}
	return self;
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	// title label
	[self.title setFrame: 
		CGRectMake(
				60, 
				0, 
				frame.size.width - 120, 
				16)];
	self.title.font = [UIFont boldSystemFontOfSize:13];

	[self.message setFrame: 
		CGRectMake(
				60, 
				self.title.frame.size.height + 2, 
				frame.size.width - 110, 
				40)];
	self.message.font = [UIFont systemFontOfSize:12];
  self.message.numberOfLines = 0;
  self.message.lineBreakMode = UILineBreakModeWordWrap;

	// make time label
	[self.time setFrame:
			CGRectMake(
				frame.size.width - 60, 
				0, 
				50, 
				14)];
	self.time.numberOfLines = 1;
	self.time.font = [UIFont systemFontOfSize:8];
	self.time.textColor = [UIColor blueColor];
		
	// unread mark
	[self.unreadView setFrame:
			CGRectMake(
				frame.size.width - 60, 
				16, 
				30, 
				14)];
	self.unreadView.layer.cornerRadius = 9.0;
	self.unreadView.backgroundColor = [UIColor grayColor];
	[self.unread setFrame:
			CGRectMake(
				0, 
				0, 
				25, 
				14)];
	self.unread.font = [UIFont systemFontOfSize:9];
	self.unread.textColor = [UIColor whiteColor];
	self.unread.textAlignment = NSTextAlignmentCenter;
}

- (NSDateComponents *)dateCompFromDate:(NSDate *)date{
	NSInteger c = NSHourCalendarUnit|NSMinuteCalendarUnit|
		NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit;
	
	return [[NSCalendar currentCalendar]
		components: c
		fromDate:date];
}

- (UIImage *)imageWithImage:(UIImage *)image convertToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return destImage;
}

- (void)setDialog:(TGDialog *)dialog {
	AppDelegate *delegate = 
		[[UIApplication sharedApplication]delegate]; 

	self.title.text = dialog.title;
	self.message.text = dialog.top_message;
	
	if (dialog.photo)
		self.imageView.image = dialog.photo;
	else if (dialog.thumb)	
		self.imageView.image = [self 
			imageWithImage:dialog.thumb 
			convertToSize:CGSizeMake(50, 50)];
	else
		self.imageView.image = [UIImage imageNamed:@"missingAvatar.png"];

	NSDateComponents *now  = [self dateCompFromDate:[NSDate date]];
	NSDateComponents *then = [self dateCompFromDate:dialog.date];
	if (now.year == then.year && 
			now.month == then.month &&
			now.day == then.day)
	{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"HH:mm";
		self.time.text = [dateFormatter stringFromDate:dialog.date];
	} else {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"dd.MM.yyyy";
		self.time.text = [dateFormatter stringFromDate:dialog.date];
	}

	if (dialog.unread_count > 0){
		self.unread.text = 
			[NSString stringWithFormat:@"%d", dialog.unread_count];
		self.unread.hidden = NO;
	} else {
		self.unread.hidden = YES;
	}
}
@end
// vim:ft=objc
