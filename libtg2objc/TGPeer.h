#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"

typedef NS_ENUM(NSUInteger, TGPeerType) {
	kTGPeerTypeNil,
	kTGPeerTypeUser,
	kTGPeerTypeChat,
	kTGPeerTypeChannel,
};

@interface TGPeer : NSManagedObject
{
}

@property TGPeerType peerType;
@property int id;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGPeer *)newWithTL:(const tl_t *)tl;
+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
