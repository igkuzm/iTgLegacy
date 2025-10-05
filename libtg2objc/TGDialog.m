#import "TGDialog.h"
#import "NSString+libtg2.h"
#import "CoreDataTools.h"

@implementation TGDialog 

- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
{
	if (tl == NULL)
		return;
	
	if (tl->_id == id_dialog){
		tl_dialog_t *tl = (tl_dialog_t *)tl;

#define TL_MACRO_EXE TL_MACRO_dialog
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not dialog type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGDialog *)newWithTL:(const tl_t *)tl
							  context:(NSManagedObjectContext *)context
{
	TGDialog *obj = 
		[NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj updateWithTL:tl context:context];
	return obj;
}

+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer
{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_dialog
#include "macro_attributes.h"
	];
	
	NSArray *relations = @[ 
		[Relation name:@"peer" entity:tgpeer],
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
