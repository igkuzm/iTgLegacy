#import "TGObject.h"
#import "TGPeer.h"

@interface TGMessage : TGObject
{
}

#define TL_MACRO_EXE TL_MACRO_message
#include "macro_properties.h"

//@property TGMessageFwdHeader fwd_from;
//@property TGMessageReplyHeader reply_to;
//@property TGMessageMedia media;
//@property TGReplyMarkup reply_markup;
//@property (strong) NSArray *entities; //TGMessageEntity
//@property TGMessageReplies replies;
//@property TGMessageReactions reactions;
//@property (strong) NSArray *restriction_reason; //TGRestrictionReason
//@property TGFactCheck factcheck;

+ (NSEntityDescription *)
	entityWitgTGPeer:(NSEntityDescription *)tgpeer;
@end

// vim:ft=objc
