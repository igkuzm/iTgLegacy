#import "TGDialog.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "AppDelegate.h"
#include <stdlib.h>
#import "Base64/Base64.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/files.h"
#import "UIImage+Utils/UIImage+Utils.h"

@implementation TGDialog

- (id)initWithDialog:(const tg_dialog_t *)d tg:(tg_t *)tg syncData:(NSOperationQueue *)syncData;
{
	if (self = [super init]) {
		self.syncData = syncData;
		
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

		self.accessHash = d->access_hash;
		self.peerId = d->peer_id;
		self.peerType = d->peer_type;
		self.date = 
			[NSDate dateWithTimeIntervalSince1970:d->top_message_date]; 
		self.unread_count = d->unread_count;
		self.imageView = NULL;


		self.pinned = d->pinned;
		self.hidden = (d->folder_id == 1);
		
		self.photoId = d->photo_id;
		
		self.photo = NULL;
			
		AppDelegate *appDelegate = 
			UIApplication.sharedApplication.delegate;
		self.photoPath = 
			[NSString stringWithFormat:@"%@/%lld.%lld", 
				appDelegate.peerPhotoCache, self.peerId, self.photoId]; 
		if ([NSFileManager.defaultManager fileExistsAtPath:self.photoPath])
			self.photo = [UIImage 
				imageWithData:[NSData dataWithContentsOfFile:self.photoPath]];

		self.broadcast = d->broadcast;
	}
	return self;
}

@end
// vim:ft=objc
