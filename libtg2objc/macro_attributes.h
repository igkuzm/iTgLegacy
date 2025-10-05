#import "../libtg2/tl/macro.h"
#define TL_MACRO_id(n) \
	[Attribute name:@"tl_id" type:NSInteger32AttributeType],
#define TL_MACRO_arg_true(n) \
	[Attribute name:@#n type:NSBooleanAttributeType],
#define TL_MACRO_arg_int(n) \
	[Attribute name:@#n type:NSInteger32AttributeType],
#define TL_MACRO_arg_long(n) \
	[Attribute name:@#n type:NSInteger64AttributeType],
#define TL_MACRO_arg_double(n) \
	[Attribute name:@#n type:NSDoubleAttributeType],
#define TL_MACRO_arg_string(n) \
	[Attribute name:@#n type:NSStringAttributeType],
#define TL_MACRO_arg_bytes(n) \
	[Attribute name:@#n type:NSBinaryDataAttributeType],

#include "../libtg2/tl/macro_exe.h"

// vim:ft=objc
