#import "TGManagedObjectModel.h"
#import "TGPeer.h"
#import "TGMessage.h"
#import "TGMessageService.h"
#import "TGMessageEmpty.h"
#import "TGFolder.h"
#import "TGDialog.h"
#import "TGDialogFolder.h"
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
		entityWithTGPeer:peer];
	NSEntityDescription *dialogFolder = [TGDialogFolder
		entityWithTGPeer:peer TGFolder:folder];
	NSEntityDescription *message = [TGMessage
		entityWitgTGPeer:peer];
	NSEntityDescription *messageService = [TGMessageService
		entityWitgTGPeer:peer];
	NSEntityDescription *messageEmpty = [TGMessageEmpty
		entityWitgTGPeer:peer];
	

	[model setEntities:[NSArray arrayWithObjects:
		chatPhoto,
		folder,
		peer,
		dialog,
		dialogFolder,
		message,
		messageService,
		messageEmpty,
		nil]];

	return model;
}

@end

// vim:ft=objc
