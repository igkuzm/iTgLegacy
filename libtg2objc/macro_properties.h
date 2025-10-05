#import "../libtg2/tl/macro.h"

#define TL_MACRO_arg_true(n) \
	@property (strong) NSNumber *n;
#define TL_MACRO_arg_int(n) \
	@property (strong) NSNumber *n;
#define TL_MACRO_arg_long(n) \
	@property (strong) NSNumber *n;
#define TL_MACRO_arg_double(n) \
	@property (strong) NSNumber *n;
#define TL_MACRO_arg_string(n) \
	@property (strong) NSString *n;
#define TL_MACRO_arg_bytes(n) \
	@property (strong) NSData *n;

#define TL_MACRO_arg_Peer(n) \
	@property (strong) TGPeer *n;
#define TL_MACRO_arg_Folder(n) \
	@property (strong) TGFolder *n;
#define TL_MACRO_arg_ChatPhoto(n) \
	@property (strong) TGChatPhoto *n;

#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
