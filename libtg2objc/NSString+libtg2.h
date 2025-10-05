#import <Foundation/Foundation.h>
#import "../libtg2/libtg.h"

@interface NSString (libtg2)

+ (NSString *)stringWithTLString:(string_t)string;

@end


// vim:ft=objc
