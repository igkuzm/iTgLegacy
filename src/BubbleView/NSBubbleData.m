//
//  NSBubbleData.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "NSBubbleData.h"
#include "Foundation/Foundation.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSBubbleData

#pragma mark - Properties

@synthesize date = _date;
@synthesize type = _type;
@synthesize view = _view;
@synthesize insets = _insets;
@synthesize avatar = _avatar;

#pragma mark - Lifecycle

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_date release];
	_date = nil;
    [_view release];
    _view = nil;
    
    self.avatar = nil;

    [super dealloc];
}
#endif

#pragma mark - Text bubble

const UIEdgeInsets textInsetsMine = {1, 10, 11, 17};
const UIEdgeInsets textInsetsSomeone = {1, 15, 11, 10};

+ (id)dataWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
//#if !__has_feature(objc_arc)
	//return [[[NSBubbleData alloc] initWithText:text date:date type:type] autorelease];
//#else
	return [[NSBubbleData alloc] initWithText:text date:date type:type];
//#endif    
}

- (id)initWithText:(NSString *)text date:(NSDate *)date type:(NSBubbleType)type
{
	if (!self.width)
		self.width = 220;
	
	UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];

	if (text.length < 10)
		text = [NSString stringWithFormat:@"%@                    ", text];

	CGSize size = [(text ? text : @"") 
		sizeWithFont:font
    constrainedToSize:CGSizeMake(self.width, 9999) 
		lineBreakMode:NSLineBreakByWordWrapping];
 
	int addHeight = 0;
	if (self.name)
		addHeight = 20;

	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(
					0, 
					0, 
					size.width, 
					size.height + 20 + addHeight)];

	if (self.name){
		self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(
				8, 8, self.width, 20)];
		self.nameLabel.backgroundColor = [UIColor clearColor];
		self.nameLabel.text = self.name;
		if (self.nameColor){
			self.nameLabel.textColor = self.nameColor;
		} else {
			self.nameLabel.textColor = [UIColor lightGrayColor];
		}
		self.nameLabel.font = 
			[UIFont systemFontOfSize:[UIFont systemFontSize]-0.5];
		[view addSubview:self.nameLabel];
	}

    self.textView = [[UITextView alloc] 
			initWithFrame:CGRectMake(
					0, 
					self.name?20:0, 
					size.width, 
					size.height + 20)];

		self.textView.editable = NO;
		self.textView.dataDetectorTypes = UIDataDetectorTypeAll;
		self.textView.scrollEnabled = NO;
    self.textView.text = (text ? text : @"");
		self.textView.font = 
			[UIFont systemFontOfSize:[UIFont systemFontSize]-0.5];
		//self.textView.textContainer.lineBreakMode = NSLineBreakByWordWrapping;
    self.textView.backgroundColor = [UIColor clearColor];
		[view addSubview:self.textView];

//#if !__has_feature(objc_arc)
    //[label autorelease];
//#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? textInsetsMine : textInsetsSomeone);
    return [self initWithView:view date:date type:type insets:insets];
}

#pragma mark - Image bubble

const UIEdgeInsets imageInsetsMine = {11, 13, 16, 22};
const UIEdgeInsets imageInsetsSomeone = {11, 18, 16, 14};

+ (id)dataWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type text:(NSString *)text
{
//#if !__has_feature(objc_arc)
    //return [[[NSBubbleData alloc] initWithImage:image date:date type:type] autorelease];
//#else
	return [[NSBubbleData alloc] initWithImage:image date:date type:type text:text];
//#endif    
}

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type text:(NSString *)text
{
	if (!self.width)
		self.width = 220;
    
	CGSize size = image.size;
	if (size.width > self.width)
	{
			size.height /= (size.width / self.width);
			size.width = self.width;
	}
	
	self.imageView = [[UIImageView alloc] 
		initWithFrame:CGRectMake(
				0, 0,
			 	size.width, size.height)];
	self.imageView.image = image;
	self.imageView.layer.cornerRadius = 5.0;
	self.imageView.layer.masksToBounds = YES;
	self.isImage = YES;

	self.videoPlayButton = [[UIImageView alloc]
		initWithFrame:CGRectMake(
				size.width/2 - 20,
			 	size.height/2 - 20, 
				40, 40)];
	self.videoPlayButton.image = [UIImage imageNamed:@"Video-play-button"];
	self.videoPlayButton.hidden = YES;
	[self.imageView addSubview:self.videoPlayButton];
	
	self.spinner = 
				[[UIActivityIndicatorView alloc] 
				initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.spinner.center = 
		CGPointMake(
				self.imageView.bounds.size.width/2, 
				self.imageView.bounds.size.height/2);
	[self.imageView addSubview:self.spinner];

	UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
	CGSize textSize = [(text ? text : @"") 
		sizeWithFont:font 
		constrainedToSize:CGSizeMake(self.width, 9999) 
		lineBreakMode:NSLineBreakByWordWrapping];

	self.textView = [[UITextView alloc] 
		initWithFrame:CGRectMake(
				0, 
				size.height, 
				textSize.width + 10, 
				textSize.height + 15)];
	self.textView.editable = NO;
	self.textView.dataDetectorTypes = UIDataDetectorTypeAll;
	self.textView.scrollEnabled = NO;
	self.textView.text = (text ? text : @"");
	self.textView.font = 
		[UIFont systemFontOfSize:[UIFont systemFontSize]-0.5];
	self.textView.backgroundColor = [UIColor clearColor];

	CGFloat height = size.height;
	if (text)
		height += textSize.height;

	UIView *view = [[UIView alloc]
		initWithFrame:CGRectMake(
				0, 
				0, 
				self.width, 
				height)];
	[view addSubview:self.imageView];
	if (text)
		[view addSubview:self.textView];

	self.titleLabel = [[UILabel alloc] 
		initWithFrame:CGRectMake(
				size.width + 2,
			 	0, 
				self.width - size.width - 4, 20)];
  self.titleLabel.backgroundColor = [UIColor clearColor];
	self.titleLabel.font = [UIFont systemFontOfSize:10];
	[view addSubview:self.titleLabel];

	self.sizeLabel = [[UILabel alloc] 
		initWithFrame:CGRectMake(
				size.width + 2,
			 	22, 
				self.width - size.width - 4, 20)];
  self.sizeLabel.backgroundColor = [UIColor clearColor];
	self.sizeLabel.font = [UIFont systemFontOfSize:8];
	[view addSubview:self.sizeLabel];

//#if !__has_feature(objc_arc)
    //[imageView autorelease];
//#endif
    
    UIEdgeInsets insets = (type == BubbleTypeMine ? imageInsetsMine : imageInsetsSomeone);
    return [self initWithView:view date:date type:type insets:insets];       
}

#pragma mark - Custom view bubble

+ (id)dataWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets
{
//#if !__has_feature(objc_arc)
    //return [[[NSBubbleData alloc] initWithView:view date:date type:type insets:insets] autorelease];
//#else
		return [[NSBubbleData alloc] initWithView:view date:date type:type insets:insets];
//#endif    
}

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets  
{
    self = [super init];
    if (self)
    {
#if !__has_feature(objc_arc)
        _view = [view retain];
        _date = [date retain];
#else
        _view = view;
        _date = date;
#endif
        _type = type;
        _insets = insets;
				
				
    }
    return self;
}

@end
