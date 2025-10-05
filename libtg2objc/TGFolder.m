#import "TGFolder.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGFolder
- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
{
	if (tl == NULL)
		return;
	
	if (tl->_id == id_folder){
		tl_folder_t *tl = (tl_folder_t *)tl;

#define TL_MACRO_EXE TL_MACRO_folder
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not folder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGFolder *)newWithTL:(const tl_t *)tl
								context:(NSManagedObjectContext *)context
{
	TGFolder *obj = 
		[NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj updateWithTL:tl context:context];
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

@end
// vim:ft=objc
