#import "TGManagedObjectModel.h"
#import "TGPeer.h"
#import "TGMessage.h"
#import "TGFolder.h"
#import "TGDialog.h"
#import "TGChatPhoto.h"

@implementation TGManagedObjectModel

+(TGManagedObjectModel *)model
{
	NSLog(@"%s: %s", __FILE__, __func__);
	TGManagedObjectModel *model = [[TGManagedObjectModel alloc] init];
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
