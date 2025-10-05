#import "TGMessage.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGMessage 

- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
{
	if (tl == NULL)
		return;
	
	if (tl->_id == id_message){
		tl_message_t *tl = (tl_message_t *)tl;

#define TL_MACRO_EXE TL_MACRO_message
#include "macro_from_tl.h"

		return;
	}
	
	NSLog(@"tl is not message type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGMessage *)newWithTL:(const tl_t *)tl
								 context:(NSManagedObjectContext *)context
{
	TGMessage *obj = 
		[NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj updateWithTL:tl context:context];
	return obj;
}

+ (NSEntityDescription *)
	entityWitgTGPeer:(NSEntityDescription *)tgpeer
{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
#define TL_MACRO_EXE TL_MACRO_message
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

@end

// vim:ft=objc
