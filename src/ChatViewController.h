#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "TGDialog.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>


@interface ChatViewController : UITableViewController
{
}
@property (strong) AppDelegate *appDelegate;
@property (strong) NSTimer *timer;
@property (strong) UITextField *textField;
@property (strong) TGDialog *dialog;
@property (strong) NSMutableArray *data;
@property (strong) NSMutableArray *cache;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *syncData;

-(ChatViewController *)initWithDialog:(TGDialog *)dialog;
@end
// vim:ft=objc
