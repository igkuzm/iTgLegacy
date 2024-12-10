#import "ChatViewController.h"
#include <stdlib.h>
#include "UIKit/UIKit.h"
#include "CoreGraphics/CoreGraphics.h"
#include "Foundation/Foundation.h"
#include "BubbleView/NSBubbleData.h"
#include "BubbleView/UIBubbleTableView.h"
#include "Base64/Base64.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"
#include "../libtg/tg/files.h"

@interface  ChatViewController()
{
}
@end

@implementation ChatViewController

- (void)viewWillAppear:(BOOL)animated {
    //[UINavigationBar.appearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    //[UINavigationBar.appearance setTintColor:[UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0]];
		//
	// add timer
	self.timer = [NSTimer scheduledTimerWithTimeInterval:60 
			target:self selector:@selector(timer:) 
				userInfo:nil repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
	// stop timer
	if (self.timer)
		[self.timer fire];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	CGRect frame = 
		CGRectMake(
				0, 
				0, 
				self.view.frame.size.width, 
				self.view.frame.size.height - 44 - 44);

	UIBubbleTableView *bubbleTableView = 
			[[UIBubbleTableView alloc]initWithFrame:frame
			style:UITableViewStylePlain];
		[self.view addSubview:bubbleTableView];
	self.bubbleTableView = bubbleTableView;
	[self.bubbleTableView setBubbleDelegate:self];

	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	self.syncData = [[NSOperationQueue alloc]init];
	self.spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	[self.view addSubview:self.spinner]; 
	
	self.bubbleTableView.bubbleDataSource = self;
	self.bubbleTableView.watchingInRealTime = YES;
	self.bubbleTableView.snapInterval = 2800;
	self.bubbleDataArray = [NSMutableArray array];
	self.tmpArray = [NSMutableArray array];
	self.bubbleTableView.showAvatars = YES; 
		//= [[NSUserDefaults standardUserDefaults] boolForKey:@"showPFP"];
	[self.bubbleTableView reloadData];
		
  //self.imagePicker = [[UIImagePickerController alloc] init];
  //self.imagePicker.delegate = self;
  //self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	// refresh control
	self.refreshControl= [[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"more messages..."]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
	[self.bubbleTableView addSubview:self.refreshControl];

	// ToolBar
	self.textField = [[UITextField alloc]initWithFrame:CGRectMake(0,0,self.navigationController.toolbar.frame.size.width - 95, 30)];
	[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
	UIBarButtonItem *textFieldItem = [[UIBarButtonItem alloc] initWithCustomView:self.textField];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
	  target:nil
		action:nil];
	[self.textField setDelegate:self];
	UIBarButtonItem *send = [[UIBarButtonItem alloc]initWithTitle:@"send" style:UIBarButtonItemStyleDone target:self action:@selector(onSend:)];
	UIBarButtonItem *add = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onAdd:)];

	[self setToolbarItems:@[flexibleSpace, add, flexibleSpace, textFieldItem, flexibleSpace, send, flexibleSpace] animated:NO];
	[self.navigationController setToolbarHidden:NO];

	// keyboard
	[[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideOrShow:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHideOrShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];

		// load data
	[self reloadData];
}

-(void)timer:(id)sender{
	// do timer funct
	[self.syncData cancelAllOperations];
	[self appendDataFrom:0];
}

- (void)onSend:(id)sender{
	tg_peer_t peer = {
			self.dialog.peerType, 
			self.dialog.peerId, 
			self.dialog.accessHash
	};
	
	tg_send_message(
			self.appDelegate.tg, 
			peer, self.textField.text.UTF8String);

	NSBubbleData *bd = 
				[[NSBubbleData alloc]
					initWithText:self.textField.text
					date:[NSDate date] 
					type:BubbleTypeMine];

	[self.textField setText:@""];
	[self.bubbleDataArray addObject:bd];
	[self.bubbleTableView reloadData];
	[self.bubbleTableView scrollToBottomWithAnimation:YES];
}

- (void)onAdd:(id)sender{

}

- (void)keyboardWillHideOrShow:(NSNotification *)note
{
    NSDictionary *userInfo = note.userInfo;
    NSTimeInterval duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue];

    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameForToolbar = [self.navigationController.toolbar.superview convertRect:keyboardFrame fromView:nil];
    CGRect keyboardFrameForTableView = [self.bubbleTableView.superview convertRect:keyboardFrame fromView:nil];

    CGRect newToolbarFrame = self.navigationController.toolbar.frame;
    newToolbarFrame.origin.y = keyboardFrameForToolbar.origin.y - newToolbarFrame.size.height;

    CGRect newTableViewFrame = self.bubbleTableView.frame;
    newTableViewFrame.size.height = keyboardFrameForTableView.origin.y - newToolbarFrame.size.height;

    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | curve
                     animations:^{self.navigationController.toolbar.frame = newToolbarFrame;
                         self.bubbleTableView.frame =newTableViewFrame;}
                     completion:nil];

	[self.navigationController setToolbarHidden: NO];
}

