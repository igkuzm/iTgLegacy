#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"

@interface TGMessage : NSObject
{
}
@property Boolean silent;
@property Boolean pinned;
@property Boolean isVoice;
@property Boolean isVideo;
@property uint32_t id;
@property uint32_t mediaType;
@property uint64_t photoId;
@property uint64_t photoAccessHash;
@property (strong) NSString *photoFileReference;
@property tg_peer_t peer;
@property tg_peer_t from;
@property (strong) NSDate *date;
@property (strong) NSData *photoData;
@property (strong) UIImage *photo;
@property (strong) NSDate *photoDate;
@property (strong) NSString *message;
@property (strong) NSString *mimeType;

-(id)initWithMessage:(const tg_message_t *)message;

@end
// vim:ft=objc
