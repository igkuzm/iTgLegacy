#import "TGChatPhoto.h"
#include "Foundation/Foundation.h"
#include "CoreData/CoreData.h"
#import "NSData+libtg2.h"
#import "CoreDataTools.h"

@implementation TGChatPhoto
- (void)updateWithTL:(const tl_t *)tl{
	self.chatPhotoType = id_chatPhotoEmpty;
	if (tl->_id == id_chatPhoto){
		tl_chatPhoto_t *p = (tl_chatPhoto_t *)tl;
		self.chatPhotoType = id_chatPhoto;
		self.has_video = p->has_video_;
		self.photo_id = p->photo_id_;
		self.stripped_thumb = [NSData dataFromPhotoStripped:p->stripped_thumb_];
		self.dc_id = p->dc_id_;
		
		return;
	}
	NSLog(@"tl is not chatPhoto type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGChatPhoto *)newWithTL:(const tl_t *)tl
{
	TGChatPhoto *obj = [[TGChatPhoto alloc] init];
	[obj updateWithTL:tl];
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s", __func__);

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

+ (TGChatPhoto *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);

		return NULL;
	}

	TGChatPhoto *obj = [[TGChatPhoto alloc] init];
	obj.managedObject = mo;
	
	obj.chatPhotoType = [[mo valueForKey:@"chatPhotoType"]intValue];
	obj.has_video = [[mo valueForKey:@"has_video"]boolValue];
	obj.photo_id = [[mo valueForKey:@"photo_id"]longLongValue];
	obj.stripped_thumb = [mo valueForKey:@"stripped_thumb"];
	obj.dc_id = [[mo valueForKey:@"dc_id"]intValue];
	
	return obj;
}

- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context
{
	NSManagedObject *obj = [NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj setValue:[NSNumber numberWithInt:self.chatPhotoType] 
				 forKey:@"chatPhotoType"];
	[obj setValue:[NSNumber numberWithBool:self.has_video] 
				 forKey:@"has_video"];
	[obj setValue:[NSNumber numberWithLongLong:self.photo_id] 
				 forKey:@"photo_id"];
	[obj setValue:self.stripped_thumb 
				 forKey:@"stripped_thumb"];
	[obj setValue:[NSNumber numberWithInt:self.dc_id] 
				 forKey:@"dc_id"];

	return obj;
}

@end
// vim:ft=objc
