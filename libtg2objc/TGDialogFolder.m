#import "TGDialogFolder.h"
#import "NSString+libtg2.h"
#import "CoreDataTools.h"

@implementation TGDialogFolder 

- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
{
	if (tl == NULL)
		return;

	if (tl->_id == id_dialogFolder){
		tl_dialogFolder_t *tl = (tl_dialogFolder_t *)tl;

#define TL_MACRO_EXE TL_MACRO_dialogFolder
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not dialogFolder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGDialogFolder *)newWithTL:(const tl_t *)tl
									    context:(NSManagedObjectContext *)context
{
	TGDialogFolder *obj = 
		[NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj updateWithTL:tl context:context];
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

@end

// vim:ft=objc
