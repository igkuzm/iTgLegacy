#import "ChatViewControllerOld.h"
#include "TGMessage.h"
#include "FilePickerController.h"
#include <stdlib.h>
#include "UIKit/UIKit.h"
#include "CoreGraphics/CoreGraphics.h"
#include "Foundation/Foundation.h"
#include "BubbleView/NSBubbleData.h"
#include "BubbleView/UIBubbleTableView.h"
#include "Base64/Base64.h"
#include "QuickLookController.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"
#include "../libtg/tg/files.h"
#include "UIImage+Utils/UIImage+Utils.h"

@interface  ChatViewController()
{
}
@property float toolbarOrigY;
@end

@implementation ChatViewController

- (void)viewWillAppear:(BOOL)animated {
	self.title = self.dialog.title;
	// add timer
	self.timer = [NSTimer scheduledTimerWithTimeInterval:60 
			target:self selector:@selector(timer:) 
				userInfo:nil repeats:YES];

	// set icon
	self.icon = [[UIImageView alloc]initWithFrame:
		CGRectMake(
		self.navigationController.navigationBar.bounds.size.width - 40, 
		self.navigationController.navigationBar.bounds.size.height/2 - 20,
	 	40, 40)]; 
	[self.navigationController.navigationBar addSubview:self.icon];
	UIImage *icon = 
		self.dialog.photo?self.dialog.photo:[UIImage 
														 imageNamed:@"missingAvatar.png"]; 
	self.icon.image = [UIImage imageWithImage:icon 
			scaledToSize:CGSizeMake(40, 40)];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.textField endEditing:YES];
	[self.textField resignFirstResponder];
	[self.spinner startAnimating];
	[self.syncData cancelAllOperations];
	// stop timer
	if (self.timer)
		[self.timer fire];
	[self.icon removeFromSuperview];
	[self.syncData cancelAllOperations];
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
	self.syncData.maxConcurrentOperationCount = 1;
	
	self.bubbleTableView.bubbleDataSource = self;
	self.bubbleTableView.watchingInRealTime = YES;
	self.bubbleTableView.snapInterval = 2800;
	self.bubbleDataArray = [NSMutableArray array];
	self.tmpArray = [NSMutableArray array];
	self.downloadPhotoArray = [NSMutableArray array];
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
	self.textField.delegate = self;
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
	[[NSNotificationCenter defaultCenter] 
		addObserver:self
    selector:@selector(keyboardWillHide:)
    name:UIKeyboardWillHideNotification
    object:nil];
  [[NSNotificationCenter defaultCenter] 
		addObserver:self
    selector:@selector(keyboardWillShow:)
    name:UIKeyboardWillShowNotification
    object:nil];

	// load data
	self.first = YES;
	[self reloadData];
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

-(void)timer:(id)sender{
	// do timer funct
	[self.syncData cancelAllOperations];
	if (self.appDelegate.tg &&
			self.appDelegate.authorizedUser && 
			self.appDelegate.reach.isReachable)
	{
		[self.syncData addOperationWithBlock:^{
			[self appendDataFrom:0 date:[NSDate date]];
		}];
	}
}

- (void)onSend:(id)sender{
	NSString *text = self.textField.text;
	if (self.appDelegate.tg &&
			self.appDelegate.authorizedUser && 
			self.appDelegate.reach.isReachable)
	{
		[self.syncData addOperationWithBlock:^{
			tg_peer_t peer = {
					self.dialog.peerType, 
					self.dialog.peerId, 
					self.dialog.accessHash
			};
			tg_message_send(
					self.appDelegate.tg, 
					peer, text.UTF8String);
			[self appendDataFrom:0 date:[NSDate date]];
		}];
	}

	[self.textField setText:@""];
	[self.textField resignFirstResponder];
}

- (void)onAdd:(id)sender{
	// hide keyboard
	[self.textField resignFirstResponder];

	// create actionSheet
	UIActionSheet *as = [[UIActionSheet alloc]
		initWithTitle:@"Отправить" 
		delegate:self 
		cancelButtonTitle:@"отмена" 
		destructiveButtonTitle:nil 
		otherButtonTitles:
			@"файл",
			@"фото",
			@"изображение",
			@"геопозицию",
		nil];
	[as showFromToolbar:self.navigationController.toolbar];
}

