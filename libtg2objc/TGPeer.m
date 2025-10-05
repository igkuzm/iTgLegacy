#import "TGPeer.h"
#import "CoreDataTools.h"

@implementation TGPeer
- (void)updateWithTL:(const tl_t *)tl{

	self.objectType = tl->_id;

	if (tl->_id == id_peerUser){
		self.peerType = id_peerUser;
		self.id = ((tl_peerUser_t *)tl)->user_id_;
		return;
	}
	if (tl->_id == id_peerChat){
		self.peerType = id_peerChat;
		self.id = ((tl_peerChat_t *)tl)->chat_id_;
		return;
	}
	if (tl->_id == id_peerChannel){
		self.peerType = id_peerChannel;
		self.id = ((tl_peerChannel_t *)tl)->channel_id_;
		return;
	}
	NSLog(@"tl is not peer type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGPeer *)newWithTL:(const tl_t *)tl{
	TGPeer *obj = [[TGPeer alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s", __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"objectType" type:NSInteger32AttributeType],
		[Attribute name:@"peerType" type:NSInteger32AttributeType],
		[Attribute name:@"id" type:NSInteger32AttributeType],
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

+ (TGPeer *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);

		return NULL;
	}

	TGPeer *obj = [[TGPeer alloc] init];
	obj.managedObject = mo;

	obj.objectType = [[mo valueForKey:@"objectType"]intValue];
	obj.peerType = [[mo valueForKey:@"peerType"]intValue];
	obj.id = [[mo valueForKey:@"id"]intValue];
	
	return obj;
}

- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context
{
	NSManagedObject *mo = [NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];

	[mo setValue:[NSNumber numberWithInt:self.objectType] forKey:@"objectType"];
	[mo setValue:[NSNumber numberWithInt:self.peerType] forKey:@"peerType"];
	[mo setValue:[NSNumber numberWithInt:self.id] forKey:@"id"];

	return mo;
}

@end
// vim:ft=objc
