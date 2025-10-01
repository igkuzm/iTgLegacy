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

@end

// vim:ft=objc
