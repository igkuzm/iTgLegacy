/**
 * File              : PlaylistsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "ChatsViewController.h"
#include "ChatViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
//#import "ActionSheet.h"
#import "Base64/Base64.h"

@implementation ChatsItem
- (id)initWithDialog:(const tg_dialog_t *)d 
{
	if (self = [super init]) {
		if (d->name)
			self.title = [NSString stringWithUTF8String:d->name];
		
		if (d->top_message_text)
			self.top_message = 
				[NSString stringWithUTF8String:d->top_message_text];
		
		if (d->thumb){
			//buf_t b64 = buf_from_base64(d->thumb);
			NSData *thumbData = 
				[NSData dataFromBase64String:[NSString stringWithUTF8String:d->thumb]];
				//[NSData dataWithBytes:b64.data length:b64.size];
			if (thumbData.length > 0)
				self.thumb = [UIImage imageWithData:thumbData];
		}

		self.accessHash = d->access_hash;
		self.peerId = d->peer_id;
		self.peerType = d->peer_type;
	}
	return self;
}
@end

@implementation ChatsViewController

- (void)viewDidLoad {
	self.title = @"Чаты";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.syncData = [[NSOperationQueue alloc]init];
	self.loadedData = [NSMutableArray array];
	self.data = [NSArray array];
	self.msg_hash = 0;	
	self.folder_id = 0;

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
	}];	
}

-(void)refresh:(id)sender{
	[self reloadData];
}

static int get_dialogs_cb(void *d, const tg_dialog_t *dialog)
{
	ChatsViewController *self = d;
	ChatsItem *item = [[ChatsItem alloc]initWithDialog:dialog];
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self.loadedData addObject:item];
		[self filterData];
		[self.spinner stopAnimating];
		[self.refreshControl endRefreshing];
	});
	return 0;
}

//static int get_user_playlists(void *data, playlist_t *playlist, const char *error)
//{ 
	//PlaylistsViewController *self = (__bridge PlaylistsViewController *)data;
	//if (error){
		//NSLog(@"%s", error);
	//}

	//if (playlist){
		//Item *t = [[Item alloc]initWithPlaylist:playlist token:self.token];
		//dispatch_sync(dispatch_get_main_queue(), ^{
			//// Update your UI
			//[self.loadedData addObject:t];
			//[self filterData];
			//[self.spinner stopAnimating];
			//[self.refreshControl endRefreshing];
		//});
	//}
	//return 0;
//}


#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	ChatsItem *item = [self.data objectAtIndex:indexPath.item];
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
	
	self.selected = [self.data objectAtIndex:indexPath.item];
	//TrackListViewController *vc = [[TrackListViewController alloc]initWithParent:self.selected];
	//[self.navigationController pushViewController:vc animated:true];

	ChatViewController *vc = 
		[[ChatViewController alloc]
			initWithPeerId:self.selected.peerId 
			peerType:self.selected.peerType 
			accessHash:self.selected.accessHash];

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
