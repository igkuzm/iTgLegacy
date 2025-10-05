#import "TGMessageEmpty.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGMessageEmpty 

- (void)updateWithTL:(const tl_t *)tl{
	
	self.objectType = tl->_id;
	
	if (tl->_id == id_messageEmpty){
		tl_messageEmpty_t *tl = (tl_messageEmpty_t *)tl;

#define TL_MACRO_EXE TL_MACRO_messageEmpty
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not message type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGMessageEmpty *)newWithTL:(const tl_t *)tl{
	TGMessageEmpty *obj = [[TGMessageEmpty alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)
	entityWitgTGPeer:(NSEntityDescription *)tgpeer
{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_messageEmpty
#include "macro_attributes.h"
	];
	
	NSArray *relations = @[ 
		[Relation name:@"from_id" entity:tgpeer],
		[Relation name:@"peer_id" entity:tgpeer],
		[Relation name:@"saved_peer_id" entity:tgpeer],
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}

+ (TGMessage *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);

		return NULL;
	}

	TGMessageEmpty *obj = [[TGMessageEmpty alloc] init];
	obj.managedObject = mo;

	obj.objectType = [[mo valueForKey:@"objectType"]intValue];
#define TL_MACRO_EXE TL_MACRO_messageEmpty
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
#define TL_MACRO_EXE TL_MACRO_messageEmpty
#include "macro_to_managed_object.h"

	return mo;
}

@end

// vim:ft=objc
