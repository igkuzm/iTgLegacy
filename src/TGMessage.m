#import "TGMessage.h"
#include "Foundation/Foundation.h"

@implementation TGMessage
- (id)initWithMessage:(const tg_message_t *)m {
	if (self = [super init]) {
		self.silent = m->silent_;
		self.pinned = m->pinned_;
		self.id = m->id_;
		tg_peer_t peer = 
			{m->type_peer_id_, m->peer_id_, 0};
		self.peer = peer;
		tg_peer_t from = 
			{m->type_from_id_, m->from_id_, 0};
		self.from = from;
		self.date = [NSDate dateWithTimeIntervalSince1970:m->date_];
		self.photo = NULL;
		self.photoId = m->photo_id;
		self.photoAccessHash = m->photo_access_hash;
		if (m->photo_file_reference)
			self.photoFileReference = 
				[NSString stringWithUTF8String:m->photo_file_reference];
		self.photoDate = 
			[NSDate dateWithTimeIntervalSince1970:m->photo_date];
		if (m->message_){
			self.message = [NSString stringWithUTF8String:m->message_];
		} else {
			self.message = [NSString string];
		}
		self.mediaType = m->media_type;
		self.isVoice = m->doc_isVoice;
		self.isVideo = m->doc_isVideo;
		if (m->doc_mime_type){
			self.mimeType = [NSString stringWithUTF8String:m->doc_mime_type];
		}
	}
	return self;
}

@end
// vim:ft=objc
