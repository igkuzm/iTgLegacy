#import "../libtg2/tl/macro.h"
#define TL_MACRO_arg_true(n) \
	obj.n = [[mo valueForKey:@"n"]boolValue];
#define TL_MACRO_arg_int(n) \
	obj.n = [[mo valueForKey:@"n"]intValue];
#define TL_MACRO_arg_long(n) \
	obj.n = [[mo valueForKey:@"n"]longLongValue];
#define TL_MACRO_arg_double(n) \
	obj.n = [[mo valueForKey:@"n"]doubleValue];
#define TL_MACRO_arg_string(n) \
	obj.n = [mo valueForKey:@"n"];
#define TL_MACRO_arg_bytes(n) \
	obj.n = [mo valueForKey:@"n"];

#define TL_MACRO_arg_Peer(n) \
	obj.n = [TGPeer newWithManagedObject:[mo valueForKey:@"n"]];
#define TL_MACRO_arg_Folder(n) \
	obj.n = [TGFolder newWithManagedObject:[mo valueForKey:@"n"]];
#define TL_MACRO_arg_ChatPhoto(n) \
	obj.n = [TGChatPhoto newWithManagedObject:[mo valueForKey:@"n"]];

#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
