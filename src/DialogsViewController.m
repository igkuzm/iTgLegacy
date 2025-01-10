/**
 * File              : DialogsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "DialogsViewController.h"
#include "RootViewController.h"
#include "CoreGraphics/CoreGraphics.h"
#include "TGDialog.h"
#include "../libtg/tg/queue.h"
#include "../libtg/tg/files.h"
#include "ChatViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "Base64/Base64.h"
#import "DialogViewCell.h"
#include <unistd.h>
#import "UIImage+Utils/UIImage+Utils.h"
#import "TSMessages/TSMessage.h"

@implementation DialogsViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.appDelegate.authorizationDelegate = self;
	self.appDelegate.appActivityDelegate = self;
	self.appDelegate.dialogsViewController = self;

	self.syncData = [[NSOperationQueue alloc]init];
	self.syncData.maxConcurrentOperationCount = 1;
	self.loadedData = [NSMutableArray array];
	self.cache = [NSMutableArray array];
	self.data = [NSArray array];
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
	self.searchBar.placeholder = @"Search:";

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
		target:self action:@selector(composeButtonPushed:)];
	self.navigationItem.rightBarButtonItem = compose;

	// hide searchbar
  [self.tableView setContentOffset:CGPointMake(0, 44)];
	

	// timer
	self.timer = [NSTimer scheduledTimerWithTimeInterval:60 
			target:self selector:@selector(timer:) 
				userInfo:nil repeats:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		[self.navigationController setToolbarHidden: YES];
		
		// load data
		[self reloadData];
		
		UINavigationController *nc =
				[((RootViewController *)self.appDelegate.rootViewController).viewControllers objectAtIndex:1]; 
		if (nc){
			nc.tabBarItem.badgeValue = 0;
		}
}

- (void)viewWillDisappear:(BOOL)animated {
	if (self.timer)
		[self.timer fire];
	//[self cancelAll];
	[super viewWillDisappear:animated];
}

-(void)editing:(BOOL)editing{
	[self setEditing:editing];
}

-(void)refresh:(id)sender{
	[self reloadData];
}

-(void)composeButtonPushed:(id)sender{
	[TSMessage 
		showNotificationWithTitle:@"title" 
										 subtitle:@"subTitle"
										     type:TSMessageNotificationTypeMessage
	];
}

-(void)timer:(id)sender{
	// do timer funct
	[self getDialogsFrom:[NSDate date]];
}

- (void)cancelAll{
	[self.spinner stopAnimating];
	if (self.refreshControl)
		[self.refreshControl endRefreshing];
	if (self.appDelegate.tg)
		tg_queue_cancell_all(self.appDelegate.tg);
	[self.syncData cancelAllOperations];
}

#pragma mark <Data functions>
-(void)filterData{
	NSArray *array = [self.loadedData sortedArrayUsingComparator:
		^NSComparisonResult(id obj1, id obj2)
	{
		TGDialog *d1 = (TGDialog *)obj1;
		TGDialog *d2 = (TGDialog *)obj2;
		
		if (d1.pinned && !d2.pinned)
			return NSOrderedAscending;
		
		if (d2.pinned && !d1.pinned)
			return NSOrderedDescending;
						 
		return [d2.date compare:d1.date]; // last date is on top           
	}];

	if (self.searchBar.text && self.searchBar.text.length > 0)
		self.data = [array filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat:@"self.title contains[c] %@", self.searchBar.text]];
	else
		self.data = array;

	[self.tableView reloadData];
}

-(void)reloadData{
	[self cancelAll];

	if (!self.appDelegate.tg)
		return;
	
	// animate spinner
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	// get dialogs
	[self getDialogsCached:YES];
}

-(void)updatePhoto {
	if (self.appDelegate.isOnLineAndAuthorized){
		for (TGDialog *d in self.loadedData){
			if (!d.photo){
				tg_peer_t peer = {
						d.peerType,
						d.peerId,
						d.accessHash
				};
				char *photo = tg_get_peer_photo_file(
							self.appDelegate.tg, 
							&peer, 
							false, 
							d.photoId); 
				if (photo){
					NSData *data = [NSData 
						dataFromBase64String:
							[NSString stringWithUTF8String:photo]];
					if (data){
						[data writeToFile:d.photoPath atomically:YES];
						d.photo = [UIImage imageWithData:data];
					}
				} // end if (photo)
			} // end if (!d.photo)
		} // end for TGDialog
	}
}

-(void)getDialogsCached:(Boolean)update{
	
	// do operation in thread
	[self.syncData addOperationWithBlock:^{
		
		tg_get_dialogs_from_database(
				self.appDelegate.tg, 
				self, 
				get_dialogs_cb);

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self filterData];
			[self.refreshControl endRefreshing];
			[self.spinner stopAnimating];
			//[self.appDelegate showMessage:@"getDialogsCached done!"];
			if (update)
				[self getDialogsFrom:[NSDate date]];
		});
	}];
}

-(void)getDialogsFrom:(NSDate *)date{
	//[self cancelAll];
	if (self.appDelegate.isOnLineAndAuthorized){
	
		if (!self.refreshControl.refreshing)
			[self.spinner startAnimating];

		[self.syncData addOperationWithBlock:^{
				pthread_t p = tg_get_dialogs_async(
						self.appDelegate.tg, 
						20, 
						[date timeIntervalSince1970], 
						NULL, 
						NULL, 
						self, 
						get_dialogs_cb,
						 NULL);

				pthread_join(p, NULL);
				dispatch_sync(dispatch_get_main_queue(), ^{
					[self.refreshControl endRefreshing];
					[self.spinner stopAnimating];
					[self filterData];

				});
				// update photo
				[self updatePhoto];
		}];
	}
}

#pragma mark <LibTG functions> 
static int get_dialogs_cb(void *d, const tg_dialog_t *dialog)
{
	if (!dialog)
		return 0;

	// drop hidden dialogs
	if (dialog->folder_id == 1)
		return 0;
		
	DialogsViewController *self = d;
	//[self.appDelegate showMessage:@"ADD DIALOG!"];
	TGDialog *current = NULL;
	for (TGDialog *item in self.loadedData){
		if (item.peerId == dialog->peer_id){
			current = item;
			break;
		}
	}
	if (!current){
		current = 
			[[TGDialog alloc]initWithDialog:dialog tg:self.appDelegate.tg syncData:self.syncData];
		[self.loadedData addObject:current];
	} else {
		current.accessHash = dialog->access_hash;
		current.photoId = dialog->photo_id;
		current.date = 
			[NSDate dateWithTimeIntervalSince1970:dialog->top_message_date];
		if (dialog->top_message_text)
			current.top_message = 
				[NSString stringWithUTF8String:dialog->top_message_text];
		else 
			current.top_message = @"";
		
		if (dialog->name)
			current.title =
				[NSString stringWithUTF8String:dialog->name];
	}

	return 0;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	TGDialog *dialog = [self.data objectAtIndex:indexPath.item];
	if (dialog.pinned)
		cell.backgroundColor = [UIColor lightGrayColor];
}

#pragma mark <UITableView Delegate>
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

	[self.searchBar resignFirstResponder];
	//[self cancelAll];
	
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
		if (dialog && dialog.date)
			[self getDialogsFrom:dialog.date];
		else {
			if (self.loadedData.count > 1){
				dialog = [self.loadedData objectAtIndex:self.loadedData.count - 2];
				if (dialog)
					[self getDialogsFrom:dialog.date];
			}
		}
	} else if (scrollView.contentOffset.y == 0){
		[self getDialogsFrom:[NSDate date]];
	} else {
		NSIndexPath *indexPath = 
			[[self.tableView indexPathsForVisibleRows]objectAtIndex:0];
		TGDialog *dialog = 
			[self.data objectAtIndex:indexPath.item];
		if (dialog)
			[self getDialogsFrom:dialog.date];
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
-(void)tgLibLoaded{
	[self reloadData];
}

-(void)authorizedAs:(tl_user_t *)user{
	[self getDialogsFrom:[NSDate date]];
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
#pragma mark <AppActivity Delegate>
-(void)willResignActive {
	if (self.timer)
		[self.timer fire];
	//[self cancelAll];
}

@end
// vim:ft=objc
