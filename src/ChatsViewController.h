#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatsItem : NSObject
@property tl_chat_t *chat;
@property (strong) NSString *title;
-(id)initWithChat:(tl_chat_t *)chat;
@end

@interface ChatsViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
@property (strong) AppDelegate *appDelegate;
//@property (strong) Item *selected;
@property (strong) NSString  *token;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) NSOperationQueue *syncData;
@property (strong) UIActivityIndicatorView *spinner;
@end

// vim:ft=objc
