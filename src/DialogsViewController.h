#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TGDialog.h"

@interface DialogsViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, 
 UISearchBarDelegate, UIActionSheetDelegate,
 UIScrollViewDelegate, DialogsSyncDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) TGDialog *selected;
@property (strong) NSString  *token;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) NSMutableArray *cache;
@property (strong) UISearchBar *searchBar;
@property (strong) NSOperationQueue *syncData;
@property (strong) NSOperationQueue *syncPhoto;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) UIRefreshControl *refreshControl;
@property long msg_hash;
@property int folder_id;
@property NSInteger currentIndex;
@property Boolean updatePhotos;
@end

// vim:ft=objc
