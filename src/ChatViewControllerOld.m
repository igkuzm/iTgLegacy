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

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.appDelegate = UIApplication.sharedApplication.delegate;
	
	self.syncData = [[NSOperationQueue alloc]init];
	self.syncData.maxConcurrentOperationCount = 1;
	self.download = [[NSOperationQueue alloc]init];
	self.download.maxConcurrentOperationCount = 1;

	// set background
	self.view.backgroundColor = 
		[UIColor colorWithPatternImage:
			[UIImage imageNamed:@"wallpaper.jpg"]];

	// bubble table view
	self.bubbleTableView = 
			[[UIBubbleTableView alloc]initWithFrame:CGRectMake(
					0, 0, 
					self.view.frame.size.width, 
					self.view.frame.size.height - 44 - 44)
			style:UITableViewStylePlain];
	[self.view addSubview:self.bubbleTableView];
	[self.bubbleTableView setBubbleDelegate:self];
	self.bubbleTableView.bubbleDataSource = self;
	self.bubbleTableView.watchingInRealTime = YES;
	self.bubbleTableView.snapInterval = 2800;
	self.bubbleDataArray = [NSMutableArray array];
	if (self.dialog.peerType == TG_PEER_TYPE_CHAT)
		self.bubbleTableView.showAvatars = YES; 
	
	// refresh control
	self.refreshControl= [[UIRefreshControl alloc]init];
	[self.refreshControl 
		setAttributedTitle:[[NSAttributedString alloc] 
				initWithString:@"more messages..."]];
	[self.refreshControl 
		addTarget:self 
		action:@selector(refresh:) 
    forControlEvents:UIControlEventValueChanged];
	[self.bubbleTableView addSubview:self.refreshControl];

	// ToolBar
	self.textField = [[UITextField alloc]
		initWithFrame:CGRectMake(
				0,0,
				self.navigationController.toolbar.frame.size.width - 95, 
				30)];
	self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
	self.textField.delegate = self;
	self.textFieldItem = [[UIBarButtonItem alloc] 
		initWithCustomView:self.textField];
	
	self.flexibleSpace = [[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil action:nil];
	
	self.send = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"Send"]	
		style:UIBarButtonItemStyleDone 
		target:self action:@selector(onSend:)];
	
	self.add = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
		target:self action:@selector(onAdd:)];
	
	self.cancel = [[UIBarButtonItem alloc]
		initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
		target:self action:@selector(onCancel:)];

	self.progressLabel = [[UILabel alloc]
		initWithFrame:CGRectMake(0, 0, 60, 40)];
	self.progressLabel.numberOfLines = 2;
	self.progressLabel.lineBreakMode = NSLineBreakByCharWrapping;
  self.progressLabel.backgroundColor = [UIColor clearColor];
	self.progressLabel.font = [UIFont systemFontOfSize:8];
	self.label = [[UIBarButtonItem alloc]
		initWithCustomView:self.progressLabel];

	self.progressView = [[UIProgressView alloc]
		initWithProgressViewStyle:UIProgressViewStyleBar];
	self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	self.progress = [[UIBarButtonItem alloc]
		initWithCustomView:self.progressView];
	
	[self.navigationController setToolbarHidden:NO];
	[self toolbarAsEntry];

	// keyboard
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(keyboardWillHide:)
		name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] 
		addObserver:self selector:@selector(keyboardWillShow:)
		name:UIKeyboardWillShowNotification object:nil];

	// load data
	[self reloadData];
}

- (void)viewDidUnload
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	self.title = self.dialog.title;
	// add timer
	self.timer = [NSTimer 
		scheduledTimerWithTimeInterval:60 
		target:self selector:@selector(timer:) 
		userInfo:nil repeats:YES];

	// set icon
	self.icon = [[UIImageView alloc]
		initWithFrame:CGRectMake(
		self.navigationController.navigationBar.bounds.size.width - 40, 
		self.navigationController.navigationBar.bounds.size.height/2 - 20,
		40, 40)];
	[self.navigationController.navigationBar 
		addSubview:self.icon];
	UIImage *icon = self.dialog.photo?
		self.dialog.photo:
		[UIImage imageNamed:@"missingAvatar.png"]; 
	self.icon.image = [UIImage imageWithImage:icon 
			scaledToSize:CGSizeMake(40, 40)];
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.textField endEditing:YES];
	[self.textField resignFirstResponder];
	[self.spinner startAnimating];
	[self.syncData cancelAllOperations];
	[self.download cancelAllOperations];
	// stop timer
	if (self.timer)
		[self.timer fire];
	[self.icon removeFromSuperview];
	[super viewDidDisappear:animated];
}

-(void)toolbarAsEntry{
	[self 
		setToolbarItems:@[self.flexibleSpace, 
		                  self.add, 
											self.flexibleSpace, 
											self.textFieldItem, 
											self.flexibleSpace, 
											self.send, 
											self.flexibleSpace]
		animated:true];
}

