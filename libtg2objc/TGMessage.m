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
	self.from_id = [TGPeer newWithTL:m->from_id_];
	self.from_boosts_applied = m->from_boosts_applied_;
	self.peer_id = [TGPeer newWithTL:m->peer_id_];
	self.saved_peer_id = [TGPeer newWithTL:m->saved_peer_id_];
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
	self.from_id = [TGPeer newWithTL:m->from_id_];
	self.peer_id = [TGPeer newWithTL:m->peer_id_];
	// reply_to
	self.date = [NSDate dateWithTimeIntervalSince1970:m->date_];
	// action
	self.ttl_period = m->ttl_period_;
	self.timeToLive = [NSDate dateWithTimeIntervalSince1970:(m->date_ + m->ttl_period_)];
}

- (void)updateWithTLMessageEmpty:(const tl_messageEmpty_t *)m{
	self.messageType = kTGMessageTypeEmplty;
	self.id = m->id_;
	self.peer_id = [TGPeer newWithTL:m->peer_id_];
}

- (void)updateWithTL:(const tl_t *)tl{
	if (tl->_id == id_message){
		[self updateWithTLMessage:(tl_message_t *)tl];
		return;
	}
	
	if (tl->_id == id_messageService){
		[self updateWithTLMessageService:(tl_messageService_t *)tl];
		return;
	}

	if (tl->_id == id_messageEmpty){
		[self updateWithTLMessageEmpty:(tl_messageEmpty_t *)tl];
		return;
	}

	NSLog(@"tl is not message type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGMessage *)newWithTL:(const tl_t *)tl{
	TGMessage *obj = [[TGMessage alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s: %s", __FILE__, __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"messageType" type:NSInteger32AttributeType],
		[Attribute name:@"out" type:NSBooleanAttributeType],
		[Attribute name:@"mentioned" type:NSBooleanAttributeType],
		[Attribute name:@"media_unread" type:NSBooleanAttributeType],
		[Attribute name:@"silent" type:NSBooleanAttributeType],
		[Attribute name:@"post" type:NSBooleanAttributeType],
		[Attribute name:@"from_scheduled" type:NSBooleanAttributeType],
		[Attribute name:@"legacy" type:NSBooleanAttributeType],
		[Attribute name:@"edit_hide" type:NSBooleanAttributeType],
		[Attribute name:@"pinned" type:NSBooleanAttributeType],
		[Attribute name:@"noforwards" type:NSBooleanAttributeType],
		[Attribute name:@"invert_media" type:NSBooleanAttributeType],
		[Attribute name:@"offline" type:NSBooleanAttributeType],
		[Attribute name:@"id" type:NSInteger32AttributeType],
		[Attribute name:@"from_boosts_applied" type:NSInteger32AttributeType],
		[Attribute name:@"via_bot_id" type:NSInteger64AttributeType],
		[Attribute name:@"via_business_bot_id" type:NSInteger64AttributeType],
		[Attribute name:@"date" type:NSDateAttributeType],
		[Attribute name:@"message" type:NSStringAttributeType],
		[Attribute name:@"views" type:NSInteger32AttributeType],
		[Attribute name:@"forwards" type:NSInteger32AttributeType],
		[Attribute name:@"edit_date" type:NSDateAttributeType],
		[Attribute name:@"post_author" type:NSStringAttributeType],
		[Attribute name:@"grouped_id" type:NSInteger64AttributeType],
		[Attribute name:@"ttl_period" type:NSInteger32AttributeType],
		[Attribute name:@"timeToLive" type:NSDateAttributeType],
		[Attribute name:@"quick_reply_shortcut_id" type:NSInteger32AttributeType],
		[Attribute name:@"effect" type:NSInteger64AttributeType],
	];
	
	NSArray *relations = @[ 
		[Relation name:@"from_id" entity:[TGPeer entity]],
		[Relation name:@"peer_id" entity:[TGPeer entity]],
		[Relation name:@"saved_peer_id" entity:[TGPeer entity]],
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
