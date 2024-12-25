#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#include <stdint.h>
#include "../libtg/tg/dialogs.h"

@interface TGDialog : NSObject

@property (strong) NSString *title;
@property uint32_t topMessageId;
@property (strong) NSString *top_message;
@property (strong) UIImage *thumb;
@property (strong) NSDate *date;
@property uint64_t peerId;
@property uint32_t peerType;
@property uint64_t accessHash;
@property uint64_t photoId;
@property (strong) UIImage *photo;
@property (strong) NSString *photoPath;
@property int unread_count;
@property (strong) UIImageView *imageView;
@property (strong) NSOperationQueue *syncData;

-(id)initWithDialog:(const tg_dialog_t *)dialog tg:(tg_t *)tg;

@end

// vim:ft=objc
