#import "TGDialog.h"
#import "NSString+libtg2.h"
#import "CoreDataTools.h"

@implementation TGDialog 

- (void)updateWithTLDialog:(const tl_dialog_t *)d{
	self.pinned = d->pinned_;
	self.unread_mark = d->unread_mark_;
	self.view_forum_as_messages = d->view_forum_as_messages_;
	self.peer = [TGPeer newWithTL:d->peer_];
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
}

- (void)updateWithTLDialogFolder:(const tl_dialogFolder_t *)d{
	self.folder = [TGFolder newWithTL:d->folder_];
	self.pinned = d->pinned_;
	self.peer = [TGPeer newWithTL:d->peer_];
	self.top_message =  d->top_message_;
	self.unread_muted_peers_count = d->unread_muted_peers_count_;
	self.unread_unmuted_peers_count = d->unread_unmuted_peers_count_;
	self.unread_muted_messages_count = d->unread_muted_messages_count_;
	self.unread_unmuted_messages_count = d->unread_unmuted_messages_count_;
}

- (void)updateWithTL:(const tl_t *)tl{
		
	if (tl->_id == id_dialog){
		[self updateWithTLDialog:(tl_dialog_t *)tl];
		return;
	}
	
	if (tl->_id == id_dialogFolder){
		[self updateWithTLDialogFolder:(tl_dialogFolder_t *)tl];
		return;
	}
	NSLog(@"tl is not dialog type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGDialog *)newWithTL:(const tl_t *)tl{
	TGDialog *obj = [[TGDialog alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s: %s", __FILE__, __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"dialogType" type:NSInteger32AttributeType],
		[Attribute name:@"pinned" type:NSBooleanAttributeType],
		[Attribute name:@"unread_mark" type:NSBooleanAttributeType],
		[Attribute name:@"view_forum_as_messages" type:NSBooleanAttributeType],
		[Attribute name:@"top_message" type:NSInteger32AttributeType],
		[Attribute name:@"read_inbox_max_id" type:NSInteger32AttributeType],
		[Attribute name:@"read_outbox_max_id" type:NSInteger32AttributeType],
		[Attribute name:@"unread_count" type:NSInteger32AttributeType],
		[Attribute name:@"unread_mentions_count" type:NSInteger32AttributeType],
		[Attribute name:@"unread_reactions_count" type:NSInteger32AttributeType],
		[Attribute name:@"pts" type:NSInteger32AttributeType],
		[Attribute name:@"ttl_period" type:NSInteger32AttributeType],
		[Attribute name:@"unread_muted_peers_count" type:NSInteger32AttributeType],
		[Attribute name:@"unread_unmuted_peers_count" type:NSInteger32AttributeType],
		[Attribute name:@"unread_muted_messages_count" type:NSInteger32AttributeType],
		[Attribute name:@"unread_unmuted_messages_count" type:NSInteger32AttributeType],
	];
	
	NSArray *relations = @[ 
		[Relation name:@"peer" entity:[TGPeer entity]],
		[Relation name:@"folder" entity:[TGFolder entity]],
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
