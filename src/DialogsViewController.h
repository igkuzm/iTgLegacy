#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import "TGDialog.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface DialogsViewController : UITableViewController
<UITableViewDelegate, UITableViewDataSource, 
 UISearchBarDelegate, UIActionSheetDelegate,
 UIScrollViewDelegate, AuthorizationDelegate,
 AppActivityDelegate, ABPeoplePickerNavigationControllerDelegate>
@property (strong) AppDelegate *appDelegate;
@property (strong) NSTimer *timer;
@property (strong) TGDialog *selected;
@property (strong) NSString  *token;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) NSMutableArray *cache;
@property (strong) UISearchBar *searchBar;
@property (strong) NSOperationQueue *syncData;
@property (strong) NSOperationQueue *download;
@property (strong) NSOperationQueue *filterQueue;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) UIRefreshControl *refreshControl;
@property NSInteger currentIndex;
@property Boolean updatePhotos;
@property Boolean showNavigationBar;
@property Boolean isHidden;

-(void)getDialogsFrom:(NSDate *)date;
@end

// vim:ft=objc
