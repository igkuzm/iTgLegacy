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

+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer
	TGFolder:(NSEntityDescription *)tgfolder
{
	NSLog(@"%s", __func__);

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
		[Relation name:@"peer" entity:tgpeer],
		[Relation name:@"folder" entity:tgfolder],
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}

+ (TGDialog *)newWithManagedObject:(NSManagedObject *)mo
{
	if (![mo.entity.name isEqualToString:NSStringFromClass(self)])
	{
		NSLog(@"%s: wrong entity name: %@", __func__, 
				mo.entity.name);
		
		return NULL;
	}

	TGDialog *obj = [[TGDialog alloc] init];
	obj.managedObject = mo;

	obj.dialogType = [[mo valueForKey:@"dialogType"]intValue];
	obj.pinned = [[mo valueForKey:@"pinned"]boolValue];
	obj.unread_mark = [[mo valueForKey:@"unread_mark"]boolValue];
	obj.view_forum_as_messages = [[mo valueForKey:@"view_forum_as_messages"]boolValue];
	obj.peer = [TGPeer newWithManagedObject:[mo valueForKey:@"peer"]];
	obj.top_message = [[mo valueForKey:@"top_message"]intValue];
	obj.read_inbox_max_id = [[mo valueForKey:@"read_inbox_max_id"]intValue];
	obj.read_outbox_max_id = [[mo valueForKey:@"read_outbox_max_id"]intValue];
	obj.unread_count = [[mo valueForKey:@"unread_count"]intValue];
	obj.unread_mentions_count = [[mo valueForKey:@"unread_mentions_count"]intValue];
	obj.unread_reactions_count = [[mo valueForKey:@"unread_reactions_count"]intValue];
	// notify_settings
	obj.pts = [[mo valueForKey:@"pts"]intValue];
	// draft
	obj.ttl_period = [[mo valueForKey:@"ttl_period"]intValue];
	obj.folder = [TGFolder newWithManagedObject:[mo valueForKey:@"folder"]];
	obj.unread_muted_peers_count = [[mo valueForKey:@"unread_muted_peers_count"]intValue];
	obj.unread_unmuted_peers_count = [[mo valueForKey:@"unread_unmuted_peers_count"]intValue];
	obj.unread_muted_messages_count = [[mo valueForKey:@"unread_muted_messages_count"]intValue];
	obj.unread_unmuted_messages_count = [[mo valueForKey:@"unread_unmuted_messages_count"]intValue];

	return obj;
}

- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context
{
	NSManagedObject *obj = [NSEntityDescription 
		insertNewObjectForEntityForName:NSStringFromClass(self.class) 
						 inManagedObjectContext:context];
	[obj setValue:[NSNumber numberWithInt:self.dialogType] 
				 forKey:@"dialogType"];
	[obj setValue:[NSNumber numberWithBool:self.pinned] 
				 forKey:@"pinned"];
	[obj setValue:[NSNumber numberWithBool:self.unread_mark] 
				 forKey:@"unread_mark"];
	[obj setValue:[NSNumber numberWithBool:self.view_forum_as_messages] 
				 forKey:@"view_forum_as_messages"];
	if (self.peer){
		NSManagedObject *rel = self.peer.managedObject;
		if (rel == nil){}
			rel = [self.peer newManagedObjectInContext:context];
		[obj setValue:self.peer.managedObject 
					 forKey:@"peer"];
	}
	[obj setValue:[NSNumber numberWithInt:self.top_message] 
				 forKey:@"top_message"];
	[obj setValue:[NSNumber numberWithInt:self.read_inbox_max_id] 
				 forKey:@"read_inbox_max_id"];
	[obj setValue:[NSNumber numberWithInt:self.read_outbox_max_id] 
				 forKey:@"read_outbox_max_id"];
	[obj setValue:[NSNumber numberWithInt:self.unread_count] 
				 forKey:@"unread_count"];
	[obj setValue:[NSNumber numberWithInt:self.unread_mentions_count] 
				 forKey:@"unread_mentions_count"];
	[obj setValue:[NSNumber numberWithInt:self.unread_reactions_count] 
				 forKey:@"unread_reactions_count"];
	[obj setValue:[NSNumber numberWithInt:self.pts] 
				 forKey:@"pts"];
	[obj setValue:[NSNumber numberWithInt:self.ttl_period] 
				 forKey:@"ttl_period"];
	if (self.folder){
		NSManagedObject *rel = self.folder.managedObject;
		if (rel == nil){}
			rel = [self.folder newManagedObjectInContext:context];
		[obj setValue:self.folder.managedObject 
					 forKey:@"peer"];
	}
	[obj setValue:[NSNumber numberWithInt:self.unread_muted_peers_count] 
				 forKey:@"unread_muted_peers_count"];
	[obj setValue:[NSNumber numberWithInt:self.unread_unmuted_peers_count] 
				 forKey:@"unread_unmuted_peers_count"];
	[obj setValue:[NSNumber numberWithInt:self.unread_muted_messages_count] 
				 forKey:@"unread_muted_messages_count"];
	[obj setValue:[NSNumber numberWithInt:self.unread_unmuted_messages_count] 
				 forKey:@"unread_unmuted_messages_count"];
	
	return obj;
}

@end

// vim:ft=objc
