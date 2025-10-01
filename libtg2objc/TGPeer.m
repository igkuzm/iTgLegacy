#import "TGPeer.h"
@implementation TGPeer
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		if (tl->_id == id_peerUser){
			self.peerType = kTGPeerTypeUser;
			self.id = ((tl_peerUser_t *)tl)->user_id_;
			return self;
		}
		if (tl->_id == id_peerChat){
			self.peerType = kTGPeerTypeChat;
			self.id = ((tl_peerChat_t *)tl)->chat_id_;
			return self;
		}
		if (tl->_id == id_peerChannel){
			self.peerType = kTGPeerTypeChannel;
			self.id = ((tl_peerChannel_t *)tl)->channel_id_;
			return self;
		}
	}
	return self;
}
@end
// vim:ft=objc
