#import "TGMessage.h"
#include "UIKit/UIKit.h"
#include <string.h>
#include "CoreGraphics/CoreGraphics.h"
#import "AppDelegate.h"
#import "AppDelegate.h"
#include "Foundation/Foundation.h"
#import "Base64/Base64.h"

@implementation TGMessage
- (id)initWithMessage:(const tg_message_t *)m dialog:(const TGDialog *)d{
	if (self = [super init]) {
		self.isBroadcast = d.broadcast;
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
		self.isSticker = m->is_sticker;
		self.isService = m->is_service;
		if (m->doc_mime_type){
			self.mimeType = [NSString stringWithUTF8String:m->doc_mime_type];
		}

		if (m->doc_file_name)
			self.docFileName = 
				[NSString stringWithUTF8String:m->doc_file_name];

		// geopoint
		self.geoAccessHash = m->geo_access_hash;
		self.geoLat = m->geo_lat;
		self.geoLong = m->geo_long;
		self.geoRadius = m->geo_accuracy_radius;

		// contact
		if (m->contact_vcard)
			self.contactVcard = [NSString stringWithUTF8String:m->contact_vcard];
		if (m->contact_first_name)
			self.contactFirstName = [NSString stringWithUTF8String:m->contact_first_name];
		if (m->contact_last_name)
			self.contactLastName = [NSString stringWithUTF8String:m->contact_last_name];
		if (m->contact_phone_number)
			self.contactPhoneNumber = [NSString stringWithUTF8String:m->contact_phone_number];
		self.contactId = m->contact_user_id;

		if (self.mediaType == id_messageMediaContact) 
			self.docFileName = [NSString stringWithFormat:@"%@ %@\n%@",
				self.contactFirstName, 
				self.contactLastName, self.contactPhoneNumber];

		AppDelegate *appDelegate = 
			UIApplication.sharedApplication.delegate;

		NSNumber *userId = [NSUserDefaults.standardUserDefaults 
			valueForKey:@"userId"];
		self.mine = (userId && userId.longLongValue == m->from_id_);
		if (d.peerType == TG_PEER_TYPE_CHANNEL && !d.broadcast){
			if (!self.mine)
				self.mine = (m->from_id_ == 0);	
		}

		// photo
		if (m->photo_id && m->photo_cached_size){
			NSString *pcs = 
				[NSString stringWithUTF8String:m->photo_cached_size];
			//NSLog(@"PHOTO CACHED: %@", pcs); 
			NSArray *psca = [pcs componentsSeparatedByString:@" "];
			for (NSString *size in psca){
				self.photoCachedSize = CGSizeFromString(size);
				break;
			}

			//NSLog(@"PHOTO CACHED SIZE: %lfx%lf", 
					//self.photoCachedSize.width, self.photoCachedSize.height);
		}
		if (m->photo_sizes){
			self.photoSizes = [NSMutableArray array];
			NSString *ps = 
				[NSString stringWithUTF8String:m->photo_sizes];
			//NSLog(@"PHOTO: %@", ps); 
			NSArray *photoSizesWithTypes = 
				[ps componentsSeparatedByString:@" "];
			for (NSString *sizeWithType in photoSizesWithTypes){
				NSArray *parts = [sizeWithType componentsSeparatedByString:@"="];
				if (parts.count < 2)
					continue;
				NSString *type = [parts objectAtIndex:0];
				NSString *size = [parts objectAtIndex:1];
				NSArray *wh = [size componentsSeparatedByString:@"x"];
				if (wh.count < 2)
					continue;
				CGSize s = CGSizeMake(
						[[wh objectAtIndex:0] floatValue], 
						[[wh objectAtIndex:1] floatValue]);
				NSDictionary *dict = @{@"type":type, @"size":[NSValue valueWithCGSize:s]};
				[self.photoSizes addObject:dict];
				//NSLog(@"PHOTO SIZE IN MESSAGE: %lfx%lf", 
						//s.width, s.height);
			}
			//NSLog(@"PHOTO SIZES ARRAY COUNT: %ld", self.photoSizes.count);
		}
		if (m->photo_id && m->photo_stripped){
			NSData *thumbData = 
				[NSData dataFromBase64String:[NSString 
								stringWithUTF8String:m->photo_stripped]];
				//[NSData dataWithBytes:b64.data length:b64.size];
			if (thumbData.length > 0)
				self.photoStripped = [UIImage imageWithData:thumbData];
			//NSLog(@"PHOTO STRIPPED: %@", self.photoStripped);
		}

		self.photoPath = 
			[NSString stringWithFormat:@"%@/%lld.x.png", 
				appDelegate.smallPhotoCache, self.photoId]; 
		if ([NSFileManager.defaultManager fileExistsAtPath:self.photoPath])
		{
			self.photoData = [NSData dataWithContentsOfFile:self.photoPath];
			self.photo = [UIImage imageWithData:self.photoData];
		}

		// video
		self.videoThumbPath = 
			[NSString stringWithFormat:@"%@/%lld.v.png", 
				appDelegate.smallPhotoCache, self.docId];

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
		if (m->video_sizes){
			self.videoSizes = [NSMutableArray array];
			NSString *ps = 
				[NSString stringWithUTF8String:m->video_sizes];
			NSArray *videoSizesWithTypes = 
				[ps componentsSeparatedByString:@" "];
			for (NSString *sizeWithType in videoSizesWithTypes){
				NSArray *parts = [sizeWithType componentsSeparatedByString:@"="];
				if (parts.count < 4)
					continue;
				NSString *type = [parts objectAtIndex:0];
				NSString *size = [parts objectAtIndex:1];
				NSString *len  = [parts objectAtIndex:2];
				NSString *sec  = [parts objectAtIndex:3];
				NSArray *wh = [size componentsSeparatedByString:@"x"];
				if (wh.count < 2)
					continue;
				CGSize s = CGSizeMake(
						[[wh objectAtIndex:0] floatValue], 
						[[wh objectAtIndex:1] floatValue]);
				NSDictionary *dict = @{
					@"type":type, 
					@"size":[NSValue valueWithCGSize:s],
					@"len" :[NSNumber numberWithInt:len.intValue],
					@"sec" :[NSNumber numberWithDouble:sec.doubleValue]
				};
				[self.videoSizes addObject:dict];
			}
		}
		if (m->photo_id && m->photo_stripped){
			NSData *thumbData = 
				[NSData dataFromBase64String:[NSString 
								stringWithUTF8String:m->photo_stripped]];
				//[NSData dataWithBytes:b64.data length:b64.size];
			if (thumbData.length > 0)
				self.photoStripped = [UIImage imageWithData:thumbData];
			//NSLog(@"PHOTO STRIPPED: %@", self.photoStripped);
		}

		// voice
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
