#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "TGMessage.h"

@interface ChatViewCell : UITableViewCell
{
}
@property (strong) TGMessage *message;
@property (strong) UITextView *text;
@property (strong) UILabel *time;
@property (strong) UIImageView *avatarView;
@property (strong) UIImageView *photoView;
@property float photoHeight;
@property float textHeight;

-(void)setMessage:(TGMessage *)message;
@end
// vim:ft=objc
