#import "TGObject.h"
#import "TGMessage.h"

@interface TGMessageService : TGMessage
{
}

#define TL_MACRO_EXE TL_MACRO_messageService
#include "macro_properties.h"

// @property (strong) TGMessageAction *action;

+ (NSEntityDescription *)
	entityWitgTGPeer:(NSEntityDescription *)tgpeer;
@end

// vim:ft=objc
