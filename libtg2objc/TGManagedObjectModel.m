#import "TGManagedObjectModel.h"
#import "TGPeer.h"
#import "TGMessage.h"
#import "TGFolder.h"
#import "TGDialog.h"
#import "TGChatPhoto.h"

@implementation TGManagedObjectModel

+(TGManagedObjectModel *)model
{
	TGManagedObjectModel *model = [super init];
	[model setEntities:[NSArray arrayWithObjects:
		[TGPeer entity], 
		[TGMessage entity], 
		[TGFolder entity], 
		[TGDialog entity], 
		[TGChatPhoto entity], 
		nil]];

	return model;
}

@end

// vim:ft=objc
