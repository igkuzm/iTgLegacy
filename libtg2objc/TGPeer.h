#import <Foundation/Foundation.h>
#import "../libtg2/libtg.h"

typedef NS_ENUM(NSUInteger, TGPeerType) {
	kTGPeerTypeNil,
	kTGPeerTypeUser,
	kTGPeerTypeChat,
	kTGPeerTypeChannel,
};

@interface TGPeer : NSObject
{
}

@property TGPeerType peerType;
@property int id;

- (id)initWithTL:(const tl_t *)tl;
@end

// vim:ft=objc
