/**
 * File              : DialogsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "DialogsViewController.h"
#include "CoreGraphics/CoreGraphics.h"
#include "TGDialog.h"
#include "../libtg/tg/files.h"
#include "ChatViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "Base64/Base64.h"
#import "DialogViewCell.h"
#include <unistd.h>

@implementation DialogsViewController

- (void)viewDidLoad {
	self.title = @"Чаты";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.appDelegate.authorizationDelegate = self;
	self.syncData = [[NSOperationQueue alloc]init];
	self.loadedData = [NSMutableArray array];
	self.cache = [NSMutableArray array];
	self.data = [NSArray array];
	self.msg_hash = 0;	
	self.folder_id = 0;
	self.currentIndex = 0;

	// spinner
	self.spinner = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.spinner.center = 
		CGPointMake(
				self.navigationController.navigationBar.bounds.size.width - 60, 
				self.navigationController.navigationBar.bounds.size.height/2);
	[self.navigationController.navigationBar addSubview:self.spinner]; 

	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl 
		setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl 
		addTarget:self 
		action:@selector(refresh:) 
		forControlEvents:UIControlEventValueChanged];

	// edit button
	self.navigationItem.leftBarButtonItem = self.editButtonItem;

	// compose button
	UIBarButtonItem *compose = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
		target:self action:nil];
	self.navigationItem.rightBarButtonItem = compose;

	// hide searchbar
  [self.tableView setContentOffset:CGPointMake(0, 44)];
	
	// load data
	[self reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		[self.navigationController setToolbarHidden: YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.syncData cancelAllOperations];
}

-(void)editing:(BOOL)editing{
	[self setEditing:editing];
}

-(void)refresh:(id)sender{
	[self reloadData];
}

#pragma mark <Data functions>
-(void)filterData{
	[self.loadedData sortedArrayUsingComparator:
		^NSComparisonResult(id obj1, id obj2)
	{
    TGDialog *d1 = (TGDialog *)obj1;
    TGDialog *d2 = (TGDialog *)obj2;
             
    return [d1.date compare:d2.date];            
	}];

	if (self.searchBar.text && self.searchBar.text.length > 0)
		self.data = [self.loadedData filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat:@"self.title contains[c] %@", self.searchBar.text]];
	else
		self.data = self.loadedData;

	[self.tableView reloadData];
}

-(void)reloadData{
	if (!self.appDelegate.tg)
		return;
	
	[self.syncData cancelAllOperations];
	
	// animate spinner
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	// get dialogs
	[self getDialogsCached:YES];
}

-(void)getDialogsCached:(Boolean)update{
	[self.syncData addOperationWithBlock:^{
		
		[self.cache removeAllObjects];
		
		tg_get_dialogs_from_database(
				self.appDelegate.tg, 
				self, 
				get_dialogs_cb);
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.loadedData removeAllObjects];
			[self.loadedData addObjectsFromArray:self.cache];
			[self filterData];
			[self.refreshControl endRefreshing];
			[self.spinner stopAnimating];
			if (update)
				[self getDialogsFrom:[NSDate date]];
		});
	}];
}

-(void)getDialogsFrom:(NSDate *)date{
	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
		return;

	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];
	
	[self.cache removeAllObjects];
	
	[self.syncData addOperationWithBlock:^{
		sleep(1); //for FLOOD_WAIT
		tg_get_dialogs(
				self.appDelegate.tg, 
				20, 
				[date timeIntervalSince1970], 
				NULL, 
				NULL, 
				self, 
				NULL,
				on_done);
	}];
}

#pragma mark <LibTG functions> 
static int get_dialogs_cb(void *d, const tg_dialog_t *dialog)
{
	DialogsViewController *self = d;
	TGDialog *item = [[TGDialog alloc]initWithDialog:dialog];
	char *photo = peer_photo_file_from_database(
			self.appDelegate.tg, 
			item.peerId, item.photoId);
	if (photo){
		NSData *data = [NSData dataFromBase64String:
			[NSString stringWithUTF8String:photo]];
		if (data)
			item.photo = [UIImage imageWithData:data];
	}
	[self.cache addObject:item];
	return 0;
}

static void on_done(void *d){
	DialogsViewController *self = d;
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self.refreshControl endRefreshing];
		[self.spinner stopAnimating];
		[self getDialogsCached:NO];
	});
}

#pragma mark <UITableView DataSource>
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 58;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	TGDialog *dialog = [self.data objectAtIndex:indexPath.item];
	DialogViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[DialogViewCell alloc]init];
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}

	[cell setDialog:dialog];
	
	return cell;
}

#pragma mark <UITableView Delegate>
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[self.searchBar resignFirstResponder];
	[self.syncData cancelAllOperations];
	[self.spinner stopAnimating];
	
	TGDialog *dialog = [self.data objectAtIndex:indexPath.item];
	self.selected = dialog;
	self.currentIndex = indexPath.item;
	
	ChatViewController *vc = [[ChatViewController alloc]init];
	vc.hidesBottomBarWhenPushed = YES;
	vc.dialog = dialog;
	vc.spinner = self.spinner;
	[self.navigationController pushViewController:vc animated:TRUE];
		
		// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return true;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete){
		self.selected = [self.data objectAtIndex:indexPath.item];
			UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"Удалить диалог?" 
				message:self.selected.title 
				delegate:self 
				cancelButtonTitle:@"Отмена" 
				otherButtonTitles:@"Удалить", nil];
			[alert show];
	}
}

#pragma mark <SCROLLVIEW DELEGATE>

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	float bottomEdge = 
		scrollView.contentOffset.y + scrollView.frame.size.height;
	if (bottomEdge >= scrollView.contentSize.height) {
		// we are at the end
		// append data to array
		TGDialog *dialog = 
			[self.loadedData lastObject];
		if (dialog)
			[self getDialogsFrom:dialog.date];
	} else if (scrollView.contentOffset.y == 0){
		[self getDialogsFrom:[NSDate date]];
	} 	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

}

#pragma mark <UISearchBar functions>

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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    [self.searchBar resignFirstResponder];
	
		// load data
		[self filterData];
}

#pragma mark <Authorization Delegate>
-(void)authorizedAs:(tl_user_t *)user{
	[self reloadData];
}

#pragma mark <AllertDelegate functions>
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
