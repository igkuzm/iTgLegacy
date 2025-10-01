#import "TGMessage.h"
#import "NSString+libtg2.h"

@implementation TGMessage 

- (id)initWithTLMessage:(const tl_message_t *)m{
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
	
	return self;
}

- (id)initWithTLMessageService:(const tl_messageService_t *)m{
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

	return self;
}

- (id)initWithTLMessageEmpty:(const tl_messageEmpty_t *)m{
	self.messageType = kTGMessageTypeEmplty;
	self.id = m->id_;
	self.peer_id = [[TGPeer alloc]initWithTL:m->peer_id_];

	return self;
}

- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		if (tl->_id == id_message)
			return [self initWithTLMessage:(tl_message_t *)tl];
		
		if (tl->_id == id_messageService)
			return [self initWithTLMessageService:(tl_messageService_t *)tl];

		if (tl->_id == id_messageEmpty)
			return [self initWithTLMessageEmpty:(tl_messageEmpty_t *)tl];
	}
	
	return self;
}

+ (NSEntityDescription *)entity{

	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"TGMessage"];
	[entity setManagedObjectClassName:@"TGMessage"];
	
	NSMutableArray *properties = [NSMutableArray array];
	
	// create the attributes
	// Boolean
	for (NSString *name in @[
			@"out",
			@"mentioned",
			@"media_unread",
			@"silent",
			@"post",
			@"from_scheduled",
			@"legacy",
			@"edit_hide",
			@"pinned",
			@"noforwards",
			@"invert_media",
			@"offline",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:name];
		[attribute setAttributeType:NSBooleanAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int32
	for (NSString *name in @[
			@"messageType",
			@"id",
			@"from_boosts_applied",
			@"views",
			@"forwards",
			@"ttl_period",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:name];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int64
	for (NSString *name in @[
			@"via_bot_id",
			@"via_business_bot_id",
			@"grouped_id",
			@"effect",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:name];
		[attribute setAttributeType:NSInteger64AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}


	// NSString
	for (NSString *name in @[
			@"message",
			@"post_author",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:name];
		[attribute setAttributeType:NSStringAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}
	
	// NSDate
	for (NSString *name in @[
			@"date",
			@"edit_date",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:name];
		[attribute setAttributeType:NSDateAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// TGPeer
	for (NSString *name in @[
			@"from_id",
			@"peer_id",
			@"saved_peer_id",
	])
	{
		NSRelationshipDescription *relation = 
			[[NSRelationshipDescription alloc] init];
		[relation setName:name];
		[relation setDestinationEntity:[TGPeer entity]];
		[relation setMinCount:0];
		[relation setMaxCount:1];
		[relation setDeleteRule:NSNullifyDeleteRule];
		//[relation setDeleteRule:NSCascadeDeleteRule]; // for multy
		//[relation setInverseRelationship:]
		[properties addObject:relation];
	}

	[entity setProperties:properties];

	return entity;
}
@end

// vim:ft=objc
