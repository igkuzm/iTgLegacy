#import "TGMessage.h"
#import "AppDelegate.h"
#import "AppDelegate.h"
#include "Foundation/Foundation.h"

@implementation TGMessage
- (id)initWithMessage:(const tg_message_t *)m{
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
		else
			self.photoFileReference = [NSString string];
		self.photoDate = 
			[NSDate dateWithTimeIntervalSince1970:m->photo_date];

		self.docId = m->doc_id;
		self.docSize = m->doc_size;
		self.docAccessHash = m->doc_access_hash;
		if (m->doc_file_reference)
			self.docFileReference = 
				[NSString stringWithUTF8String:m->doc_file_reference];
		else
			self.docFileReference = [NSString string];

		if (m->message_)
			self.message = [NSString stringWithUTF8String:m->message_];
		
		self.mediaType = m->media_type;
		self.isVoice = m->doc_isVoice;
		self.isVideo = m->doc_isVideo;
		if (m->doc_mime_type){
			self.mimeType = [NSString stringWithUTF8String:m->doc_mime_type];
		}

		if (m->doc_file_name)
			self.docFileName = 
				[NSString stringWithUTF8String:m->doc_file_name];

		AppDelegate *appDelegate = 
			UIApplication.sharedApplication.delegate;

		NSNumber *userId = [NSUserDefaults.standardUserDefaults 
			valueForKey:@"userId"];
		self.mine = 
			(userId && [userId longLongValue] == m->from_id_);

		self.photoPath = 
			[NSString stringWithFormat:@"%@/%lld", 
				appDelegate.smallPhotoCache, self.photoId]; 
		if ([NSFileManager.defaultManager fileExistsAtPath:self.photoPath])
		{
			self.photoData = [NSData dataWithContentsOfFile:self.photoPath];
			self.photo = [UIImage imageWithData:self.photoData];
		}

		//self.docThumbPath = 
			//[NSString stringWithFormat:@"%@/%lld", 
				//appDelegate.thumbDocCache, self.docId]; 
		//if ([NSFileManager.defaultManager fileExistsAtPath:self.docThumbPath])
		//{
			//self.photoData = [NSData dataWithContentsOfFile:self.docThumbPath];
			//self.photo = [UIImage imageWithData:self.photoData];
		//}

		if ([self.mimeType isEqualToString:@"video/mov"] ||
		    [self.mimeType isEqualToString:@"video/mp4"] ||
				[self.docFileName.pathExtension.lowercaseString 
					isEqualToString:@"mov"] ||
				[self.docFileName.pathExtension.lowercaseString 
					isEqualToString:@"mp4"]
				)
		{
			self.isVideo = YES;
		}

		if ([self.mimeType isEqualToString:@"audio/ogg"] ||
				[self.docFileName.pathExtension.lowercaseString 
					isEqualToString:@"ogg"]
				)
		{
			self.isVoice = YES;
		}
	}
	return self;
}

@end
// vim:ft=objc
