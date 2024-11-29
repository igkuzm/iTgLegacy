#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatsItem : NSObject
@property tg_dialog_t dialog;
@property (strong) NSString *title;
@property (strong) NSString *top_message;
-(id)initWithDialog:(const tg_dialog_t *)dialog;
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
@property long msg_hash;
@property int folder_id;
@end

// vim:ft=objc
