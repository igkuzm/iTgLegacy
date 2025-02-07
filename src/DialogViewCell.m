#import "DialogViewCell.h"
#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "QuartzCore/QuartzCore.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
#import "../libtg/tg/peer.h"
#import "../libtg/tg/files.h"
#include "UIImage+Utils/UIImage+Utils.h"
#import "Base64/Base64.h"

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
		self.unreadView = [[UIImageView alloc] init];
		[self.contentView addSubview:self.unreadView];
		self.unread = [[UILabel alloc] init];
		self.checkView = [[UIImageView alloc] init];
		[self.contentView addSubview:self.checkView];
		//[self.unreadView addSubview:self.unread];
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
				4, 
				frame.size.width - 120, 
				16)];
	self.title.font = [UIFont boldSystemFontOfSize:13];
	self.title.backgroundColor = [UIColor clearColor];

	// message
	[self.message setFrame: 
		CGRectMake(
				60, 
				self.title.frame.size.height + 2, 
				frame.size.width - 110, 
				40)];
	self.message.font = [UIFont systemFontOfSize:12];
  self.message.numberOfLines = 0;
  self.message.lineBreakMode = UILineBreakModeWordWrap;
	self.message.backgroundColor = [UIColor clearColor];

	// make time label
	[self.time setFrame:
			CGRectMake(
				frame.size.width - 60, 
				4, 
				80, 
				14)];
	self.time.numberOfLines = 1;
	self.time.font = [UIFont systemFontOfSize:10];
	self.time.textColor = [UIColor blueColor];
	self.time.backgroundColor = [UIColor clearColor];

	// read checkmark
	[self.checkView setFrame:
			CGRectMake(
				frame.size.width - 60, 
				20, 
				18, 
				10)];
	self.checkView.backgroundColor = [UIColor clearColor];

	// unread mark
	[self.unreadView setFrame:
			CGRectMake(
				frame.size.width - 60, 
				20, 
				30, 
				18)];
	self.unreadView.layer.cornerRadius = 9.0;
	self.unreadView.backgroundColor = [UIColor grayColor];

	self.unread.frame = 
		CGRectInset(self.unreadView.bounds, 3, 3);
	self.unread.font = [UIFont systemFontOfSize:9];
	self.unread.textColor = [UIColor whiteColor];
	self.unread.backgroundColor = [UIColor clearColor];
	self.unread.textAlignment = NSTextAlignmentCenter;
	[self.unreadView addSubview:self.unread];
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

	// dialog photo
	[self.imageView 
		setImageWithSize:CGSizeMake(50,50) 
					 placeholder:[UIImage imageNamed:@"missingAvatar.png"] 
						 cachePath:dialog.photoPath 
				 downloadBlock:dialog.photoDownloadBlock];
	self.imageView.layer.cornerRadius = 9.0;
  self.imageView.layer.masksToBounds = YES;
  self.imageView.layer.borderColor = [UIColor 
					colorWithWhite:0.0 alpha:0.2].CGColor;
  self.imageView.layer.borderWidth = 1.0;
        

	// dialog last message data
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

	// dialog delivered check and unread count
	NSNumber *userId = [NSUserDefaults.standardUserDefaults 
		valueForKey:@"userId"];

	//if (dialog.peerType == TG_PEER_TYPE_USER){
		//NSLog(@"TOP MSG FROM ID: %lld", dialog.topMessageFromId);
	//}

	if (dialog.peerType == TG_PEER_TYPE_USER &&
			dialog.peerId != userId.longLongValue &&
			(dialog.topMessageFromId == userId.longLongValue))
	{
		self.unreadView.hidden = YES;
		self.checkView.hidden = NO;
		if (dialog.readDate == -1){
			self.checkView.image = nil;
		}
		else if (dialog.readDate == 0){
			self.checkView.image = [UIImage 
				imageNamed:@"ModernConversationListIconDelivered.png"];
		} else {
			self.checkView.image = [UIImage 
				imageNamed:@"ModernConversationListIconRead.png"];
		}
	} else {
		self.checkView.hidden = YES;
		if (dialog.unread_count > 0) 
		{
			NSString *s = @"";
			if (dialog.unread_count / 1000 > 0){
				s = [NSString stringWithFormat:@"%dk", 
					dialog.unread_count/1000];
			} else {
				s = [NSString stringWithFormat:@"%d", 
					dialog.unread_count];
			}
			self.unread.text = s;
			self.unreadView.hidden = NO;
		} else {
			self.unreadView.hidden = YES;
		}
	}
}
@end
// vim:ft=objc
