#import "TGObject.h"
#import "NSData+libtg2.h"
#import "NSString+libtg2.h"

@implementation TGObject

+ (NSString *)sringWithTLString:(string_t)string
{
	//NSLog(@"%s", __func__);
	NSString *nsstring;
	if (string.size){
		NSData *data = [NSData dataWithBytes:string.data 
																	length:string.size];
		nsstring = 
			[[NSString alloc] initWithData:data 
													 encoding:NSUTF8StringEncoding];
	
	} else 
		nsstring = [NSString string];

	return nsstring;
}

@end

// vim:ft=objc
