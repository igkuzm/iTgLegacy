#import <UIKit/UIKit.h>
#include "../libtg/tg/dialogs.h"

@interface TGDialog : NSObject

@property (strong) NSString *title;
@property (strong) NSString *top_message;
@property (strong) UIImage *thumb;
@property (strong) NSDate *date;
@property long peerId;
@property int peerType;
@property long accessHash;

-(id)initWithDialog:(const tg_dialog_t *)dialog;

@end

// vim:ft=objc
