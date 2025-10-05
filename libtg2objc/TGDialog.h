#import "TGObject.h"
#import "TGPeer.h"
#import "TGFolder.h"

@interface TGDialog : TGObject
{
}

#define TL_MACRO_EXE TL_MACRO_dialog
#include "macro_properties.h"

//@property (strong) TGPeerNotifySettings *notify_settings;
//@property (strong) TGDraftMessage *draft;

+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer;
@end

// vim:ft=objc
