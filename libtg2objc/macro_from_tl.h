#import "../libtg2/tl/macro.h"

#define TL_MACRO_id(n) \
	self.objectType = n;
#define TL_MACRO_arg_int(n) \
	self.n = tl->n;
#define TL_MACRO_arg_string(n) \
	self.n = [NSString stringWithTLString:tl->n];
#define TL_MACRO_arg_long(n) \
	self.n = tl->n;
#define TL_MACRO_arg_true(n) \
	self.n = tl->n;
#define TL_MACRO_arg_double(n) \
	self.n = tl->n;

#define TL_MACRO_arg_Peer(n) \
	self.n = [TGPeer newWithTL:tl->n];
#define TL_MACRO_arg_Folder(n) \
	self.n = [TGFolder newWithTL:tl->n];
#define TL_MACRO_arg_ChatPhoto(n) \
	self.n = [TGChatPhoto newWithTL:tl->n];
#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
