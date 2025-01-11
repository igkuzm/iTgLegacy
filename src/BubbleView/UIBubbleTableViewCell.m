//
//  UIBubbleTableViewCell.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
#import <QuartzCore/QuartzCore.h>
#import "UIBubbleTableViewCell.h"
#import "NSBubbleData.h"

@interface UIBubbleTableViewCell ()

@property (nonatomic, retain) UIView *customView;
@property (nonatomic, retain) UIImageView *bubbleImage;
@property (nonatomic, retain) UIImageView *avatarImage;
@property (nonatomic, retain) UIView *dateView;
@property (nonatomic, retain) UIImageView *checkView;

- (void) setupInternalData;

@end

@implementation UIBubbleTableViewCell

@synthesize data = _data;
@synthesize customView = _customView;
@synthesize bubbleImage = _bubbleImage;
@synthesize showAvatar = _showAvatar;
@synthesize avatarImage = _avatarImage;

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
	[self setupInternalData];
}

#if !__has_feature(objc_arc)
- (void) dealloc
{
    self.data = nil;
    self.customView = nil;
    self.bubbleImage = nil;
    self.avatarImage = nil;
    [super dealloc];
}
#endif

- (void)setDataInternal:(NSBubbleData *)value
{
	self.data = value;
	[self setupInternalData];
}

- (void) setupInternalData
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (!self.bubbleImage)
    {
#if !__has_feature(objc_arc)
        self.bubbleImage = [[[UIImageView alloc] init] autorelease];
#else
        self.bubbleImage = [[UIImageView alloc] init];        
#endif
        [self addSubview:self.bubbleImage];
    }
    
    NSBubbleType type = self.data.type;
    
    CGFloat width = self.data.view.frame.size.width;
    CGFloat height = self.data.view.frame.size.height;

    CGFloat x = (type == BubbleTypeSomeoneElse) ? 0 : self.frame.size.width - width - self.data.insets.left - self.data.insets.right;
    CGFloat y = 0;
    
    // Adjusting the x coordinate for avatar
    if (self.showAvatar)
    {
        [self.avatarImage removeFromSuperview];
#if !__has_feature(objc_arc)
        self.avatarImage = [[[UIImageView alloc] initWithImage:(self.data.avatar ? self.data.avatar : [UIImage imageNamed:@"missingAvatar.png"])] autorelease];
#else
        self.avatarImage = [[UIImageView alloc] initWithImage:(self.data.avatar ? self.data.avatar : [UIImage imageNamed:@"missingAvatar.png"])];
#endif
        self.avatarImage.layer.cornerRadius = 9.0;
        self.avatarImage.layer.masksToBounds = YES;
        self.avatarImage.layer.borderColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
        self.avatarImage.layer.borderWidth = 1.0;
        
        CGFloat avatarX = (type == BubbleTypeSomeoneElse) ? 2 : self.frame.size.width - 52;
        CGFloat avatarY = self.frame.size.height - 50;
        
        self.avatarImage.frame = CGRectMake(avatarX, avatarY, 50, 50);
        [self addSubview:self.avatarImage];
        
        CGFloat delta = self.frame.size.height - (self.data.insets.top + self.data.insets.bottom + self.data.view.frame.size.height);
        if (delta > 0) y = delta;
        
        if (type == BubbleTypeSomeoneElse) x += 54;
        if (type == BubbleTypeMine) x -= 54;
    }

    [self.customView removeFromSuperview];
    self.customView = self.data.view;
    self.customView.frame = CGRectMake(
				x + self.data.insets.left, 
				y + self.data.insets.top, 
				width, height);
    [self.contentView addSubview:self.customView];
    
    
    if (type == BubbleTypeSomeoneElse)
    {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleSomeone.png"] stretchableImageWithLeftCapWidth:21 topCapHeight:14];

    }
    else {
        self.bubbleImage.image = [[UIImage imageNamed:@"bubbleMine.png"] stretchableImageWithLeftCapWidth:15 topCapHeight:14];
    }

    self.bubbleImage.frame = 
			CGRectMake(
					x, y, 
					width + self.data.insets.left + self.data.insets.right, 
					height + self.data.insets.top + self.data.insets.bottom);

		TGMessage *message = self.data.message;
		//if (message.mine){
			//self.dateView = [[[UIImageView alloc]init]autorelease];
			//self.dateView.frame = CGRectMake(
					//self.bubbleImage.frame.origin.x - 62, 
					//self.bubbleImage.frame.origin.y + 
						//self.bubbleImage.frame.size.height - 40, 
					//200, 20);
			//self.dateView.backgroundColor = [UIColor whiteColor];

			//CAShapeLayer * shapeLayer = [CAShapeLayer layer];
			//UIBezierPath * bezierPath = [UIBezierPath bezierPath];
			//[bezierPath moveToPoint:CGPointMake(0, 0)];
			//[bezierPath addLineToPoint:CGPointMake(0,20)];
			//[bezierPath addLineToPoint:CGPointMake(170,20)];
			//[bezierPath addLineToPoint:CGPointMake(180,90)];
			//[bezierPath addLineToPoint:CGPointMake(190, 20)];
			//[bezierPath addLineToPoint:CGPointMake(200,20)];
			//[bezierPath addLineToPoint:CGPointMake(200, 0)];
			//[bezierPath closePath];
			//shapeLayer.path = bezierPath.CGPath;

			//self.dateView.layer.mask = shapeLayer;

			//// add subview
			//[self.contentView addSubview:self.dateView];
		//}
		//if (message.mine){
			//self.checkView = [[[UIImageView alloc]init]autorelease];
			//self.checkView.frame = CGRectMake(
					//self.bubbleImage.frame.origin.x - 20, 
					//self.bubbleImage.frame.origin.y + 
						//self.bubbleImage.frame.size.height - 20, 
					//18, 10);

			//self.checkView.image = [UIImage 
				//imageNamed:@"ModernConversationListIconRead.png"];
			
			//// add subview
			//[self.contentView addSubview:self.checkView];
		//}
}

@end
