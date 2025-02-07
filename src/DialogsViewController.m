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
#include "../libtg/tg/user.h"
#include "ChatViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "Base64/Base64.h"
#import "DialogViewCell.h"
#include <unistd.h>
#import "UIImage+Utils/UIImage+Utils.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <QuartzCore/QuartzCore.h>

@interface  DialogsViewController()
{
}
@property uint64_t hash;
@end

@implementation DialogsViewController
@synthesize hash = _hash;

- (void)viewDidLoad {
	[super viewDidLoad];

	self.hash = 0;
	
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	self.appDelegate.authorizationDelegate = self;
	self.appDelegate.appActivityDelegate = self;
	self.appDelegate.dialogsViewController = self;

	self.syncData = [[NSOperationQueue alloc]init];
	self.syncData.maxConcurrentOperationCount = 1;
	
	self.download = [[NSOperationQueue alloc]init];
	
  self.filterQueue = [[NSOperationQueue alloc]init];
	self.filterQueue.maxConcurrentOperationCount = 1;
	
	self.loadedData = [NSMutableArray array];
	self.cache = [NSMutableArray array];
	self.data = [NSArray array];
	self.currentIndex = 0;

	self.showNavigationBar = YES;

	// spinner
	self.spinner = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	self.spinner.center = 
		CGPointMake(
				self.navigationController.navigationBar.bounds.size.width - 60, 
				self.navigationController.navigationBar.bounds.size.height/2);
	self.spinner.autoresizingMask = 
		UIViewAutoresizingFlexibleLeftMargin|
		UIViewAutoresizingFlexibleTopMargin |
		UIViewAutoresizingFlexibleBottomMargin;
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
	//self.navigationItem.leftBarButtonItem = self.editButtonItem;
	
	// hidden button
	UIBarButtonItem *hidden = [[UIBarButtonItem alloc]
		initWithTitle:@"Archive" 
		style:UIBarButtonItemStyleBordered 
	  target:self 
		action:@selector(onHidden:)]; 
	self.navigationItem.leftBarButtonItem = hidden;

	// compose button
	UIBarButtonItem *compose = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
		target:self action:@selector(composeButtonPushed:)];
	self.navigationItem.rightBarButtonItem = compose;

	// hide searchbar
  [self.tableView setContentOffset:CGPointMake(0, 44)];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
		[self.navigationController setToolbarHidden: YES];


		// timer
		NSInteger sec = [NSUserDefaults.standardUserDefaults 
			integerForKey:@"chatUpdateInterval"];
		if (sec < 5 || sec > 120)
			sec = 120;
		self.timer = [NSTimer scheduledTimerWithTimeInterval:sec 
				target:self selector:@selector(timer:) 
					userInfo:nil repeats:YES];

		
		// load data
		[self reloadData];

		// navigationBar
		if (self.showNavigationBar)
			[self.navigationController setNavigationBarHidden:NO animated:YES];
		else
			[self.navigationController setNavigationBarHidden:YES animated:YES];
		
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

-(void)onHidden:(id)sender{
	UIBarButtonItem *hidden = sender;
	self.isHidden = !self.isHidden;
	if (self.isHidden)
		hidden.style = UIBarButtonItemStyleDone;
	else 
		hidden.style = UIBarButtonItemStyleBordered;
	[self filterData];
}

-(void)refresh:(id)sender{
	[self cancelAll];
	[self reloadData];
}

-(void)composeButtonPushed:(id)sender{
	ABPeoplePickerNavigationController *picker =
				[[ABPeoplePickerNavigationController alloc] init];
	picker.peoplePickerDelegate = self;
	[self presentViewController:picker animated:TRUE completion:nil];
}

-(void)timer:(id)sender{
	// do timer funct
	[self getDialogsFrom:[NSDate date]];
}

- (void)cancelAll{
	[self.spinner stopAnimating];
	if (self.refreshControl)
		[self.refreshControl endRefreshing];
	[self.syncData cancelAllOperations];
	//for (TGDialog *dialog in self.loadedData){
		//[dialog.syncData cancelAllOperations];
	//}
	// unlock mutex
	if (self.appDelegate.tg){
		pthread_mutex_unlock(&self.appDelegate.tg->send_query);
		tg_new_session(self.appDelegate.tg);
	}
}

#pragma mark <Data functions>
-(void)filterData{
	[self.filterQueue cancelAllOperations];

	[self.filterQueue addOperationWithBlock:^{
		NSPredicate *predicate = [NSPredicate predicateWithBlock:
				^BOOL(id evaluatedObject, NSDictionary *bindings)
		{
			TGDialog *dialog = evaluatedObject;
			if (self.isHidden){
				if (dialog.hidden)
					return YES;
				else
					return NO;

			} else {
				if (dialog.hidden)
					return NO;
				else
					return YES;
			}
		}];

		NSArray *src = 
			[self.loadedData filteredArrayUsingPredicate:predicate];

		NSArray *array = [src sortedArrayUsingComparator:
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

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.tableView reloadDataAnimated:YES];
		});
	}];
}

