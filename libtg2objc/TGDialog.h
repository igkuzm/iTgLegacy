#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "TGPeer.h"
#import "TGFolder.h"

@interface TGDialog : NSObject
{
}

@property int dialogType;
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

@property (strong) NSManagedObject *managedObject;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGDialog *)newWithTL:(const tl_t *)tl;
+ (TGDialog *)newWithManagedObject:(NSManagedObject *)object;
- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription *)
	entityWithTGPeer:(NSEntityDescription *)tgpeer
	TGFolder:(NSEntityDescription *)tgfolder;
@end

// vim:ft=objc
