#import "TGChatPhoto.h"
#import "NSData+libtg2.h"
#import "NSString+libtg2.h"
#import "CoreDataTools.h"

@implementation TGChatPhoto
- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
{
	if (tl == NULL)
		return;
	
	if (tl->_id != id_chatPhotoEmpty ||
			tl->_id != id_chatPhoto)
	{
		NSLog(@"tl is not chatPhoto type: %s",
				TL_NAME_FROM_ID(tl->_id));
		return;
	}
	
	self.tl_id = [NSNumber numberWithInt:id_chatPhotoEmpty];
	
	if (tl->_id == id_chatPhoto){
		tl_chatPhoto_t *tl = (tl_chatPhoto_t *)tl;

#define TL_MACRO_EXE TL_MACRO_chatPhoto
#include "macro_from_tl.h"
		
		self.stripped_thumb_ = 
			[NSData dataFromPhotoStripped:tl->stripped_thumb_];

		return;
	}

}

+ (TGChatPhoto *)newWithTL:(const tl_t *)tl
									 context:(NSManagedObjectContext *)context
{
	TGChatPhoto *obj = 
		[NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj updateWithTL:tl context:context];
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_chatPhoto
#include "macro_attributes.h"
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

/*
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

	obj.objectType = [[mo valueForKey:@"objectType"]intValue];

#define TL_MACRO_EXE TL_MACRO_chatPhoto
#include "macro_from_managed_object.h"
	
	return obj;
}

- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context
{
	NSManagedObject *mo = [NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];

	[mo setValue:[NSNumber numberWithInt:self.objectType] forKey:@"objectType"];

#define TL_MACRO_EXE TL_MACRO_chatPhoto
#include "macro_to_managed_object.h"

	return mo;
}
*/
@end
// vim:ft=objc
