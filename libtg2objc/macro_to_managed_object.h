#import "../libtg2/tl/macro.h"
#define TL_MACRO_arg_true(n) \
	[mo setValue:[NSNumber numberWithBool:self.n] forKey:@"n"];
#define TL_MACRO_arg_int(n) \
	[mo setValue:[NSNumber numberWithInt:self.n] forKey:@"n"];
#define TL_MACRO_arg_long(n) \
	[mo setValue:[NSNumber numberWithLongLong:self.n] forKey:@"n"];
#define TL_MACRO_arg_double(n) \
	[mo setValue:[NSNumber numberWithDouble:self.n] forKey:@"n"];
#define TL_MACRO_arg_string(n) \
	[mo setValue:self.n forKey:@"n"];
#define TL_MACRO_arg_bytes(n) \
	[mo setValue:self.n forKey:@"n"];

#define TL_MACRO_arg_Peer(n) \
if (self.n){ \
	[mo setValue:self.n.managedObject forKey:@"n"]; \
}

#define TL_MACRO_arg_Folder(n) \
if (self.n){ \
	[mo setValue:self.n.managedObject forKey:@"n"]; \
}

#define TL_MACRO_arg_ChatPhoto(n) \
if (self.n){ \
	[mo setValue:self.n.managedObject forKey:@"n"]; \
}

#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