-(void)refresh:(id)sender{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date]];
	}];
}

#pragma mark <Data Functions>
-(void)downloadPhotoForBubbleData:(NSBubbleData *)d{

	// add spinner to image view
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (!d.spinner)
			d.spinner = [[UIActivityIndicatorView alloc] 
					initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		d.spinner.center = CGPointMake(
				d.view.bounds.size.width/2, 
				d.view.bounds.size.height/2);
		[d.view addSubview:d.spinner];
		[d.spinner startAnimating]; 
	});

	// download photo
	NSDictionary *dict = @{@"self":self, @"data":d};
	char *photo = tg_get_photo_file(
			self.appDelegate.tg, 
			d.message.photoId, 
			d.message.photoAccessHash, 
			[d.message.photoFileReference UTF8String], 
			"s");

	// on done
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (d.spinner){
			[d.spinner stopAnimating]; 
			[d.spinner removeFromSuperview]; 
		}
	});

	if (photo){
		dispatch_sync(dispatch_get_main_queue(), ^{
			d.message.photoData = [NSData dataFromBase64String:
					[NSString stringWithUTF8String:photo]];
			d.message.photo = [UIImage imageWithData:d.message.photoData];
		
			// update BubbleView
			UIImageView *iv = (UIImageView *)d.view;
			iv.image = d.message.photo;
			[self.bubbleTableView reloadData];
		});

		free(photo);
	}
}

-(void)getPhotoForMessageCached:(NSBubbleData *)d{
	// try to get image from database
	char *photo  = photo_file_from_database(
			self.appDelegate.tg, 
			d.message.photoId);
	if (photo){
		// add photo to BubbleData
		d.message.photoData = [NSData dataFromBase64String:
				[NSString stringWithUTF8String:photo]];
		d.message.photo = [UIImage imageWithData:d.message.photoData];
		free(photo);
	} else {
	  // add image placeholder to BubbleData
		d.message.photo = [UIImage imageNamed:@"filetype_icon_png@2x.png"];
		
		// add task to queqe to download image
		if (!self.first)
			[self.downloadPhotoArray addObject:d];
	}
}

-(void)getDocumentForMessage:(NSBubbleData *)d{
	// add image placeholder to BubbleData
	switch (d.message.mediaType) {
		case id_messageMediaContact:
			{
				d.message.photo = 
					[UIImage imageNamed:@"avatar@2x.png"];
			}
			break;
		case id_messageMediaDocument:
			{
				if (d.message.isVoice)
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
				else if (d.message.isVideo)
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_video@2x.png"];

				// todo handle MIME TYPES
				// d.message.mimeType
			}
			break;
		case id_messageMediaGeo:
			{
				d.message.photo = 
					[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];

			}
			break;
	
		default:
				d.message.photo = 
					[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];
			break;
	}
}

- (void)appendDataFrom:(int)offset date:(NSDate *)date
{
	//sleep(1); //for FLOOD_WAIT
	
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}

	if (!self.appDelegate.tg ||
			!self.appDelegate.authorizedUser ||
			!self.appDelegate.reach.isReachable)
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.refreshControl endRefreshing];
			[self.spinner stopAnimating];
		});
		return;
	}
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self.spinner startAnimating];
	});

	[self.downloadPhotoArray removeAllObjects];

	tg_peer_t peer = {
		self.dialog.peerType,
		self.dialog.peerId,
		self.dialog.accessHash
	};

	int limit = 
		peer.type == TG_PEER_TYPE_CHANNEL?6:8;

	tg_messages_get_history(
			self.appDelegate.tg, 
			peer, 
			offset, 
			[date timeIntervalSince1970], 
			0, 
			limit, 
			0, 
			0, 
			NULL, 
			self, 
			messages_callback);

	// on done
	dispatch_sync(dispatch_get_main_queue(), ^{
				[self.refreshControl endRefreshing];
				[self.spinner stopAnimating];
				[self.bubbleTableView reloadData];
	});

	self.first = NO;

	[self.syncData addOperationWithBlock:^{
		// set read history
		NSInteger lastSectionIdx = 
			[self.bubbleTableView numberOfSections] - 1;
		NSArray *section = 
			[self.bubbleTableView.bubbleSection objectAtIndex:lastSectionIdx];
		NSBubbleData *bd = 
			[section objectAtIndex:section.count - 1];
		if (bd){
			tg_peer_t peer = {
				self.dialog.peerType,
				self.dialog.peerId,
				self.dialog.accessHash
			};
			tg_messages_set_read(
					self.appDelegate.tg, 
					peer, 
					bd.message.id);
		}
	
		// download photos
		for (NSBubbleData *d in self.downloadPhotoArray){
			[self downloadPhotoForBubbleData:d];
		}
	}];
}

