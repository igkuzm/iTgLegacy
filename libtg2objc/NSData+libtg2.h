#import <Foundation/Foundation.h>
#import "../libtg2/libtg.h"

@interface NSData (libtg2)

+ (NSData *)dataFromPhotoStripped:(buf_t)bytes;
+ (NSData *)dataFromSvgPath:(buf_t)encoded;

@end


// vim:ft=objc
