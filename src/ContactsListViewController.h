/**
 * File              : ContactsListViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 04.05.2021
 * Last Modified Date: 30.12.2024
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ContactsListViewController : UITableViewController 
<UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic)  UISearchBar *searchBar;
@property (strong,nonatomic) NSString *searchString;
@property (strong,nonatomic) AppDelegate *appDelegate;
@property (strong,nonatomic) NSArray *data;
@property (strong,nonatomic) NSMutableArray *loadedData;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *syncData;
@property (strong) NSOperationQueue *filterQueue;

@property Boolean showNavigationBar;

-(void)getContacts;
@end

// vim:ft=objc
