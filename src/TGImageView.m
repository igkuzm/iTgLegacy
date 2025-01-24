#import "TGImageView.h"
#include "UIKit/UIKit.h"
#include "CoreGraphics/CoreGraphics.h"
#include "Foundation/Foundation.h"
#import "UIImage+Utils/UIImage+Utils.h"

@implementation UIImageView (Utils)

- (void)setImageWithSize:(CGSize)size 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
			     downloadBlock:(NSData * (^)())downloadBlock
{
	__block UIActivityIndicatorView *spinner = 
		[[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self addSubview:spinner];
	spinner.center = CGPointMake(
		size.width/2, 
		size.height/2);
	[spinner startAnimating];

	NSOperationQueue *operationQueue = [[NSOperationQueue alloc]init];

	self.image = [UIImage imageWithImage:placeholder 
												scaledToSize:size]; 
	if ([NSFileManager.defaultManager fileExistsAtPath:cachePath]){
		// load from cache
		NSData *data = [NSData dataWithContentsOfFile:cachePath];
		self.image = [UIImage imageWithImage:[UIImage imageWithData:data] 
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
						self.image = [UIImage imageWithImage:image 
												          scaledToSize:size]; 
					});
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				[spinner stopAnimating];
				[spinner removeFromSuperview];
			});
		}];
	}
}
@end
// vim:ft=objc
