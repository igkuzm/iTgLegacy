#import "ContactsListViewController.h"
#import "ChatViewController.h"
#include "AddressBook/AddressBook.h"
#include "CoreFoundation/CoreFoundation.h"
#include "Foundation/Foundation.h"
#import "AppDelegate.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#include "UIImage+Utils/UIImage+Utils.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/user.h"

@implementation ContactsListViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.appDelegate = 
		UIApplication.sharedApplication.delegate;

  self.syncData = [[NSOperationQueue alloc]init];
  self.filterQueue = [[NSOperationQueue alloc]init];
	self.filterQueue.maxConcurrentOperationCount = 1;
	
	self.showNavigationBar = YES;

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
	self.searchString = @"";

	[self.tableView reloadData]; // load search bar
	
	self.refreshControl=[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	[self loadData];
}

- (void)viewDidUnload{
	[self.syncData cancelAllOperations];
	[super viewDidUnload];
}

-(void)loadData{
	[self.syncData cancelAllOperations];
	[self getContacts];
}

-(void)filterData{
	[self.filterQueue cancelAllOperations];

	[self.filterQueue addOperationWithBlock:^{
		if (![self.searchString isEqualToString:@""])
		{
			NSPredicate *predicate = [NSPredicate predicateWithBlock:
				^BOOL(id evaluatedObject, NSDictionary *bindings) 
			{
				ABRecordRef person=(__bridge ABRecordRef)evaluatedObject;
				
				NSString *name = (__bridge NSString *)
					ABRecordCopyCompositeName(person);
				if (name && [name rangeOfString:self.searchString].location != NSNotFound){
					return YES;
				}
				
				NSString *nickName = (__bridge NSString *)
					ABRecordCopyValue(
							person, kABPersonNicknameProperty);
				if (nickName && [nickName rangeOfString:self.searchString].location != NSNotFound){
					return YES;
				}

				ABMultiValueRef phonesProperty =
					ABRecordCopyValue(
							person, kABPersonPhoneProperty);
				NSArray *phones = (__bridge NSArray *)
					ABMultiValueCopyArrayOfAllValues(phonesProperty);
				CFRelease(phonesProperty);
				for (NSString *value in phones) {
					if ([value rangeOfString:self.searchString].location!=NSNotFound) {
							return YES;
					}
				}

				ABMultiValueRef emailsProperty =
					ABRecordCopyValue(
							person, kABPersonEmailProperty);
				NSArray *emails = (__bridge NSArray *)
					ABMultiValueCopyArrayOfAllValues(emailsProperty);
				CFRelease(emailsProperty);
				for (NSString *value in emails) {
					if ([value rangeOfString:self.searchString].location!=NSNotFound) {
							return YES;
					}
				}

				return NO;
			}];

			self.data = [self.loadedData filteredArrayUsingPredicate:predicate];
		
		} else { // no search
			self.data = self.loadedData;
		}
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.spinner stopAnimating];
			[self.tableView reloadData];	
		});
	}];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	// navigationBar
		if (self.showNavigationBar)
			[self.navigationController setNavigationBarHidden:NO animated:YES];
		else
			[self.navigationController setNavigationBarHidden:YES animated:YES];
		
	[self.navigationController setToolbarHidden: YES];
}

