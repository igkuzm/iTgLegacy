#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "TGDialog.h"

@interface DialogViewCell : UITableViewCell
{
}
@property (strong) UILabel *title;
@property (strong) UILabel *message;
@property (strong) UILabel *time;
@property (strong) UIView *unreadView;
@property (strong) UILabel *unread;

-(void)setDialog:(TGDialog *)dialog;
@end
// vim:ft=objc