static void on_messages_sync_done(void *data){
	ChatViewController *self = data;
	
	tg_peer_t peer = {
			self.dialog.peerType,
			self.dialog.peerId,
			self.dialog.accessHash
	};
	
	tg_get_messages_from_database(
				self.appDelegate.tg, 
				peer, 
				self, 
				messages_callback);
	
	dispatch_sync(dispatch_get_main_queue(), ^{
				[self.refreshControl endRefreshing];
				[self.spinner stopAnimating];
				[self.bubbleDataArray removeAllObjects];
				[self.bubbleDataArray addObjectsFromArray:self.tmpArray];
				[self.bubbleTableView reloadData];
	});
}

- (void)appendDataFrom:(int)offset
{
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}

	if (!self.appDelegate.reach.isReachable)
	{
		[self.refreshControl endRefreshing];
		[self.spinner stopAnimating];
		return;
	}
	
	[self.tmpArray removeAllObjects];

	[self.syncData addOperationWithBlock:^{
		tg_peer_t peer = {
			self.dialog.peerType,
			self.dialog.peerId,
			self.dialog.accessHash
		};

		int limit = 
			peer.type == TG_PEER_TYPE_CHANNEL?1:5;
		tg_sync_messages_to_database(
				self.appDelegate.tg, 
				peer,
			  offset,	
				limit,
				self, on_messages_sync_done);
	}];
}

- (void)reloadData {
	[self.syncData cancelAllOperations];

	// animate spinner
	CGRect rect = self.bubbleTableView.bounds;
	self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	[self.bubbleDataArray removeAllObjects];
	[self.tmpArray removeAllObjects];

	tg_peer_t peer = {
			self.dialog.peerType,
			self.dialog.peerId,
			self.dialog.accessHash
	};

	[self.syncData addOperationWithBlock:^{
		// get photo
		//char *photo = tg_get_peer_photo_file(
				//self.appDelegate.tg, 
				//&peer, 
				//false, 
				//self.dialog.photoId);
		//if (photo){
			//NSData *data = [NSData dataFromBase64String:
			//[NSString stringWithUTF8String:photo]];
			//if (data)
				//self.peerPhoto = [UIImage imageWithData:data];
			//free(photo);
		//}

		if (tg_get_messages_from_database(
				self.appDelegate.tg, 
				peer, 
				self, 
				messages_callback))
		{
			// reload data again;
				tg_get_messages_from_database(
					self.appDelegate.tg, 
					peer, 
					self, 
					messages_callback);
		}

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.bubbleDataArray addObjectsFromArray:self.tmpArray];
			//[self.spinner stopAnimating];
			[self.bubbleTableView reloadData];
			[self.bubbleTableView scrollToBottomWithAnimation:NO];
			[self appendDataFrom:0];
		});	
	}];
}

-(void)refresh:(id)sender{
	[self appendDataFrom:[self.bubbleDataArray count]];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super viewDidUnload];
}

#pragma mark <messages_getHistory callback>
struct photo_data {
	ChatViewController *self;
	NSBubbleData *bd;
};

static int messages_callback(void *d, const tg_message_t *m){
	ChatViewController *self = d;
	if (m->message_ && m->peer_id_ == self.dialog.peerId){
		bool me = (m->from_id_ == self.appDelegate.authorizedUser->id_);
		UIImage *img = NULL;
		if (m->photo_id){
			// download image
			buf_t fr = buf_from_base64(m->photo_file_reference);
			char *img_data = 
				tg_get_photo_file(
						self.appDelegate.tg, 
						m->photo_id, 
						m->photo_access_hash, 
						m->photo_file_reference, 
						"s");
			if (img_data){
				NSData *data = [NSData dataFromBase64String:
						[NSString stringWithUTF8String:img_data]];
				img = [UIImage imageWithData:data];
			}
		}
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			NSBubbleData *bd; 
			if (img){
				bd = [[NSBubbleData alloc]
						initWithImage:img 
						date:[NSDate dateWithTimeIntervalSince1970:m->date_] 
						type:me?BubbleTypeMine:BubbleTypeSomeoneElse
						msg_id:m->id_];
			} else {
				bd = [[NSBubbleData alloc]
						initWithText:[NSString stringWithUTF8String:m->message_] 
						date:[NSDate dateWithTimeIntervalSince1970:m->date_] 
						type:me?BubbleTypeMine:BubbleTypeSomeoneElse
						msg_id:m->id_];
			}

			//if (self.peerPhoto && 
					//self.dialog.peerType == TG_PEER_TYPE_USER)
				//bd.avatar = self.peerPhoto;
			
			[self.tmpArray addObject:bd];

		});
	} else {
		return 1;
	}

	return 0;
}

#pragma mark <UIBubbleTableViewDelegate>
- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectRow:(int)row 
{
  //NSLog(@"selected");
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didScroll:(UIScrollView *)scrollView
{
	[self.textField endEditing:YES];
	[self.textField resignFirstResponder];
}


- (void)bubbleTableViewOnTap:(UIBubbleTableView *)bubbleTableView
{
	//[self.appDelegate showMessage:@"TAP"];
	//[self.textField endEditing:YES];
	//[self.textField resignFirstResponder];
}

#pragma mark <UIBubbleTableViewDataSource>
- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row 
{
	return [self.bubbleDataArray objectAtIndex:row];
}
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView 
{
	return self.bubbleDataArray.count;
}

#pragma mark <UITextFieldDelegate>
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self.bubbleTableView scrollToBottomWithAnimation:YES];
}


@end
// vim:ft=objc
