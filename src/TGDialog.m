#import "TGDialog.h"
#import "Base64/Base64.h"

@implementation TGDialog

- (id)initWithDialog:(const tg_dialog_t *)d 
{
	if (self = [super init]) {
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

		self.accessHash = d->access_hash;
		self.peerId = d->peer_id;
		self.peerType = d->peer_type;
		self.date = [NSDate dateWithTimeIntervalSince1970:d->top_message_date]; 
	}
	return self;
}

@end

// vim:ft=objc
