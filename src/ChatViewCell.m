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
		self.text = [[UITextView alloc] init];
		self.text.editable = NO;
		self.text.dataDetectorTypes = UIDataDetectorTypeAll;
		self.text.scrollEnabled = NO;
    self.text.font = 
			[UIFont systemFontOfSize:[UIFont systemFontSize]];
    self.text.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:self.text];
    
		self.time = [[UILabel alloc] init];
		[self.contentView addSubview:self.time];
		
		self.avatarView = [[UIImageView alloc] init];
		[self.contentView addSubview:self.avatarView];
		
		self.photoView = [[UIImageView alloc] init];
		[self.contentView addSubview:self.photoView];

		self.photoHeight = 0;
		self.textHeight = 0;
	}
	return self;
}

- (void)setMessage:(TGMessage *)message {
	AppDelegate *delegate = 
		[[UIApplication sharedApplication]delegate]; 

	self.message = message;

	if (!message.mine){
	 self.avatarView.image = 
		 [UIImage imageWithImage:[UIImage imageNamed:@"avatar@2x.png"] 
			scaledToSize:CGSizeMake(40, 40)];
	}

	UIImage *photo = [self imageForMessage:message];
	if (photo){
		self.photoView.image = [UIImage imageWithImage:photo 
			scaledToSize:CGSizeMake(220, 165)];

		self.photoHeight = 165;
	}

	NSMutableString *text = [NSMutableString string];
	// add sender name
	// todo
	// add message
	[text appendString:message.message];
	
	CGSize size = [text 
		sizeWithFont:[UIFont systemFontOfSize:[UIFont systemFontSize]]
		constrainedToSize:CGSizeMake(220, 9999) 
		lineBreakMode:NSLineBreakByWordWrapping];
	self.textHeight = size.height;
    
	self.text.text = text;
	
	NSDateComponents *now  = [self dateCompFromDate:[NSDate date]];
	NSDateComponents *then = [self dateCompFromDate:message.date];
	if (now.year == then.year && 
			now.month == then.month &&
			now.day == then.day)
	{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"HH:mm";
		self.time.text = [dateFormatter stringFromDate:message.date];
	} else {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		dateFormatter.dateFormat = @"dd.MM.yyyy";
		self.time.text = [dateFormatter stringFromDate:message.date];
	}
}

-(UIImage *)imageForMessage:(TGMessage *)message {

	if (!message.photoId || message.docId)
		return nil;

	if (message.photo)
		return message.photo;

	switch (message.mediaType) {
		case id_messageMediaContact:
			return [UIImage imageNamed:@"avatar@2x.png"];
		
		case id_messageMediaDocument:
			{
				if (message.isVoice)
					return [UIImage imageNamed:@"filetype_icon_audio@2x.png"];
				else if (message.isVideo)
					return [UIImage imageNamed:@"filetype_icon_video@2x.png"];

				// todo handle MIME TYPES
				// d.message.mimeType
			}
		case id_messageMediaGeo:
			{
				return [UIImage imageNamed:@"filetype_icon_unknown@2x.png"];
			}
	
		default:
				return [UIImage imageNamed:@"filetype_icon_unknown@2x.png"];
	}
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