-(void)toolbarAsProgress{
	[self 
		setToolbarItems:@[self.progress, 
											self.flexibleSpace, 
											self.label, 
											self.flexibleSpace, 
											self.cancel]
		animated:true];
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

- (void)onCancel:(id)sender{
	[self.download cancelAllOperations];
	[self toolbarAsEntry];
}

-(void)refresh:(id)sender{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date]];
	}];
}

#pragma mark <Data Functions>
-(void)getPhotoForMessageCached:(NSBubbleData *)d
											 download:(Boolean)download{
	if (!d.message.photo)
		d.message.photo = [UIImage imageNamed:@"filetype_icon_png@2x.png"];
	
	if (!download)
		return;
	
	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
		return;
	
	// try to get image from database
	if (d.message.photoId && !d.message.photoData){
		char *photo  = 
			tg_get_photo_file(
					self.appDelegate.tg, 
					d.message.photoId, 
					d.message.photoAccessHash, 
					d.message.photoFileReference.UTF8String, 
					"s");
		if (photo){
			// add photo to BubbleData
			d.message.photoData = [NSData dataFromBase64String:
					[NSString stringWithUTF8String:photo]];
			d.message.photo = [UIImage imageWithData:d.message.photoData];
			[d.message.photoData writeToFile:d.message.photoPath atomically:YES];
			free(photo);
		}
	}
}

-(void)getDocumentForMessageChached:(NSBubbleData *)d
											 download:(Boolean)download{
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
				else if ([d.message.mimeType isEqualToString:@"video/mov"] ||
						     [[d.message.docFileName pathExtension] isEqualToString:@"mov"] ||
						     [[d.message.docFileName pathExtension] isEqualToString:@"MOV"])
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mov@2x.png"];
				
				else if ([d.message.mimeType isEqualToString:@"video/mp4"] ||
						     [[d.message.docFileName pathExtension] isEqualToString:@"mp4"] ||
						     [[d.message.docFileName pathExtension] isEqualToString:@"MP4"])
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp4@2x.png"];
				
				else if ([d.message.mimeType isEqualToString:@"audio/ogg"])
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
				
				else if ([d.message.mimeType isEqualToString:@"audio/mp3"])
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp3@2x.png"];

				else
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];

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
	} // end switch (d.message.mediaType)

	if (!download)
		return;
	
	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
		return;
	
	// try to get image from database
	if (d.message.docId && !d.message.photoData){
		char *photo  = 
			tg_get_photo_file(
					self.appDelegate.tg, 
					d.message.photoId, 
					d.message.photoAccessHash, 
					d.message.photoFileReference.UTF8String, 
					"s");
		if (photo){
			// add photo to BubbleData
			d.message.photoData = [NSData dataFromBase64String:
					[NSString stringWithUTF8String:photo]];
			d.message.photo = [UIImage imageWithData:d.message.photoData];
			[d.message.photoData writeToFile:d.message.photoPath atomically:YES];
			free(photo);
		}
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


	tg_peer_t peer = {
		self.dialog.peerType,
		self.dialog.peerId,
		self.dialog.accessHash
	};

	int limit = 
		peer.type == TG_PEER_TYPE_CHANNEL?6:8;

	NSDictionary *dict = @{@"self":self, @"update": @1};

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
			dict, 
			messages_callback);

	// on done
	dispatch_sync(dispatch_get_main_queue(), ^{
				[self.refreshControl endRefreshing];
				[self.spinner stopAnimating];
				[self.bubbleTableView reloadData];
	});

	/*
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
	}];
	*/
}

- (void)reloadData {
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
		
		NSDictionary *dict = @{@"self":self, @"update": @0};
		
		tg_get_messages_from_database(
			self.appDelegate.tg, 
			peer, 
			dict, 
			messages_callback);

		dispatch_sync(dispatch_get_main_queue(), ^{
			//[self.spinner stopAnimating];
			[self.bubbleTableView reloadData];
			[self.bubbleTableView scrollToBottomWithAnimation:NO];
		});

		// update data
		[self appendDataFrom:0 date:[NSDate date]];
		
	}];
}


