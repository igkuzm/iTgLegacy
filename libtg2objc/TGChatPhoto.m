#import "TGChatPhoto.h"
#import "NSData+libtg2.h"

@implementation TGChatPhoto
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		self.chatPhotoType = kTGChatPhotoTypeChatPhotoEmpty;

		if (tl->_id == id_chatPhoto){
			tl_chatPhoto_t *p = (tl_chatPhoto_t *)tl;
			self.chatPhotoType = kTGChatPhotoTypeChatPhoto;
			self.has_video = p->has_video_;
			self.photo_id = p->photo_id_;
			self.stripped_thumb = [NSData dataFromPhotoStripped:p->stripped_thumb_];
			self.dc_id = p->dc_id_;
		}
	}
	return self;
}

+ (NSEntityDescription *)entityDescription{

	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"TGChatPhoto"];
	[entity setManagedObjectClassName:@"TGChatPhoto"];
	
	NSMutableArray *properties = [NSMutableArray array];
	
	// create the attributes
	// Boolean
	for (NSString *attributeDescriptionName in @[
			@"has_video",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSBooleanAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int32
	for (NSString *attributeDescriptionName in @[
			@"chatPhotoType",
			@"dc_id",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int64
	for (NSString *attributeDescriptionName in @[
			@"photo_id",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSInteger64AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// NSBinaryData
	for (NSString *attributeDescriptionName in @[
			@"stripped_thumb",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSBinaryDataAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	[entity setProperties:properties];

	return entity;
}

@end
// vim:ft=objc
