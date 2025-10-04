#import "TGChatPhoto.h"
#import "NSData+libtg2.h"
#import "CoreDataTools.h"

@implementation TGChatPhoto
- (void)updateWithTL:(const tl_t *)tl{
	self.chatPhotoType = kTGChatPhotoTypeChatPhotoEmpty;
	if (tl->_id == id_chatPhoto){
		tl_chatPhoto_t *p = (tl_chatPhoto_t *)tl;
		self.chatPhotoType = kTGChatPhotoTypeChatPhoto;
		self.has_video = p->has_video_;
		self.photo_id = p->photo_id_;
		self.stripped_thumb = [NSData dataFromPhotoStripped:p->stripped_thumb_];
		self.dc_id = p->dc_id_;
		
		return;
	}
	NSLog(@"tl is not chatPhoto type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGChatPhoto *)newWithTL:(const tl_t *)tl{
	TGChatPhoto *obj = [[TGChatPhoto alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s: %s", __FILE__, __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"chatPhotoType" type:NSInteger32AttributeType],
		[Attribute name:@"has_video" type:NSBooleanAttributeType],
		[Attribute name:@"photo_id" type:NSInteger64AttributeType],
		[Attribute name:@"stripped_thumb" type:NSBinaryDataAttributeType],
		[Attribute name:@"dc_id" type:NSInteger32AttributeType],
	];
	
	NSArray *relations = @[ 
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}
@end
// vim:ft=objc
