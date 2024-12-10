#import <UIKit/UIKit.h>
#include <stdint.h>
#include "../libtg/tg/dialogs.h"

@interface TGDialog : NSObject

@property (strong) NSString *title;
@property (strong) NSString *top_message;
@property (strong) UIImage *thumb;
@property (strong) NSDate *date;
@property uint64_t peerId;
@property uint32_t peerType;
@property uint64_t accessHash;
@property uint64_t photoId;
@property (strong) UIImage *photo;

-(id)initWithDialog:(const tg_dialog_t *)dialog;

@end

// vim:ft=objc
