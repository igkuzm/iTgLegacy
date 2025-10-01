#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "TGPeer.h"

typedef NS_ENUM(NSUInteger, TGMessageType) {
	kTGMessageTypeNil,
	kTGMessageTypeEmplty,
	kTGMessageTypeMessage,
	kTGMessageTypeMessageService,
};

@interface TGMessage : NSManagedObject
{
}

@property TGMessageType messageType;
@property Boolean out;
@property Boolean mentioned;
@property Boolean media_unread;
@property Boolean silent;
@property Boolean post;
@property Boolean from_scheduled;
@property Boolean legacy;
@property Boolean edit_hide;
@property Boolean pinned;
@property Boolean noforwards;
@property Boolean invert_media;
@property Boolean offline;
@property int id;
@property (strong) TGPeer *from_id;
@property int from_boosts_applied;
@property (strong) TGPeer *peer_id;
@property (strong) TGPeer *saved_peer_id;
//@property TGMessageFwdHeader fwd_from;
@property long long via_bot_id;
@property long long via_business_bot_id;
//@property TGMessageReplyHeader reply_to;
@property (strong) NSDate *date;
@property (strong) NSString *message;
//@property TGMessageMedia media;
//@property TGReplyMarkup reply_markup;
//@property (strong) NSArray *entities; //TGMessageEntity
@property int views;
@property int forwards;
//@property TGMessageReplies replies;
@property (strong) NSDate *edit_date;
@property (strong) NSString *post_author;
@property long long grouped_id;
//@property TGMessageReactions reactions;
//@property (strong) NSArray *restriction_reason; //TGRestrictionReason
@property int ttl_period;
@property (strong) NSDate *timeToLive; // time to live
@property int quick_reply_shortcut_id;
@property long long effect;
//@property TGFactCheck factcheck;

// Service Message
// @property (strong) TGMessageAction *action;

- (id)initWithTL:(const tl_t *)tl;

+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
