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

- (id)initWithImage:(UIImage *)image 
							 date:(NSDate *)date 
							 type:(NSBubbleType)type 
							 text:(NSString *)text
{
	self.textInsetsMine = UIEdgeInsetsMake(
			1, 10, 11, 17);
	self.textInsetsSomeone = UIEdgeInsetsMake(
			1, 15, 11, 10);

	if (!self.width)
		self.width = 220;
	
	UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    
	// username Label
	CGSize nameSize = {0,0};
	if (self.name){
		nameSize = [self.name 
			sizeWithFont:font 
			constrainedToSize:CGSizeMake(self.width, 9999) 
			lineBreakMode:NSLineBreakByWordWrapping];

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
			[UIFont systemFontOfSize:[UIFont systemFontSize]];
	}

	// imageView
	CGSize imageSize = {0,0};
	if (image){
		imageSize	= image.size;
		if (imageSize.width > self.width)
		{
				imageSize.height /= (imageSize.width / self.width);
				imageSize.width = self.width;
		}
	}

	self.imageView = [[UIImageView alloc] 
		initWithFrame:CGRectMake(
      	0, self.name?28:8,
			 	imageSize.width, imageSize.height)];
	self.imageView.image = image;
	self.imageView.layer.cornerRadius = 5.0;
	self.imageView.layer.masksToBounds = YES;
	self.isImage = YES;

	UITapGestureRecognizer *tapOnImage = [[UITapGestureRecognizer alloc] 
		initWithTarget:self action:@selector(onImageTap:)];
	tapOnImage.numberOfTapsRequired = 1;
	[self.imageView addGestureRecognizer:tapOnImage];
	self.imageView.userInteractionEnabled = YES;

	self.videoPlayButton = [[UIImageView alloc]
		initWithFrame:CGRectMake(
				imageSize.width/2 - 20,
			 	imageSize.height/2 - 20, 
				40, 40)];
	self.videoPlayButton.image = [UIImage imageNamed:@"Video-play-button"];
	self.videoPlayButton.hidden = !self.showPlayButton;
	[self.imageView addSubview:self.videoPlayButton];
	
	self.spinner = [[UIActivityIndicatorView alloc] 
	initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	self.spinner.center = 
		CGPointMake(
				self.imageView.bounds.size.width/2, 
				self.imageView.bounds.size.height/2);
	[self.imageView addSubview:self.spinner];


	// text view
	//if (text.length < 2 && !image){
		//font = [UIFont systemFontOfSize:125];
	//}

	CGSize textSize = [text 
		sizeWithFont:font 
		constrainedToSize:CGSizeMake(self.width, 9999) 
		lineBreakMode:NSLineBreakByWordWrapping];

	self.text = [[UILabel alloc] 
		initWithFrame:CGRectMake(
				0, 
				self.name?imageSize.height + 28 + 4:imageSize.height +8 + 4, 
				textSize.width, 
				textSize.height)];
	self.text.text = text;
	self.text.font = font; 
	self.text.backgroundColor = [UIColor clearColor];
	self.text.numberOfLines = 0;
	self.text.lineBreakMode = NSLineBreakByWordWrapping;
	
	UITapGestureRecognizer *tapOnText = [[UITapGestureRecognizer alloc] 
		initWithTarget:self action:@selector(onTextTap:)];
	tapOnText.numberOfTapsRequired = 1;
	[self.text addGestureRecognizer:tapOnText];
	self.text.userInteractionEnabled = YES;

	// view
	CGFloat viewH = imageSize.height + 8;
	if (text)
		viewH += textSize.height + 8 + 4;
	if (self.name)
		viewH += 28;

	CGFloat viewW = self.width;
	if (textSize.width < self.width)
		viewW = textSize.width;
	if (imageSize.width > viewW)
		viewW = imageSize.width;
	if (nameSize.width + 2> viewW)
		viewW = nameSize.width;
	if (image && viewW < 180)
		viewW = 180;
		
	UIView *view = [[UIView alloc]
		initWithFrame:CGRectMake(
				0, 
				0, 
				viewW, 
				viewH)];
	
	// add subviews
	if (self.name)
		[view addSubview:self.nameLabel];
	if (image)	
		[view addSubview:self.imageView];
	
	if (text)
		[view addSubview:self.text];

	// titleLabel
	self.titleLabel = [[UILabel alloc]init]; 
	self.titleLabel.frame = CGRectMake(
				imageSize.width + 6,
			 	8, 
				viewW - imageSize.width - 4, 20);
  self.titleLabel.backgroundColor = [UIColor clearColor];
	self.titleLabel.font = [UIFont systemFontOfSize:10];
	[view addSubview:self.titleLabel];

	// sizeLabel
	self.sizeLabel = [[UILabel alloc] 
		initWithFrame:CGRectMake(
				imageSize.width + 6,
			 	22, 
				viewW - imageSize.width - 4, 20)];
  self.sizeLabel.backgroundColor = [UIColor clearColor];
	self.sizeLabel.font = [UIFont systemFontOfSize:8];
	[view addSubview:self.sizeLabel];

  UIEdgeInsets insets = (type == BubbleTypeMine ? 
			self.textInsetsMine : self.textInsetsSomeone);
    return [self initWithView:view 
												 date:date type:type insets:insets];       
}


//- (id)initWithServiceMessage:(NSString *)text date:(NSDate *)date
//{
	//if (!self.width)
		//self.width = 220;
	
	//UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]-2];
   
	//CGSize textSize = [text 
		//sizeWithFont:font 
		//constrainedToSize:CGSizeMake(self.width, 9999) 
		//lineBreakMode:NSLineBreakByWordWrapping];

	//self.text = [[UILabel alloc] 
		//initWithFrame:CGRectMake(
				//self.width/2 - textSize.width/2, 
				//0, 
				//textSize.width, 
				//textSize.height)];
	
	//self.text.text = text;
	//self.text.font = font; 
	//self.text.textColor = [UIColor lightGrayColor];
	//self.text.backgroundColor = [UIColor clearColor];
	//self.text.numberOfLines = 0;
	//self.text.lineBreakMode = NSLineBreakByWordWrapping;

	//UIView *view = [[UIView alloc]
		//initWithFrame:CGRectMake(
				//0, 
				//0, 
				//self.width, 
				//textSize.height)];
	//[view addSubview:self.text];
	
  //UIEdgeInsets insets = {0,0,0,0}; 
  //return [self initWithView:view 
						//date:date type:BubbleTypeMine insets:insets];       
//}

#pragma mark - Custom view bubble

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets  
{
    self = [super init];
    if (self)
    {
			_view = view;
			_date = date;
			_type = type;
			_insets = insets;
    }
    return self;
}

#pragma mark - On tap
-(void)onTextTap:(id)sender{
	if (self.delegate)
		[self.delegate bubbleDataDidTapText:self];
}

-(void)onImageTap:(id)sender{
	if (self.delegate)
		[self.delegate bubbleDataDidTapImage:self];
}

@end
