#import "TGPeer.h"
@implementation TGPeer
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		if (tl->_id == id_peerUser){
			self.peerType = kTGPeerTypeUser;
			self.id = ((tl_peerUser_t *)tl)->user_id_;
			return self;
		}
		if (tl->_id == id_peerChat){
			self.peerType = kTGPeerTypeChat;
			self.id = ((tl_peerChat_t *)tl)->chat_id_;
			return self;
		}
		if (tl->_id == id_peerChannel){
			self.peerType = kTGPeerTypeChannel;
			self.id = ((tl_peerChannel_t *)tl)->channel_id_;
			return self;
		}
	}
	return self;
}

+ (NSEntityDescription *)entity{

	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"TGPeer"];
	[entity setManagedObjectClassName:@"TGPeer"];
	
	// create the attributes
	NSMutableArray *properties = [NSMutableArray array];

	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:@"peerType"];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}
 
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:@"id"];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	[entity setProperties:properties];

	return entity;
}
@end
// vim:ft=objc
