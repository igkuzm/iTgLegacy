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

@implementation TGContact
- (id)init
{
	if (self = [super init]) {
		
	}
	return self;
}
@end

@implementation ContactsListViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	self.appDelegate = 
		UIApplication.sharedApplication.delegate;

  self.syncData = [[NSOperationQueue alloc]init];

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
	if (self.searchString == nil || [self.searchString isEqualToString:@""]) {
		self.data = self.loadedData;
	}else {
		NSPredicate *predicate = 
			[NSPredicate predicateWithFormat:
			@"self.name contains[c] %@ or self.nickname contains[c] %@ or self.phones contains[c] %@ or self.emails contains[c] %@", 
			self.searchString,self.searchString,self.searchString,self.searchString];
		self.data = [self.loadedData filteredArrayUsingPredicate:predicate];
	}
	[self.spinner stopAnimating];
	[self.tableView reloadData];	
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
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

	TGContact *contact = [self.data objectAtIndex:indexPath.item];
	cell.textLabel.text = contact.name;
	

	if (contact.phones)
		cell.detailTextLabel.text = contact.phones;
	
	if (contact.imageData){
		UIImage *image = [UIImage imageWithData:contact.imageData];
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
	
	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
	{
		[self.appDelegate showMessage:@"no network"];
		return;
	}
	
	UITableViewCell *cell = 
		[tableView cellForRowAtIndexPath:indexPath];

	TGContact *contact = [self.data objectAtIndex:indexPath.item];
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
		if (contact.phones){
			NSArray *phones = 
				[contact.phones componentsSeparatedByString:@" "];
			
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
					dialog.title = contact.name;
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

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	self.searchString=searchText;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	[self filterData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
	[self filterData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
		self.searchString=@"";
    [self.searchBar resignFirstResponder];
		// load data
		[self filterData];
}

#pragma mark <Contacts Manager>
-(void)getContacts{
	ABAddressBookRequestAccessWithCompletion(
			ABAddressBookCreateWithOptions(
				NULL, nil), 
			^(bool granted, CFErrorRef error) 
	{
		if (!granted){
			NSLog(@"Just denied");
			return;
		}

		NSLog(@"Just authorized");
		
		[self.spinner startAnimating];

		self.loadedData = [NSMutableArray array];

		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, NULL, kABPersonSortByLastName);
		//CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(
        //kCFAllocatorDefault,
        //CFArrayGetCount(people),
        //people);
		
		NSUInteger peopleCounter = 0;
		for (peopleCounter = 0; peopleCounter < ((__bridge NSArray *)people).count; peopleCounter++)
		{
			TGContact *contact = [[TGContact alloc]init];
			ABRecordRef thisPerson = (__bridge ABRecordRef) [(__bridge NSArray *)people objectAtIndex:peopleCounter];

			NSString *name = (__bridge NSString *) ABRecordCopyCompositeName(thisPerson);
			if (name.length > 0)
				contact.name = [NSString stringWithString:name];
			else
				contact.name = @"no name";

			NSString *nickname = (__bridge NSString *) ABRecordCopyValue(thisPerson, kABPersonNicknameProperty);
			if (nickname.length > 0)
				contact.nickname = [NSString stringWithString:nickname];

			NSData *contactImageData = (__bridge NSData *)ABPersonCopyImageDataWithFormat(thisPerson, kABPersonImageFormatThumbnail);
			if (contactImageData)
				contact.imageData = [NSData dataWithData:contactImageData];

			ABMultiValueRef phonesProperty = ABRecordCopyValue(thisPerson, kABPersonPhoneProperty);
			NSArray *phones = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phonesProperty);
			if (phones)
				contact.phones = [phones componentsJoinedByString:@" "];
			
			ABMultiValueRef emailsProperty = ABRecordCopyValue(thisPerson, kABPersonEmailProperty);
			NSArray *emails = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailsProperty);
			if (emails)
				contact.emails = [emails componentsJoinedByString:@" "];
						
			// add contact
			[self.loadedData addObject:contact];
		}
		CFRelease(addressBook);

		[self filterData];
	});
}

@end

// vim:ft=objc