-(void)reloadData{
	[self.spinner stopAnimating];
	[self cancelAll];

	if (!self.appDelegate.tg)
		return;
	
	// get dialogs
	[self getDialogsCached:YES];
}

-(void)getDialogsCached:(Boolean)update{
	
	// do operation in thread
	[self.syncData addOperationWithBlock:^{
		
		tg_get_dialogs_from_database(
				self.appDelegate.tg, 
				(__bridge void *)self, 
				get_dialogs_cb);

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self filterData];
			[self.refreshControl endRefreshing];
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
				tg_get_dialogs(
						self.appDelegate.tg, 
						20, 
						[date timeIntervalSince1970], 
						//&_hash, 
						0, 
						NULL, 
						(__bridge void *)self, 
						get_dialogs_cb);

				dispatch_sync(dispatch_get_main_queue(), ^{
					//[self.appDelegate showMessage:@"done"];
					[self.refreshControl endRefreshing];
					[self.spinner stopAnimating];
					[self filterData];
				});
		}];
	}
}

#pragma mark <LibTG functions> 
static int get_dialogs_cb(void *d, const tg_dialog_t *dialog)
{
	DialogsViewController *self = (__bridge DialogsViewController *)d;
	
	if (!dialog)
		return 0;

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
		
		current.unread_count = dialog->unread_count;
		current.topMessageId = dialog->top_message_id;
		current.topMessageFromId = dialog->top_message_from_peer_id;
		[current syncReadDate];
		
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
	[self cancelAll];

	if (!self.appDelegate.isOnLineAndAuthorized){
		[self.appDelegate showMessage:@"no network"];
		[tableView deselectRowAtIndexPath:indexPath animated:true];
		return;
	}
	
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

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

#pragma mark <UISearchBar functions>

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	self.searchBar.showsCancelButton = YES;
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	self.showNavigationBar = NO;
}

- (void)searchBar:(UISearchBar *)searchBar 
		textDidChange:(NSString *)searchText
{
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    //[self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    [self.searchBar resignFirstResponder];
		self.searchBar.showsCancelButton = NO;
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		self.showNavigationBar = YES;
	
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

#pragma mark <AppActivity Delegate>
-(void)willResignActive {
	if (self.timer)
		[self.timer fire];
	[self cancelAll];
}

#pragma mark <>ABPeoplePickerNavigationController Delegate>
- (void)peoplePickerNavigationControllerDidCancel:
(ABPeoplePickerNavigationController *)peoplePicker
{
	[peoplePicker dismissViewControllerAnimated:true completion:nil];
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person 
{
	if (!self.appDelegate.isOnLineAndAuthorized){
		[self.appDelegate showMessage:@"no network"];
		return NO;
	}
	NSString *name = (__bridge NSString *)
	 	ABRecordCopyCompositeName(person);
	ABMultiValueRef phonesProperty = 
		ABRecordCopyValue(person, kABPersonPhoneProperty);
	NSArray *phones = (__bridge NSArray *)
		ABMultiValueCopyArrayOfAllValues(phonesProperty);
	if (phones){
		[peoplePicker dismissViewControllerAnimated:true completion:nil];
		[self.spinner startAnimating];
		[[[NSOperationQueue alloc]init]addOperationWithBlock:^{
			for (NSString *phone in phones){
				tg_peer_t peer = tg_peer_by_phone(
						self.appDelegate.tg, 
						phone.UTF8String);
				if (peer.access_hash){
					TGDialog *dialog = [[TGDialog alloc] init];
					dialog.peerType = peer.type;
					dialog.peerId = peer.id;
					dialog.accessHash = peer.access_hash;
					dialog.title = name;
					// try to find user by id in local database
					tg_user_t *user = tg_user_get(
							self.appDelegate.tg, 
							peer.id);
					if (user){
						dialog.photoId = user->photo_id;
						if (user->username_)
							dialog.title = 
								[NSString stringWithUTF8String:user->username_];
						tg_user_free(user);
						free(user);
					}
					dispatch_sync(dispatch_get_main_queue(), ^{
						[self.spinner stopAnimating];
						[self openDialog:dialog];
					});
					return;
				}
			}
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.spinner stopAnimating];
				[self.appDelegate showMessage:@"can't find user in telegram"];
			});
		}];
	} else {
		[self.appDelegate showMessage:@"can't find user in telegram"];
		return NO;
	}

	return NO;
}

- (BOOL)peoplePickerNavigationController:
(ABPeoplePickerNavigationController *)peoplePicker
      shouldContinueAfterSelectingPerson:(ABRecordRef)person 
			property:(ABPropertyID)property
      identifier:(ABMultiValueIdentifier)identifier
{
  return NO;
}

-(void)openDialog:(TGDialog *)dialog {
	ChatViewController *vc = [[ChatViewController alloc]init];
	vc.hidesBottomBarWhenPushed = YES;
	vc.dialog = dialog;
	vc.spinner = self.spinner;
	[self.navigationController 
			pushViewController:vc animated:TRUE];
}

@end
// vim:ft=objc
