#import "TGChatPhoto.h"
#import "NSData+libtg2.h"

@implementation TGChatPhoto
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		self.chatPhotoType = kTGChatPhotoTypeChatPhotoEmpty;

		if (tl->_id == id_chatPhoto){
			tl_chatPhoto_t *p = (tl_chatPhoto_t *)tl;
			self.chatPhotoType = kTGChatPhotoTypeChatPhoto;
			self.has_video = p->has_video_;
			self.photo_id = p->photo_id_;
			self.stripped_thumb = [NSData dataFromPhotoStripped:p->stripped_thumb_];
			self.dc_id = p->dc_id_;
		}
	}
	return self;
}
@end
// vim:ft=objc
