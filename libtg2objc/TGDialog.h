#import <Foundation/Foundation.h>
#import "../libtg2/libtg.h"
#import "TGPeer.h"
#import "TGFolder.h"

typedef NS_ENUM(NSUInteger, TGDialogType) {
	kTGDialogTypeNil,
	kTGDialogTypeDialog,
	kTGDialogTypeDialogFolder,
};

@interface TGDialog : NSObject
{
}

@property TGDialogType dialogType;
@property Boolean pinned;
@property Boolean unread_mark;
@property Boolean view_forum_as_messages;
@property (strong) TGPeer *peer;
@property int top_message;
@property int read_inbox_max_id;
@property int read_outbox_max_id;
@property int unread_count;
@property int unread_mentions_count;
@property int unread_reactions_count;
//@property (strong) TGPeerNotifySettings *notify_settings;
@property int pts;
//@property (strong) TGDraftMessage *draft;
@property int ttl_period;

// dialog Folder
@property (strong) TGFolder *folder;
@property int unread_muted_peers_count;
@property int unread_unmuted_peers_count;
@property int unread_muted_messages_count;
@property int unread_unmuted_messages_count;

- (id)initWithTL:(const tl_t *)tl;
@end

// vim:ft=objc
