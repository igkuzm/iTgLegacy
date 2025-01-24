/* UIImageView with cache, placeholder, download manager
 * and spinner */
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>

@interface UIImageView (Utils)
- (void)setImageWithSize:(CGSize)imageSize 
	           placeholder:(UIImage *)placeholder 
				       cachePath:(NSString *)cachePath 
			     downloadBlock:(NSData * (^)())downloadBlock;
@end
// vim:ft=objc