- (void)reloadData {
	[self.syncData cancelAllOperations];

	// animate spinner
	if (!self.refreshControl.refreshing)
		[self.spinner startAnimating];

	[self.bubbleDataArray removeAllObjects];

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
			//[self.spinner stopAnimating];
			[self.bubbleTableView reloadData];
			[self.bubbleTableView scrollToBottomWithAnimation:NO];
		});

		self.first = NO;
	
		// update data
		[self appendDataFrom:0 date:[NSDate date]];
		
	}];
}


#pragma mark <LibTG Functions>
static int messages_callback(void *d, const tg_message_t *m){
	ChatViewController *self = d;
	if (m->peer_id_ == self.dialog.peerId){

		NSBubbleData *item = NULL; 
		for (NSBubbleData *d in self.bubbleDataArray){
			if (d.message.id == m->id_){
				item = d;
				break;
			}
		}

		if (item){
			// update TGMessage
			dispatch_sync(dispatch_get_main_queue(), ^{
				item.message = [[TGMessage alloc]initWithMessage:m];
				if (m->photo_id){
					[self getPhotoForMessageCached:item];
				} else if (m->doc_id){
					[self getDocumentForMessage:item];
				}
			});
		} else {
			item = [NSBubbleData alloc]; 

			NSBubbleType type = 
						(m->from_id_ == self.appDelegate.authorizedUser->id_)?
						BubbleTypeMine:BubbleTypeSomeoneElse;
		
			// init TGMessage
			item.message = [[TGMessage alloc]initWithMessage:m];
			
			if (m->photo_id){
				[self getPhotoForMessageCached:item];
			} else if (m->doc_id){
				[self getDocumentForMessage:item];
			}
					
			dispatch_sync(dispatch_get_main_queue(), ^{
				if (item.message.photo){
					[item initWithImage:item.message.photo 
							date:item.message.date 
							type:type];
				} else {
					[item initWithText:item.message.message
							date:item.message.date 
							type:type];
				}
				[self.bubbleDataArray addObject:item];
			});
		}
	}

	return 0;
}

#pragma mark <UIBubbleTableViewDelegate>
- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectData:(NSBubbleData *)data 
{
	TGMessage *m = data.message;
	if (m){
		if (m.photoId){
			NSString *filepath = [self.appDelegate.imagesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.png", m.photoId]];
			NSURL *url = [NSURL fileURLWithPath:filepath]; 
			if ([NSFileManager.defaultManager fileExistsAtPath:filepath]){
					QuickLookController *qlc = [[QuickLookController alloc]
						initQLPreviewControllerWithData:@[url]];	
					[self presentViewController:qlc animated:TRUE completion:nil];
			} else {
				// download photo
				UIActivityIndicatorView *spinner = 
					[[UIActivityIndicatorView alloc] 
					initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
				spinner.center = 
					CGPointMake(data.view.bounds.size.width/2, data.view.bounds.size.height/2);
				[data.view addSubview:spinner];
				
				[spinner startAnimating]; 
				NSDictionary *dict = 
					@{@"self":self, @"filepath":filepath, @"spinner":spinner};

				[self.syncData addOperationWithBlock:^{
					char *photo = tg_get_photo_file(
							self.appDelegate.tg, 
							m.photoId, 
							m.photoAccessHash, 
							[m.photoFileReference UTF8String], 
							"x"); 

					// on done
					if (spinner){
						dispatch_sync(dispatch_get_main_queue(), ^{
							[spinner stopAnimating]; 
							[spinner removeFromSuperview];
						});
					}
					if (photo){
						NSData *data = [NSData dataFromBase64String:
							[NSString stringWithUTF8String:photo]];
						if (data){
							[data writeToFile:filepath atomically:YES];
							dispatch_sync(dispatch_get_main_queue(), ^{
								QuickLookController *qlc = [[QuickLookController alloc]
									initQLPreviewControllerWithData:@[url]];	
								[self presentViewController:qlc 
																	 animated:TRUE completion:nil];
							});
						}
						free(photo);

					} else { // no photo
						dispatch_sync(dispatch_get_main_queue(), ^{
							[self.appDelegate 
								showMessage:@"can't download full-sized photo"];
						});
					}
				}];
			}
		}
	}
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

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgTo:(NSBubbleData *)data
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:data.date];
	}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToBottom:(Boolean)bottom
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date]];
	}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToTop:(Boolean)top
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:self.bubbleDataArray.count-1 date:[NSDate date]];
	}];
}


