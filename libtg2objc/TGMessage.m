#import "TGMessage.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGMessage 

- (void)updateWithTLMessage:(const tl_message_t *)m{
	self.messageType = kTGMessageTypeMessage;
	self.out = m->out_;
	self.mentioned = m->mentioned_;
	self.media_unread = m->media_unread_;
	self.silent = m->silent_;
	self.post = m->post_;
	self.from_scheduled = m->from_scheduled_;
	self.legacy = m->legacy_;
	self.edit_hide = m->edit_hide_;
	self.pinned = m->pinned_;
	self.noforwards = m->noforwards_;
	self.invert_media = m->invert_media_;
	self.offline = m->offline_;
	self.id = m->id_;
	self.from_id = [[TGPeer alloc]initWithTL:m->from_id_];
	self.from_boosts_applied = m->from_boosts_applied_;
	self.peer_id = [[TGPeer alloc]initWithTL:m->peer_id_];
	self.saved_peer_id = [[TGPeer alloc]initWithTL:m->saved_peer_id_];
	// fwd_from
	self.via_bot_id = m->via_bot_id_;
	self.via_business_bot_id = m->via_business_bot_id_;
	// reply_to
	self.date = [NSDate dateWithTimeIntervalSince1970:m->date_];
	self.message = [NSString sringWithTLString:m->message_]; 
	// media
	// reply_markup
	// entities
	self.views = m->views_;
	self.forwards = m->forwards_;
	// replies
	self.edit_date = [NSDate dateWithTimeIntervalSince1970:m->edit_date_];
	self.post_author = [NSString sringWithTLString:m->post_author_];
	self.grouped_id = m->grouped_id_;
	// reactions
	// restriction_reason
	self.timeToLive = [NSDate dateWithTimeIntervalSince1970:(m->date_ + m->ttl_period_)];
	self.quick_reply_shortcut_id = m->quick_reply_shortcut_id_;
	self.effect = m->effect_;
	// factcheck
}

- (void)updateWithTLMessageService:(const tl_messageService_t *)m{
	self.messageType = kTGMessageTypeMessageService;
	self.out = m->out_;
	self.mentioned = m->mentioned_;
	self.media_unread = m->media_unread_;
	self.silent = m->silent_;
	self.post = m->post_;
	self.legacy = m->legacy_;
	self.id = m->id_;
	self.from_id = [[TGPeer alloc] initWithTL:m->from_id_];
	self.peer_id = [[TGPeer alloc]initWithTL:m->peer_id_];
	// reply_to
	self.date = [NSDate dateWithTimeIntervalSince1970:m->date_];
	// action
	self.ttl_period = m->ttl_period_;
	self.timeToLive = [NSDate dateWithTimeIntervalSince1970:(m->date_ + m->ttl_period_)];
}

- (void)updateWithTLMessageEmpty:(const tl_messageEmpty_t *)m{
	self.messageType = kTGMessageTypeEmplty;
	self.id = m->id_;
	self.peer_id = [[TGPeer alloc]initWithTL:m->peer_id_];
}

- (void)updateWithTL:(const tl_t *)tl{
	if (tl->_id == id_message){
		[self initWithTLMessage:(tl_message_t *)tl];
		return;
	}
	
	if (tl->_id == id_messageService){
		[self initWithTLMessageService:(tl_messageService_t *)tl];
		return;
	}

	if (tl->_id == id_messageEmpty){
		[self initWithTLMessageEmpty:(tl_messageEmpty_t *)tl];
		return;
	}

	NSLog(@"tl is not message type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (NSEntityDescription *)entity{

	NSArray *attributes = @[ 
		[NSAttributeDescription 
			attributeWithName:@"messageType" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"out" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"mentioned" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"media_unread" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"silent" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"post" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"from_scheduled" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"legacy" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"edit_hide" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"pinned" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"noforwards" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"invert_media" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"offline" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"id" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"from_boosts_applied" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"via_bot_id" 
									 type:NSInteger64AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"via_business_bot_id" 
									 type:NSInteger64AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"date" 
									 type:NSDateAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"message" 
									 type:NSStringAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"views" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"forwards" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"edit_date" 
									 type:NSDateAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"post_author" 
									 type:NSStringAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"grouped_id" 
									 type:NSInteger64AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"ttl_period" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"timeToLive" 
									 type:NSDateAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"quick_reply_shortcut_id" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"effect" 
									 type:NSInteger64AttributeType],
	];
	
	NSArray *relations = @[ 
		[NSRelationshipDescription 
			relationWithName:@"from_id" 
								entity:[TGPeer entity]],
		[NSRelationshipDescription 
			relationWithName:@"peer_id" 
								entity:[TGPeer entity]],
		[NSRelationshipDescription 
			relationWithName:@"saved_peer_id" 
								entity:[TGPeer entity]],
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
