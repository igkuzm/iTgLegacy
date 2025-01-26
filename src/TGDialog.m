#import "TGDialog.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "AppDelegate.h"
#include <stdlib.h>
#import "Base64/Base64.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"
#include "../libtg/tg/files.h"
#import "UIImage+Utils/UIImage+Utils.h"

@implementation TGDialog

- (id)initWithDialog:(const tg_dialog_t *)d tg:(tg_t *)tg syncData:(NSOperationQueue *)syncData;
{
	if (self = [super init]) {
		self.syncData = syncData;
		self.syncData.maxConcurrentOperationCount = 1;
		
		if (d->name)
			self.title = [NSString stringWithUTF8String:d->name];
		
		if (d->top_message_text)
			self.top_message = 
				[NSString stringWithUTF8String:d->top_message_text];
		
		if (d->thumb){
			//buf_t b64 = buf_from_base64(d->thumb);
			NSData *thumbData = 
				[NSData dataFromBase64String:[NSString stringWithUTF8String:d->thumb]];
				//[NSData dataWithBytes:b64.data length:b64.size];
			if (thumbData.length > 0)
				self.thumb = [UIImage imageWithData:thumbData];
		}

		self.topMessageId = d->top_message_id;
		self.topMessageFromId = d->top_message_from_peer_id;

		self.accessHash = d->access_hash;
		self.peerId = d->peer_id;
		self.peerType = d->peer_type;
		self.date = 
			[NSDate dateWithTimeIntervalSince1970:d->top_message_date]; 
		self.unread_count = d->unread_count;
		self.spinner = [[UIActivityIndicatorView alloc]
			initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];

		self.pinned = d->pinned;
		self.hidden = (d->folder_id == 1);
		
		self.photoId = d->photo_id;

		self.readDate = -1;
		[self syncReadDate];
		
		self.broadcast = d->broadcast;

		AppDelegate *appDelegate = 
			UIApplication.sharedApplication.delegate;
		
		self.photoPath = 
			[NSString stringWithFormat:@"%@/%lld.%lld", 
				appDelegate.peerPhotoCache, self.peerId, self.photoId];

		// downloadBlock
		
		self.photoDownloadBlock = ^NSData *{
			return [TGDialog dialogPhotoDownloadBlock:self];
		};
	}
	return self;
}

-(void)syncReadDate{
	NSNumber *userId = [NSUserDefaults.standardUserDefaults 
		valueForKey:@"userId"];
	if (self.peerType == TG_PEER_TYPE_USER &&
			self.peerId != userId.longLongValue &&
			(self.topMessageFromId == userId.longLongValue))
	{
		AppDelegate *appDelegate = 
				UIApplication.sharedApplication.delegate;
		if (appDelegate.isOnLineAndAuthorized){
			[self.syncData addOperationWithBlock:^{
				tg_peer_t peer = {
						self.peerType,
						self.peerId,
						self.accessHash
				};
				int date = tg_messages_get_read_date(
						appDelegate.tg, peer, self.topMessageId);
				if (date){
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.readDate = date;
					});
				}
			}];
		}
	}
}

+(NSData *)dialogPhotoDownloadBlock:(TGDialog *)dialog
{
	tg_peer_t peer = {
				dialog.peerType,
				dialog.peerId,
				dialog.accessHash
		};
	AppDelegate *appDelegate = 
		UIApplication.sharedApplication.delegate;
	if (!appDelegate.isOnLineAndAuthorized)
		return nil;
	char *photo = tg_get_peer_photo_file(
				appDelegate.tg, 
				&peer, 
				false, 
				dialog.photoId);
	if (photo){
		NSData *data = [NSData 
			dataFromBase64String:
				[NSString stringWithUTF8String:photo]];
		return data;
	}
	return nil;
}

@end
// vim:ft=objc
