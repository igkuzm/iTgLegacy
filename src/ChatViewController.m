#import "ChatViewController.h"
#include "TGMessage.h"
#include "ChatViewCell.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "CoreGraphics/CoreGraphics.h"
#include "Base64/Base64.h"
#include "../libtg/tg/messages.h"
#include "../libtg/tg/files.h"

@implementation ChatViewController

- (ChatViewController *)initWithDialog:(TGDialog *)dialog {
	if (self = [super initWithStyle:(UITableViewStylePlain)]) {
		self.dialog = dialog;	
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	// set tableview
	self.tableView.backgroundColor = [UIColor clearColor];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	
	// init data
	self.data = [NSMutableArray array];

	// init syncData
	self.syncData = [[NSOperationQueue alloc]init];
	
	// init spinner
	CGRect spinnerRect = self.tableView.bounds;
	self.spinner.center = 
		CGPointMake(
				spinnerRect.size.width/2, 
				spinnerRect.size.height/2);
	self.spinner = [[UIActivityIndicatorView alloc]
		initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[self.view addSubview:self.spinner]; 

	// init refresh
	self.refreshControl= [[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:
		[[NSAttributedString alloc] initWithString:@"more messages..."]];
	[self.refreshControl 
		addTarget:self 
		action:@selector(refresh:) 
		forControlEvents:UIControlEventValueChanged];
	[self.tableView addSubview:self.refreshControl];

	// set delegate
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	// flip tableView
	[self.tableView setTransform:
		CGAffineTransformScale(self.tableView.transform, 1, -1)];

	//set keyboard observer
	[[NSNotificationCenter defaultCenter]
		addObserver:self
    selector:@selector(keyboardWillHideOrShow:)
    name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] 
		addObserver:self
		selector:@selector(keyboardWillHideOrShow:)
    name:UIKeyboardWillShowNotification object:nil];

	// set toolbar
	CGRect textFieldFrame =
		CGRectMake(
				0,0,
				self.navigationController.toolbar.frame.size.width-95,
			 	30);
	self.textField = 
		[[UITextField alloc]
		initWithFrame:textFieldFrame];
	[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
	UIBarButtonItem *textFieldItem = 
		[[UIBarButtonItem alloc] 
		initWithCustomView:self.textField];
	UIBarButtonItem *flexibleSpace = 
		[[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
	  target:nil
		action:nil];
	[self.textField setDelegate:self];
	UIBarButtonItem *send = 
		[[UIBarButtonItem alloc]
		initWithTitle:@"send" 
		style:UIBarButtonItemStyleDone 
	  target:self 
		action:@selector(onSend:)];
	UIBarButtonItem *add = 
		[[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
		target:self 
		action:@selector(onAdd:)];
	[self 
		setToolbarItems:
			@[flexibleSpace, add, flexibleSpace, 
				textFieldItem, flexibleSpace, send, 
				flexibleSpace] 
		animated:NO];
	[self.navigationController setToolbarHidden: NO];
}

- (void)reloadData {
	[self.spinner startAnimating];
	[self.data removeAllObjects];
	[self getMessagesCached];
	//[self getMessagesFrom:0];
}

#pragma mark <UITableView DataSource>
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	TGMessage *message = [self.data objectAtIndex:indexPath.item];
	
	ChatViewCell *cell = 
		[self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
		cell = [[ChatViewCell alloc] init];
	}

	[cell setMessage:message];
	
	// flip cell
	[cell setTransform:
		CGAffineTransformScale(cell.transform, 1, -1)];
	return cell;
}

#pragma mark <UITableView Delegate>
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// append data
	[self getMessagesFrom:self.data.count];
}

#pragma mark <Keyboard Observer>
- (void)keyboardWillHideOrShow:(NSNotification *)note{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = 
			[[userInfo objectForKey:
			UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = 
			[[userInfo objectForKey:
			UIKeyboardAnimationCurveUserInfoKey] intValue];

    CGRect keyboardFrame = 
			[[userInfo objectForKey:
			UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameForToolbar = 
			[self.navigationController.toolbar.superview 
			convertRect:keyboardFrame fromView:nil];
    CGRect keyboardFrameForTableView = 
			[self.tableView.superview 
			convertRect:keyboardFrame fromView:nil];

    CGRect newToolbarFrame = 
			self.navigationController.toolbar.frame;
    newToolbarFrame.origin.y = 
			keyboardFrameForToolbar.origin.y - newToolbarFrame.size.height;

    CGRect newTableViewFrame = 
			self.tableView.frame;
    newTableViewFrame.size.height = 
			keyboardFrameForTableView.origin.y - newToolbarFrame.size.height;

    [UIView 
			animateWithDuration:duration
      delay:0
      options:UIViewAnimationOptionBeginFromCurrentState | curve
      animations:^{
				self.navigationController.toolbar.frame = newToolbarFrame;
        self.tableView.frame =newTableViewFrame;}
      completion:nil];

		[self.navigationController setToolbarHidden: NO];
}

#pragma mark <UIRefreshControl functions>
- (void) refresh:(id)sender {
	[self getMessagesFrom:self.data.count];
}

#pragma mark <LibTg functions>
static int messages_callback(void *d, const tg_message_t *m){
	ChatViewController *self = d;
	if (m->peer_id_ == self.dialog.peerId){
		// init message
		TGMessage *msg = [[TGMessage alloc]initWithMessage:m];

		//bool me = (m->from_id_ == self.appDelegate.authorizedUser->id_);
		//if (m->photo_id){
			//// get photo
			//buf_t reference = buf_from_base64(m->photo_file_reference);
			//char *photo = tg_get_photo_file(
						//self.appDelegate.tg, 
						//m->photo_id, 
						//m->photo_access_hash, 
						//m->photo_file_reference, 
						//"s");
			//if (photo){
				//// add photo to message
				//NSData *data = [NSData dataFromBase64String:
						//[NSString stringWithUTF8String:photo]];
				//msg.photo = [UIImage imageWithData:data];
			//}
		//}
		[self.cache addObject:msg];
	} else { //wrong peerId
	
	}
}

static void on_done(void *d){
	ChatViewController *self = d;
	[self getMessagesCached];
	[self.refreshControl endRefreshing];
}

#pragma mark <Data functions>
-(void)getMessagesCached{
	tg_peer_t peer = {
			self.dialog.peerType,
			self.dialog.peerId,
			self.dialog.accessHash
	};

	[self.syncData addOperationWithBlock:^{
		tg_get_messages_from_database(
					self.appDelegate.tg, 
					peer, 
					self, 
					messages_callback);

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.data addObjectsFromArray:self.cache];
			[self.tableView reloadData];
			[self.spinner stopAnimating];
		});
		// get photo
		//tg_peer_t peer = {
			//self.dialog.peerType,
			//self.dialog.peerId,
			//self.dialog.accessHash
		//};
		//char *photo = 
			//tg_get_peer_photo_file(
					//self.appDelegate.tg, 
					//&peer, 
					//false, 
					//self.dialog.photoId);
		
		//dispatch_sync(dispatch_get_main_queue(), ^{
				//if (photo){
					//[self.appDelegate showMessage:@"Photo OK!"];
				//} else {
					//[self.appDelegate showMessage:@"Photo ERR"];
				//}
		//});
	}];
}

-(void)getMessagesFrom:(int)offset{
	//if (!self.appDelegate.reach.isReachable)
	//{
		//[self.refreshControl endRefreshing];
		//[self.spinner stopAnimating];
		//[self.appDelegate showMessage:@"no network"];
		//return;
	//}
	
	//[self.cache removeAllObjects];
	//[self.refreshControl startRefreshing];

	//[self.syncData addOperationWithBlock:^{
		//tg_peer_t peer = {
			//self.dialog.peerType,
			//self.dialog.peerId,
			//self.dialog.accessHash
		//};

		//int limit = 
			//peer.type == TG_PEER_TYPE_CHANNEL?1:5;
		//tg_sync_messages_to_database(
				//self.appDelegate.tg, 
				//peer,
				//offset,	
				//limit,
				//self, on_done);
	//}];
}

@end
// vim:ft=objc
