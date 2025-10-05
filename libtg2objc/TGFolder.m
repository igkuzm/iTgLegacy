#import "TGFolder.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGFolder
- (void)updateWithTL:(const tl_t *)tl{
	
	self.objectType = tl->_id;
	
	if (tl->_id == id_folder){
		tl_folder_t *tl = (tl_folder_t *)tl;

#define TL_MACRO_EXE TL_MACRO_folder
#include "macro_from_tl.h"

		return;
	}
	NSLog(@"tl is not folder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGFolder *)newWithTL:(const tl_t *)tl{
	TGFolder *obj = [[TGFolder alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entityWithTGphoto:(NSEntityDescription *)tgphoto;
{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_folder
#include "macro_attributes.h"
	];
	
	NSArray *relations = @[ 
		[Relation name:@"photo" entity:tgphoto],
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}

+ (TGFolder *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);

		return NULL;
	}

	TGFolder *obj = [[TGFolder alloc] init];
	obj.managedObject = mo;

	obj.objectType = [[mo valueForKey:@"objectType"]intValue];
#define TL_MACRO_EXE TL_MACRO_folder
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
#define TL_MACRO_EXE TL_MACRO_folder
#include "macro_to_managed_object.h"

	return mo;
}

@end
// vim:ft=objc
