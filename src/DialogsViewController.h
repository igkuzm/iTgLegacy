#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TGDialog.h"

@interface DialogsViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, 
 UISearchBarDelegate, UIActionSheetDelegate,
 UIScrollViewDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) TGDialog *selected;
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
