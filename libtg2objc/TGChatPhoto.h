#import <Foundation/Foundation.h>
#import "../libtg2/libtg.h"

typedef NS_ENUM(NSUInteger, TGChatPhotoType) {
	kTGChatPhotoTypeChatPhotoEmpty,
	kTGChatPhotoTypeChatPhoto,
};

@interface TGChatPhoto : NSObject
{
}

@property TGChatPhotoType chatPhotoType;
@property Boolean has_video;
@property long long photo_id;
@property (strong) NSData *stripped_thumb;
@property int dc_id;

- (id)initWithTL:(const tl_t *)tl;
@end

// vim:ft=objc
