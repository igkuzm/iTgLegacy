#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "../libtg2/tl/macro.h"


@interface TGChatPhoto : NSManagedObject
{
}

@property int chatPhotoType;
#define TL_MACRO_chatPhoto_arg_true(name) \
	@property Boolean name;
#define TL_MACRO_chatPhoto_arg_long(name) \
	@property long long mane;
#define TL_MACRO_chatPhoto_arg_bytes(name) \
	@property (strong) NSData *name;
#define TL_MACRO_chatPhoto_arg_int(name) \
	@property int name;

TL_MACRO_chatPhoto

#undef TL_MACRO_chatPhoto_arg_true
#undef TL_MACRO_chatPhoto_arg_long
#undef TL_MACRO_chatPhoto_arg_bytes
#undef TL_MACRO_chatPhoto_arg_int
	
- (void)updateWithTL:(const tl_t *)tl;
+ (TGChatPhoto *)newWithTL:(const tl_t *)tl;
+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
