#import "TGObject.h"
#import "TGChatPhoto.h"

@interface TGFolder : TGObject
{
}

#define TL_MACRO_EXE TL_MACRO_folder
#include "macro_properties.h"

+ (NSEntityDescription *)entityWithTGphoto:(NSEntityDescription *)tgphoto;
@end

// vim:ft=objc
