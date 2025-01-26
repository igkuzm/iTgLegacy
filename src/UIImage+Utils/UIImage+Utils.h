/**
 * File              : UIImage+Utils.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 26.01.2025
 * Last Modified Date: 26.01.2025
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
/**
 * UIImage+Utils/UIImage+Utils.h
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
#import <UIKit/UIKit.h>

@interface UIImage (Utils)
+ (UIImage *)imageWithImage:(UIImage *)image 
							 scaledToSize:(CGSize)newSize;

+ (UIImage *)imageWithSize:(CGSize)size
	             placeholder:(UIImage *)placeholder 
				         cachePath:(NSString *)cachePath 
											view:(UIView *)view
			       downloadBlock:(NSData * (^)())downloadBlock
								  onUpdate:(void(^)(UIImage *image))onUpdate;
@end

@interface UIImageView (Utils)
- (void)setImageWithSize:(CGSize)size 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
			     downloadBlock:(NSData * (^)())downloadBlock;
@end

@interface UIButton (Utils)
- (void)setImageWithSize:(CGSize)size 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
								forState:(UIControlState)state
			     downloadBlock:(NSData * (^)())downloadBlock;
@end


// vim:ft=objc