#pragma mark <LibTG Functions>
static int messages_callback(void *d, const tg_message_t *m){
	NSDictionary *dict = d; //@{@"self":self, @"update": @1};
	ChatViewController *self = [dict objectForKey:@"self"];
	NSNumber *update = [dict objectForKey:@"update"];

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
				
				// init TGMessage
				item.message = [[TGMessage alloc]initWithMessage:m];
				
				if (m->photo_id){
					[self getPhotoForMessageCached:item 
						download:[update boolValue]];
				} else if (m->doc_id){
					[self getDocumentForMessage:item];
				}
			});
		} else {
			item = [NSBubbleData alloc]; 
			if (self.dialog.peerType == TG_PEER_TYPE_CHANNEL)
				item.width = 280;

			NSBubbleType type = 
						(m->from_id_ == self.appDelegate.authorizedUser->id_)?
						BubbleTypeMine:BubbleTypeSomeoneElse;
		
			// init TGMessage
			item.message = [[TGMessage alloc]initWithMessage:m];
			
			dispatch_sync(dispatch_get_main_queue(), ^{
				if (m->photo_id){
					[self getPhotoForMessageCached:item 
						download:[update boolValue]];
				} else if (m->doc_id){
					[self getDocumentForMessage:item];
				}
					
				if (item.message.photo){
					NSString *text = nil;
					if (item.message.message)
						text = item.message.message;
					
					[item initWithImage:item.message.photo 
							date:item.message.date 
							type:type text:text];
					
					if (m->doc_id && item.message.docFileName)
						item.titleLabel.text = item.message.docFileName;
					
					if (m->doc_id){
						float size = m->doc_size;
						if (m->doc_size/1048576 > 0) 
							item.sizeLabel.text = 
								[NSString stringWithFormat:@"%.2f Mb", 
									size/1048576];
						else if (m->doc_size/1024 > 0) 
							item.sizeLabel.text = 
								[NSString stringWithFormat:@"%.2f Kb", 
									size/1024];
						else
							item.sizeLabel.text = 
								[NSString stringWithFormat:@"%lld", 
									m->doc_size];
					}

				} else {
					[item initWithText:item.message.message
							date:item.message.date 
							type:type];
				}

				// add to array
				[self.bubbleDataArray addObject:item];
			});
		} // end if (item)
	}

	return 0;
}

int get_document_cb(void *d, const tg_file_t *f){
	NSDictionary *dict = d;
	ChatViewController *self = [dict objectForKey:@"self"];
	NSMutableData *data = [dict objectForKey:@"d"];
	[data appendBytes:f->bytes_.data length:f->bytes_.size];
	self.progressCurrent += f->bytes_.size;
	return 0;
}

int get_document_progress(void *d, int size, int total){
	ChatViewController *self = d;
	dispatch_sync(dispatch_get_main_queue(), ^{
		int downloaded = self.progressCurrent + size;
		float fl = (float)downloaded / self.progressTotal;
		[self.progressView setProgress:fl];
		self.progressLabel.text = 
			[NSString stringWithFormat:@"%d /\n%d",
				downloaded, self.progressTotal];
	});
	return 0;
}

#pragma mark <UIBubbleTableViewDelegate>
-(void)getDoc:(NSBubbleData *)data{
	TGMessage *m = data.message;
	
	NSString *filepath;
	if (m.isVoice){
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.ogg", 
		m.docId]];
	} else {
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.%@", 
		m.docId, m.docFileName]];
	}
	
	NSURL *url = [NSURL fileURLWithPath:filepath]; 
		if ([NSFileManager.defaultManager fileExistsAtPath:filepath]){
				QuickLookController *qlc = [[QuickLookController alloc]
					initQLPreviewControllerWithData:@[url]];	
				[self presentViewController:qlc animated:TRUE completion:nil];
		} else {
			// download file
			//if (data.spinner)
				//[data.spinner startAnimating]; 

			[self toolbarAsProgress];
			[self.progressView setProgress:0.0];
			[self.progressLabel 
				setText:[NSString stringWithFormat:@"%d /\n%lld",
				0, m.docSize]];

			[self.download addOperationWithBlock:^{
				NSMutableData *d = [NSMutableData data];
				NSDictionary *dict = @{@"self":self, @"d":d};
				self.progressTotal = m.docSize;
				self.progressCurrent = 0;
				tg_get_document(
						self.appDelegate.tg, 
						m.docId,
						m.docSize, 
						m.docAccessHash, 
						[m.docFileReference UTF8String], 
						"", 
						dict, 
						get_document_cb,
						self,
						get_document_progress);

				// on done
				if (data.spinner){
					dispatch_sync(dispatch_get_main_queue(), ^{
						[self toolbarAsEntry];
						//[data.spinner stopAnimating]; 
					});
				}
				if (d.length > 0){
					[d writeToFile:filepath atomically:YES];
					dispatch_sync(dispatch_get_main_queue(), ^{
						QuickLookController *qlc = [[QuickLookController alloc]
							initQLPreviewControllerWithData:@[url]];	
						[self presentViewController:qlc 
															 animated:TRUE completion:nil];
					});
				} else { // no data
					dispatch_sync(dispatch_get_main_queue(), ^{
						[self.appDelegate 
							showMessage:@"can't download file"];
					});
				}
			}];
	}
}

-(void)getPhoto:(NSBubbleData *)data{
	TGMessage *m = data.message;
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
			if (data.spinner)
				[data.spinner startAnimating]; 

			[self.syncData addOperationWithBlock:^{
				char *photo = tg_get_photo_file(
						self.appDelegate.tg, 
						m.photoId, 
						m.photoAccessHash, 
						[m.photoFileReference UTF8String], 
						"x"); 

				// on done
				if (data.spinner){
					dispatch_sync(dispatch_get_main_queue(), ^{
						[data.spinner stopAnimating]; 
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

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectData:(NSBubbleData *)data 
{
	TGMessage *m = data.message;
	if (m){
		if (m.photoId){
			[self getPhoto:data];
		}	else if (m.docId){
			[self getDoc:data];
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
