#import "TGManagedObjectModel.h"
#import "TGPeer.h"
#import "TGMessage.h"
#import "TGFolder.h"
#import "TGDialog.h"
#import "TGChatPhoto.h"

@implementation TGManagedObjectModel

+(TGManagedObjectModel *)model
{
	NSLog(@"%s", __func__);
	TGManagedObjectModel *model = [[TGManagedObjectModel alloc] init];
	
	NSEntityDescription *chatPhoto = [TGChatPhoto entity];
	NSEntityDescription *folder = [TGFolder entityWithTGphoto:chatPhoto];
	NSEntityDescription *peer = [TGPeer entity];
	NSEntityDescription *dialog = [TGDialog
		entityWithTGPeer:peer TGFolder:folder];
	NSEntityDescription *message = [TGMessage
		entityWitgTGPeer:peer];
	

	[model setEntities:[NSArray arrayWithObjects:
		chatPhoto,
		folder,
		peer,
		dialog,
		message,
		nil]];

	return model;
}

@end

// vim:ft=objc
