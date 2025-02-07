#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TextEditViewController.h"

@interface ConfigViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate, TextEditViewControllerDelegate, AuthorizationDelegate, UITextFieldDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) NSString *selectedKey;
@end

// vim:ft=objc
