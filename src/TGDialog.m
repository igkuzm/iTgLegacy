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
		
		[self setPeerPhoto];
		
		self.broadcast = d->broadcast;
	}
	return self;
}

-(void)setPeerPhoto{
	AppDelegate *appDelegate = 
			UIApplication.sharedApplication.delegate;
	self.photoPath = 
		[NSString stringWithFormat:@"%@/%lld.%lld", 
			appDelegate.peerPhotoCache, self.peerId, self.photoId]; 
	if ([NSFileManager.defaultManager fileExistsAtPath:self.photoPath])
	{
		// set photo from local data
		self.photo = [UIImage 
			imageWithData:[NSData dataWithContentsOfFile:self.photoPath]];
		self.hasPhoto = YES;
	}
	else {
		self.hasPhoto = NO;
		[self.spinner startAnimating];
		// set default photo
		self.photo = [UIImage imageNamed:@"missingAvatar.png"];
		// download photo
		if (appDelegate.isOnLineAndAuthorized){
			[self.syncData addOperationWithBlock:^{
				tg_peer_t peer = {
						self.peerType,
						self.peerId,
						self.accessHash
				};
				char *photo = tg_get_peer_photo_file(
							appDelegate.tg, 
							&peer, 
							false, 
							self.photoId); 
				if (photo){
					NSData *data = [NSData 
						dataFromBase64String:
							[NSString stringWithUTF8String:photo]];
					if (data){
						// save photo
						[data writeToFile:self.photoPath atomically:YES];
						self.photo = [UIImage imageWithData:data];
					}
					self.photo = [UIImage imageWithData:data];
					self.hasPhoto = YES;
					free(photo);
				} // end if (photo)
				dispatch_sync(dispatch_get_main_queue(), ^{
					[self.spinner stopAnimating];
				});
			}];
		}
	}
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

@end
// vim:ft=objc
