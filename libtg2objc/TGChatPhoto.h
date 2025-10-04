#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"

typedef NS_ENUM(NSUInteger, TGChatPhotoType) {
	kTGChatPhotoTypeChatPhotoEmpty,
	kTGChatPhotoTypeChatPhoto,
};

@interface TGChatPhoto : NSManagedObject
{
}

@property TGChatPhotoType chatPhotoType;
@property Boolean has_video;
@property long long photo_id;
@property (strong) NSData *stripped_thumb;
@property int dc_id;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGChatPhoto *)newWithTL:(const tl_t *)tl;
+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
