#import "../libtg2/tl/macro.h"

#define TL_MACRO_id(n) \
	self.tl_id = [NSNumber numberWithInt:n];
#define TL_MACRO_arg_true(n) \
	if (tl) \
		self.n = [NSNumber numberWithBool:tl->n];
#define TL_MACRO_arg_int(n) \
	if (tl) \
		self.n = [NSNumber numberWithInt:tl->n];
#define TL_MACRO_arg_long(n) \
	if (tl) \
		self.n = [NSNumber numberWithLongLong:tl->n];
#define TL_MACRO_arg_double(n) \
	if (tl) \
		self.n = [NSNumber numberWithDouble:tl->n];
#define TL_MACRO_arg_string(n) \
	if (tl) \
		self.n = [NSString stringWithTLString:tl->n];

#define TL_MACRO_arg_Peer(n) \
	if (tl) { \
		if (self.n == nil || tl->n == NULL){ \
			self.n = [TGPeer newWithTL:tl->n context:context]; \
		} \
		else if (tl->n){ \
			if (tl->n->_id != self.n.tl_id) \
				self.n = [TGPeer newWithTL:tl->n context:context]; \
			else { \
				if (tl->n->_id == id_peerUser || tl->n->_id == id_peerChat || tl->n->_id == id_peerChannel) { \
					tl_peerChat_t *_o = (tl_peerChat_t *)tl->n; \
					if (_o->chat_id_ != self.n.id) \
						self.n = [TGPeer newWithTL:tl->n context:context]; \
				} \
			} \
		} \
	} \

#define TL_MACRO_arg_Folder(n) \
	if (tl) { \
		if (self.n == nil || tl->n == NULL){ \
			self.n = [TGFolder newWithTL:tl->n context:context]; \
		} \
		else if (tl->n){ \
			if (tl->n->_id != self.n.tl_id) \
				self.n = [TGFolder newWithTL:tl->n context:context]; \
			else { \
				if (tl->n->_id == id_folder) { \
					tl_folder_t *_o = (tl_folder_t *)tl->n; \
					if (_o->id_ != self.n.id_) \
						self.n = [TGFolder newWithTL:tl->n context:context]; \
				} \
			} \
		} \
	} \

#define TL_MACRO_arg_ChatPhoto(n) \
	if (tl) { \
		if (self.n == nil || tl->n == NULL){ \
			self.n = [TGChatPhoto newWithTL:tl->n context:context]; \
		} \
		else if (tl->n){ \
			if (tl->n->_id != self.n.tl_id) \
				self.n = [TGChatPhoto newWithTL:tl->n context:context]; \
			else { \
				if (tl->n->_id == id_chatPhoto) { \
					tl_chatPhoto_t *_o = (tl_chatPhoto_t *)tl->n; \
					if (_o->dc_id_ != self.n.dc_id_ || _o->photo_id_ != self.n.photo_id_) \
						self.n = [TGChatPhoto newWithTL:tl->n context:context]; \
				} \
			} \
		} \
	} \

#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
