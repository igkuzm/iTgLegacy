#import "NSData+libtg2.h"
#import "../libtg2/tg/images.h"

@implementation NSData (libtg2)

+ (NSData *)dataFromPhotoStripped:(buf_t)bytes
{
	NSLog(@"%s: %s", __FILE__, __func__);
	NSData *data;
	buf_t buf = image_from_photo_stripped(bytes);
	
	if (buf.size){
		data = [NSData dataWithBytes:buf.data length:buf.size];
		buf_free(buf);
	} else 
		data = [NSData data];
}

@end
// vim:ft=objc
