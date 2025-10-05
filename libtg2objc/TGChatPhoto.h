#import "TGObject.h"

@interface TGChatPhoto : TGObject
{
}

#define TL_MACRO_EXE TL_MACRO_chatPhoto
#include "macro_properties.h"

+ (NSEntityDescription *)entity;

@end

// vim:ft=objc
