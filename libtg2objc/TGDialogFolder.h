#import "TGDialog.h"

@interface TGDialogFolder : TGDialog
{
}

#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_properties.h"

+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer
	TGFolder:(NSEntityDescription *)tgfolder;

@end

// vim:ft=objc
