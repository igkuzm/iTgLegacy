#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
@interface InputToolBar : UIView
<UITextViewDelegate>
@property (strong) UITextView *textView;
@property (strong) NSString *placeholder;
@property (strong) UIBarButtonItem *sendButton;
@property (strong) UIBarButtonItem *recordButton;
@property (strong) UIBarButtonItem *attach;
@property (strong) UIButton *attachButton;
@property (strong) UIBarButtonItem *cancelButton;
@property (strong) UILabel *prgogressLabel;
@property (strong) UIProgressView *prgogressView;

@end

// vim:ft=objc