-(void)refresh:(id)sender{
	NSLog(@"refreshing...");
	[self loadData];
	[self.refreshControl endRefreshing];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
	return self.data.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (!cell)
		cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];	

	ABRecordRef person = (__bridge ABRecordRef)
		[self.data objectAtIndex:indexPath.item];

	NSString *name = (__bridge NSString *)
	 	ABRecordCopyCompositeName(person);
	cell.textLabel.text = name;
	
	ABMultiValueRef phonesProperty =
		ABRecordCopyValue(person, kABPersonPhoneProperty);
	NSArray *phones = (__bridge NSArray *)
		ABMultiValueCopyArrayOfAllValues(phonesProperty);
	if (phones){
		cell.detailTextLabel.text = 
			[phones componentsJoinedByString:@" "];
	}
	
	NSData *imageData = (__bridge NSData *)
		ABPersonCopyImageDataWithFormat(person, kABPersonImageFormatThumbnail);
	if (imageData){
		UIImage *image = [UIImage imageWithData:imageData];
		cell.imageView.image = [UIImage imageWithImage:image 
			scaledToSize:CGSizeMake(50, 50)];
	}
	else 
		cell.imageView.image = [UIImage imageNamed:@"missingAvatar.png"];

	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;	
	return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	[self.searchBar resignFirstResponder];
	
	if (!self.appDelegate.isOnLineAndAuthorized)
	{
		[self.appDelegate showMessage:@"no network"];
		return;
	}
	
	UITableViewCell *cell = 
		[tableView cellForRowAtIndexPath:indexPath];

	ABRecordRef person = (__bridge ABRecordRef)
		[self.data objectAtIndex:indexPath.item];
	
	// spinner
	UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	spinner.center = 
		CGPointMake(
				cell.bounds.size.width - 40, 
				cell.bounds.size.height/2);
	[cell addSubview:spinner]; 
	[spinner startAnimating];

	// try to get peer
	[self.syncData addOperationWithBlock:^{
		ABMultiValueRef phonesProperty =
			ABRecordCopyValue(person, kABPersonPhoneProperty);
		NSArray *phones = (__bridge NSArray *)
			ABMultiValueCopyArrayOfAllValues(phonesProperty);
		if (phones){
			
			// try to get user in local database first
			//for (NSString *phone in phones){
				//tg_user_t *user = tg_user_get_by_phone(
						//self.appDelegate.tg, 
						//phone.UTF8String);
				//if (user){
					//TGDialog *dialog = [[TGDialog alloc] init];
					//dialog.peerType = TG_PEER_TYPE_USER;
					//dialog.peerId = user->id_;
					//dialog.accessHash = user->access_hash_;
					//dialog.photoId = user->photo_id;
					//dialog.title = contact.name; 
					//if (user->username_)
						//dialog.title = 
							//[NSString stringWithUTF8String:user->username_];
					//dispatch_sync(dispatch_get_main_queue(), ^{
						//[spinner stopAnimating];
						//[spinner removeFromSuperview];
						//[self openDialog:dialog];
					//});
					//tg_user_free(user);
					//free(user);
					//return;
				//}
			//}

			// if no user - try to get from telegram
			for (NSString *phone in phones){
				tg_peer_t peer = tg_peer_by_phone(
						self.appDelegate.tg, 
						phone.UTF8String);
				if (peer.access_hash){
					TGDialog *dialog = [[TGDialog alloc] init];
					dialog.peerType = peer.type;
					dialog.peerId = peer.id;
					dialog.accessHash = peer.access_hash;
					NSString *name = (__bridge NSString *)
						ABRecordCopyCompositeName(person);
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
						[spinner stopAnimating];
						[spinner removeFromSuperview];
						[self openDialog:dialog];
					});
					return;;
				}
			}
		}
		dispatch_sync(dispatch_get_main_queue(), ^{
			[spinner stopAnimating];
			[spinner removeFromSuperview];
			[self.appDelegate showMessage:@"can't find user in telegram"];
		});
	}];
}

-(void)openDialog:(TGDialog *)dialog {
	ChatViewController *vc = [[ChatViewController alloc]init];
	vc.hidesBottomBarWhenPushed = YES;
	vc.dialog = dialog;
	vc.spinner = self.spinner;
	[self.navigationController 
			pushViewController:vc animated:TRUE];
}

-(void)addButtonPushed:(id)sender{

}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
	self.searchBar.showsCancelButton = YES;
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	self.showNavigationBar = NO;
}

- (void)searchBar:(UISearchBar *)searchBar 
		textDidChange:(NSString *)searchText
{
	self.searchString = searchBar.text;
	[self filterData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self.searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
		self.searchString = @"";
		self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
		self.searchBar.showsCancelButton = NO;
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		self.showNavigationBar = YES;
		
		// load data
		[self filterData];
}

#pragma mark <Contacts Manager>
-(void)syncContacts{
	[self.spinner startAnimating];

	[self.syncData addOperationWithBlock:^{
		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		CFArrayRef people = 
			ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(
					addressBook, 
					NULL, 
					kABPersonSortByLastName);

		self.loadedData = (__bridge NSMutableArray *)people;
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.spinner stopAnimating];
			[self filterData];
		});
	}];
}
-(void)getContacts{
	ABAddressBookRequestAccessWithCompletion(
			ABAddressBookCreateWithOptions(
				NULL, nil), 
			^(bool granted, CFErrorRef error) 
	{
		if (!granted){
			NSLog(@"Access to contacts denied");
			return;
		}

		NSLog(@"Access to contacts authorized");
		[self syncContacts];
	});
}

@end

// vim:ft=objc
