#import "NSString+libtg2.h"

@implementation NSString (libtg2)

+ (NSString *)sringWithTLString:(string_t)string
{
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
