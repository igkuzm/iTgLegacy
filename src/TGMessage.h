#import <UIKit/UIKit.h>
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"

@interface TGMessage : NSObject
{
}
@property Boolean silent;
@property Boolean pinned;
@property uint32_t id;
@property tg_peer_t peer;
@property tg_peer_t from;
@property (strong) NSDate *date;
@property (strong) UIImage *photo;
@property (strong) NSDate *photoDate;
@property (strong) NSString *message;

-(id)initWithMessage:(const tg_message_t *)message;

@end
// vim:ft=objc