#pragma mark <UIBubbleTableView DataSource>
- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row 
{
	return [self.bubbleDataArray objectAtIndex:row];
}
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView 
{
	return self.bubbleDataArray.count;
}

#pragma mark <UITextField Delegate>
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	if (self.appDelegate.tg &&
			self.appDelegate.authorizedUser && 
			self.appDelegate.reach.isReachable)
	{
		[self.syncData addOperationWithBlock:^{
			tg_peer_t peer = {
						self.dialog.peerType, 
						self.dialog.peerId, 
						self.dialog.accessHash
			};
			tg_messages_set_typing(
					self.appDelegate.tg, 
					peer, 
					true);
		}];
	}

	self.bubbleTableView.typingBubble = NSBubbleTypingTypeMe;
	[self.bubbleTableView reloadData];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	if (self.appDelegate.tg &&
			self.appDelegate.authorizedUser && 
			self.appDelegate.reach.isReachable)
	{
		[self.syncData addOperationWithBlock:^{
			tg_peer_t peer = {
						self.dialog.peerType, 
						self.dialog.peerId, 
						self.dialog.accessHash
			};
			tg_messages_set_typing(
					self.appDelegate.tg, 
					peer, 
					false);
		}];
	}

	self.bubbleTableView.typingBubble = NSBubbleTypingTypeNobody;
	[self.bubbleTableView reloadData];
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	// get selected item
	switch (buttonIndex){
		case 0:
			{
				FilePickerController *fpc = [[FilePickerController alloc]
					initWithPath:@"/var/mobile" isNew:YES];
				UINavigationController *nc = [[UINavigationController alloc]
					initWithRootViewController:fpc];
				[self presentViewController:nc animated:TRUE completion:nil];
			}
			break;

		case 1:
			{
				UIImagePickerController *ipc = 
					[[UIImagePickerController alloc] init];
				ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
				ipc.delegate = self;
        [self presentViewController:ipc animated:YES completion:nil];
			}
			break;

		case 2:
			{
				UIImagePickerController *ipc = 
					[[UIImagePickerController alloc] init];
				ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				ipc.delegate = self;
        [self presentViewController:ipc animated:YES completion:nil];
			}
			break;

		default:
			break;
	}
}	

#pragma mark <UIImagePickerController Delegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
  
	// hide picker
	[self dismissViewControllerAnimated:YES completion:nil];
  UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];

    NSBubbleData *imgBubbleData = 
			[NSBubbleData dataWithImage:image date:[NSDate date] type:BubbleTypeMine];
  [self.bubbleDataArray addObject:imgBubbleData];
	[self.bubbleTableView reloadData];
}

#pragma mark <Keyboard Functions>
- (void)keyboardWillShow:(NSNotification *)notification {
    CGSize keyboardSize = [[[notification userInfo] 
			objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    float newVerticalPosition = -keyboardSize.height;

    [self moveFrameToVerticalPosition:newVerticalPosition forDuration:0.3f];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self moveFrameToVerticalPosition:0.0f forDuration:0.3f];
}

- (void)moveFrameToVerticalPosition:(float)position forDuration:(float)duration {
    CGRect frame = self.view.frame;
    CGRect toolbarFrame = self.navigationController.toolbar.frame;
    frame.origin.y = position;
		if (position){
			self.toolbarOrigY = toolbarFrame.origin.y;
			toolbarFrame.origin.y += position;
		} else
			toolbarFrame.origin.y = self.toolbarOrigY;

    [UIView animateWithDuration:duration animations:^{
        self.view.frame = frame;
				self.navigationController.toolbar.frame = toolbarFrame;
    }];
}
@end
// vim:ft=objc
