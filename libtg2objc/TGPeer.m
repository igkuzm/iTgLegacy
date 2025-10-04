#import "TGPeer.h"
#import "CoreDataTools.h"
@implementation TGPeer
- (void)updateWithTL:(const tl_t *)tl{
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

@end
// vim:ft=objc
