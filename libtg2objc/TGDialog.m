#import "TGDialog.h"
#import "NSString+libtg2.h"

@implementation TGDialog 

- (id)initWithTLDialog:(const tl_dialog_t *)d{
	self.pinned = d->pinned_;
	self.unread_mark = d->unread_mark_;
	self.view_forum_as_messages = d->view_forum_as_messages_;
	self.peer = [[TGPeer alloc] initWithTL:d->peer_];
	self.top_message =  d->top_message_;
	self.read_inbox_max_id = d->read_inbox_max_id_;
	self.read_outbox_max_id = d->read_inbox_max_id_;
	self.unread_count = d->unread_count_;
	self.unread_mentions_count = d->unread_mentions_count_;
	self.unread_reactions_count = d->unread_reactions_count_;
	//self.notify_settings;
	self.pts = d->pts_;
	//self.draft;
	self.ttl_period =  d->ttl_period_;
	
	return self;
}

- (id)initWithTLDialogFolder:(const tl_dialogFolder_t *)d{
	self.folder = [[TGFolder alloc]initWithTL:d->folder_];
	self.pinned = d->pinned_;
	self.peer = [[TGPeer alloc] initWithTL:d->peer_];
	self.top_message =  d->top_message_;
	self.unread_muted_peers_count = d->unread_muted_peers_count_;
	self.unread_unmuted_peers_count = d->unread_unmuted_peers_count_;
	self.unread_muted_messages_count = d->unread_muted_messages_count_;
	self.unread_unmuted_messages_count = d->unread_unmuted_messages_count_;
	
	return self;
}

- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		
		if (tl->_id == id_dialog)
			return [self initWithTLDialog:(tl_dialog_t *)tl];
		
		if (tl->_id == id_dialogFolder)
			return [self initWithTLDialogFolder:(tl_dialogFolder_t *)tl];
	}
	
	return self;
}


+ (NSEntityDescription *)entity{

	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"TGDialog"];
	[entity setManagedObjectClassName:@"TGDialog"];
	
	NSMutableArray *properties = [NSMutableArray array];
	
	// create the attributes
	// Boolean
	for (NSString *attributeDescriptionName in @[
			@"pinned",
			@"unread_mark",
			@"view_forum_as_messages",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSBooleanAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int32
	for (NSString *attributeDescriptionName in @[
			@"dialogType",
			@"top_message",
			@"read_inbox_max_id",
			@"read_outbox_max_id",
			@"unread_count",
			@"unread_mentions_count",
			@"unread_reactions_count",
			@"pts",
			@"ttl_period",
			@"unread_muted_peers_count",
			@"unread_unmuted_peers_count",
			@"unread_muted_messages_count",
			@"unread_unmuted_messages_count",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// TGPeer
	{
		NSRelationshipDescription *relation = 
			[[NSRelationshipDescription alloc] init];
		[relation setName:@"peer"];
		[relation setDestinationEntity:[TGPeer entity]];
		[relation setMinCount:0];
		[relation setMaxCount:1];
		[relation setDeleteRule:NSNullifyDeleteRule];
		[properties addObject:relation];
	}

	// TGPeer
	{
		NSRelationshipDescription *relation = 
			[[NSRelationshipDescription alloc] init];
		[relation setName:@"folder"];
		[relation setDestinationEntity:[TGFolder entity]];
		[relation setMinCount:0];
		[relation setMaxCount:1];
		[relation setDeleteRule:NSNullifyDeleteRule];
		[properties addObject:relation];
	}

	[entity setProperties:properties];

	return entity;
}

@end

// vim:ft=objc
