#import "TGObject.h"
#import "TGMessage.h"

@interface TGMessageEmpty : TGMessage
{
}

#define TL_MACRO_EXE TL_MACRO_messageEmpty
#include "macro_properties.h"

+ (NSEntityDescription *)
	entityWitgTGPeer:(NSEntityDescription *)tgpeer;
@end

// vim:ft=objc
