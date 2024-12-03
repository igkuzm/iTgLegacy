/**
 * File              : PlaylistsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "ChatsViewController.h"
#include "TGDialog.h"
#include "ChatViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
//#import "ActionSheet.h"

@implementation ChatsViewController

- (void)viewDidLoad {
	self.title = @"Чаты";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.syncData = [[NSOperationQueue alloc]init];
	self.loadedData = [NSMutableArray array];
	self.data = [NSArray array];
	self.msg_hash = 0;	
	self.folder_id = 0;

	// spinner
	self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	[self.view addSubview:self.spinner]; 

	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	// edit button
	self.navigationItem.rightBarButtonItem = self.editButtonItem;
		
	// load data
	[self reloadData];
}

-(void)editing:(BOOL)editing{
	[self setEditing:editing];
	if (self.editing){

		[self.navigationItem setHidesBackButton:YES animated:YES];
	}
	else
		[self.navigationItem setHidesBackButton:NO animated:YES];
}

//hide searchbar by default
- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView setContentOffset:CGPointMake(0, 44)];
}
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    [self.searchBar resignFirstResponder];
	
		// load data
		[self reloadData];
}

-(void)filterData{
	if (self.searchBar.text && self.searchBar.text.length > 0)
		self.data = [self.loadedData filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat:@"self.title contains[c] %@", self.searchBar.text]];
	else
		self.data = self.loadedData;

	[self.tableView reloadData];
}

-(void)reloadData{
	// stop all sync
	[self.syncData cancelAllOperations];

	if (!self.appDelegate.tg)
		return;
	
	// animate spinner
	CGRect rect = self.view.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	// get dialogs
	[self.loadedData removeAllObjects];
	[self.tableView reloadData];
	[self.syncData addOperationWithBlock:^{
		tg_get_dialogs_from_database(
				self.appDelegate.tg, 
				self, 
				get_dialogs_cb);
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.spinner stopAnimating];
			[self.refreshControl endRefreshing];
			[self filterData];
		});
	}];	
}

-(void)refresh:(id)sender{
	[self reloadData];
}

static int get_dialogs_cb(void *d, const tg_dialog_t *dialog)
{
	ChatsViewController *self = d;
	TGDialog *item = [[TGDialog alloc]initWithDialog:dialog];
		[self.loadedData addObject:item];
	return 0;
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TGDialog *item = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[UITableViewCell alloc]
		initWithStyle: UITableViewCellStyleSubtitle 
		reuseIdentifier: @"cell"];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	//item.imageView = cell.imageView;
	[cell.textLabel setText:item.title];
	[cell.detailTextLabel setText:item.top_message];	
	[cell.imageView setImage:item.thumb];
	//if (item.coverImage)
		//[cell.imageView setImage:item.coverImage];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	TGDialog *dialog = [self.data objectAtIndex:indexPath.item];
	self.selected = dialog;
	//TrackListViewController *vc = [[TrackListViewController alloc]initWithParent:self.selected];
	//[self.navigationController pushViewController:vc animated:true];
	
	ChatViewController *vc = [[ChatViewController alloc]init];
	vc.dialog = dialog;
	[self.navigationController pushViewController:vc animated:TRUE];
		
		// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	//UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
	//[spinner startAnimating];
	//ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:YES onDone:^{
		//[spinner stopAnimating];
	//}];
	//[as showFromTabBar:self.tabBarController.tabBar];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//if (editingStyle == UITableViewCellEditingStyleDelete){
		//self.selected = [self.data objectAtIndex:indexPath.item];
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить плейлист?" 
				//message:self.selected.title 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];
	//}
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[searchBar resignFirstResponder];
}

#pragma mark <ALERT DELEGATE FUNCTIONS>
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//if (buttonIndex == 1){
		//c_yandex_music_remove_playlist(
				//[self.token UTF8String], 
				//self.selected.uid, 
				//self.selected.kind, 
				//NULL, NULL);
		//[self.loadedData removeObject:self.selected];
		//[self filterData];
	//}
//}
@end
// vim:ft=objc
