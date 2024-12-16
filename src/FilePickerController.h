/**
 * File              : FilePickerController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 10.08.2023
 * Last Modified Date: 11.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>

@interface FileObj : NSObject
@property (strong) NSString *name;
@property NSInteger type;
@end

@interface FilePickerController : UITableViewController 
<UISearchBarDelegate, UIAlertViewDelegate, UIActionSheetDelegate>
{
}
@property BOOL new;
@property (strong) FileObj *selected;
@property (strong) NSString *path;
@property (strong) NSArray *data;
@property (strong) NSMutableArray *loadedData;
@property (strong) UISearchBar *searchBar;

- (id)initWithPath:(NSString *)path isNew:(BOOL)new;
@end

// vim:ft=objc
