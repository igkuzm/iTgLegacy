#import "TGDialogFolder.h"
#import "NSString+libtg2.h"
#import "CoreDataTools.h"

@implementation TGDialogFolder 

- (void)updateWithTL:(const tl_t *)tl{
	
	self.objectType = tl->_id;
		
	if (tl->_id == id_dialogFolder){
		tl_dialogFolder_t *tl = (tl_dialogFolder_t *)tl;

#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not dialogFolder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGDialogFolder *)newWithTL:(const tl_t *)tl{
	TGDialogFolder *obj = [[TGDialogFolder alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer
	TGFolder:(NSEntityDescription *)tgfolder
{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_attributes.h"
	];
	
	NSArray *relations = @[ 
		[Relation name:@"peer" entity:tgpeer],
		[Relation name:@"folder" entity:tgfolder],
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}

+ (TGDialogFolder *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);
		
		return NULL;
	}

	TGDialogFolder *obj = [[TGDialogFolder alloc] init];
	obj.managedObject = mo;

	obj.objectType = [[mo valueForKey:@"objectType"]intValue];
#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_from_managed_object.h"

	// notify_settings
	// draft

	return obj;
}

- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context
{
	NSManagedObject *mo = [NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];

	[mo setValue:[NSNumber numberWithInt:self.objectType] forKey:@"objectType"];
#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_to_managed_object.h"
	
	return mo;
}

@end

// vim:ft=objc
