#include "CoreGraphics/CoreGraphics.h"
#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"
#include "TGDialog.h"

@interface TGMessage : NSObject
{
}
@property Boolean mine;
@property Boolean silent;
@property Boolean pinned;
@property Boolean isVoice;
@property Boolean isVideo;
@property Boolean isSticker;
@property Boolean isService;
@property uint32_t id;
@property uint32_t mediaType;
@property uint64_t photoId;
@property uint64_t photoAccessHash;
@property (strong) NSString *photoFileReference;
@property (strong) NSString *photoPath;
@property (strong) NSMutableArray *photoSizes;
@property CGSize photoCachedSize;
@property (strong) UIImage *photoStripped;
@property uint64_t docId;
@property uint64_t docSize;
@property uint64_t docAccessHash;
@property (strong) NSString *docThumbPath;
@property (strong) NSString *docFileReference;
@property (strong) NSString *docFileName;
@property tg_peer_t peer;
@property tg_peer_t from;
@property (strong) NSDate *date;
@property (strong) NSData *photoData;
@property (strong) UIImage *photo;
@property (strong) NSDate *photoDate;
@property (strong) NSString *message;
@property (strong) NSString *mimeType;
@property (strong) NSString *contactVcard;
@property (strong) NSString *contactPhoneNumber;
@property (strong) NSString *contactFirstName;
@property (strong) NSString *contactLastName;
@property uint64_t geoAccessHash;
@property double geoLat;
@property double geoLong;
@property uint32_t geoRadius;
@property uint64_t contactId;

- (id)initWithMessage:(const tg_message_t *)m dialog:(const TGDialog *)d;

@end
// vim:ft=objc
