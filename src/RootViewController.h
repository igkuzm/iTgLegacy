/**
 * File              : RootViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 10.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
//#import "YDFile.h"
#include "../libtg/libtg.h"

@interface RootViewController : UITableViewController 
<UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UIActionSheetDelegate>
{
	tg_t *tg;
}
//@property (strong) YDFile *file;
//@property (strong) YDFile *selected;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;
@property (strong) UIActivityIndicatorView *spinner;
@end
// vim:ft=objc
