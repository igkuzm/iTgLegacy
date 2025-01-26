/**
 * File              : UIImage+Utils.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 26.01.2025
 * Last Modified Date: 26.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
/**
 * UIImage+Utils/UIImage+Utils.m
 * Copyright (c) 2025 Igor V. Sementsov <ig.kuzm@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
#import "UIImage+Utils.h"
#include "UIKit/UIKit.h"

@implementation UIImage (Utils)

+ (UIImage *)imageWithImage:(UIImage *)image 
							 scaledToSize:(CGSize)newSize 
{
    UIGraphicsBeginImageContextWithOptions(
				newSize, NO, 0.0);
    
		[image drawInRect:CGRectMake(
				0, 0, 
				newSize.width, 
				newSize.height)];
    
		UIImage *newImage = 
			UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
		return newImage;
}

+ (UIImage *)imageWithPlaceholder:(UIImage *)placeholder 
				                cachePath:(NSString *)cachePath 
											       view:(UIView *)view
			              downloadBlock:(NSData * (^)())downloadBlock
								         onUpdate:(void(^)(UIImage *image))onUpdate
{
	__block UIActivityIndicatorView *spinner = 
		[[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[view addSubview:spinner];
	spinner.center = CGPointMake(
		placeholder.size.width/2, 
		placeholder.size.height/2);
	[spinner startAnimating];

	NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];

	UIImage *image = placeholder;

	if ([NSFileManager.defaultManager fileExistsAtPath:cachePath]){
		// load from cache
		NSData *data = [NSData dataWithContentsOfFile:cachePath];
		image = [UIImage imageWithData:data]; 
		[spinner stopAnimating];
		[spinner removeFromSuperview];
	} else {
		[operationQueue addOperationWithBlock:^{
			NSData * data = downloadBlock();
			if (data != nil){
				UIImage *image = [UIImage imageWithData:data];
				if (image != nil){
					[data writeToFile:cachePath atomically:YES];
					dispatch_sync(dispatch_get_main_queue(), ^{
						onUpdate(image);
					});
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				[spinner stopAnimating];
				[spinner removeFromSuperview];
			});
		}];
	}
	return image;
}

+ (UIImage *)imageWithSize:(CGSize)size
	             placeholder:(UIImage *)placeholder 
				         cachePath:(NSString *)cachePath 
											view:(UIView *)view
			       downloadBlock:(NSData * (^)())downloadBlock
								  onUpdate:(void(^)(UIImage *image))onUpdate;
{
	__block UIActivityIndicatorView *spinner = 
		[[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[view addSubview:spinner];
	spinner.center = CGPointMake(
		size.width/2, 
		size.height/2);
	[spinner startAnimating];

	NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];

	UIImage *image = [UIImage imageWithImage:placeholder 
												scaledToSize:size]; 
	if ([NSFileManager.defaultManager fileExistsAtPath:cachePath]){
		// load from cache
		NSData *data = [NSData dataWithContentsOfFile:cachePath];
		image = [UIImage imageWithImage:[UIImage imageWithData:data] 
													scaledToSize:size]; 
		[spinner stopAnimating];
		[spinner removeFromSuperview];
	} else {
		[operationQueue addOperationWithBlock:^{
			NSData * data = downloadBlock();
			if (data != nil){
				UIImage *image = [UIImage imageWithData:data];
				if (image != nil){
					[data writeToFile:cachePath atomically:YES];
					dispatch_sync(dispatch_get_main_queue(), ^{
						UIImage *image = [UIImage imageWithImage:image 
												          scaledToSize:size]; 
						onUpdate(image);
					});
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				[spinner stopAnimating];
				[spinner removeFromSuperview];
			});
		}];
	}
	return image;
}
@end

@implementation UIImageView (Utils)
- (void)setImageWithSize:(CGSize)size 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
			     downloadBlock:(NSData * (^)())downloadBlock
{
	self.image = [UIImage 
		imageWithSize:size 
		placeholder:placeholder 
		cachePath:cachePath 
		view:self 
		downloadBlock:downloadBlock 
		onUpdate:^(UIImage *image){
			self.image = image; 
		}];
}

- (void)setImageWithPlaceholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
			     downloadBlock:(NSData * (^)())downloadBlock
{
	self.image = [UIImage 
		imageWithPlaceholder:placeholder 
		cachePath:cachePath 
		view:self 
		downloadBlock:downloadBlock 
		onUpdate:^(UIImage *image){
			self.image = image; 
		}];
}
@end

@implementation UIButton (Utils)
- (void)setImageWithSize:(CGSize)size 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
								forState:(UIControlState)state
			     downloadBlock:(NSData * (^)())downloadBlock
{
	[self setImage:[UIImage 
	 imageWithSize:size 
	 placeholder:placeholder
	 cachePath:cachePath 
	 view:self 
   downloadBlock:downloadBlock 
	 onUpdate:^(UIImage *image){
		[self setImage:image forState:state];
	 }] 
	 forState:state];
}
@end
// vim:ft=objc
