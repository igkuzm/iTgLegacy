#import "ChatViewController.h"
#include <stdint.h>
#import <MobileCoreServices/MobileCoreServices.h>
#include "opus/include/opus/opus_defines.h"
#include "CoreAudio/CoreAudioTypes.h"
#include "AudioToolbox/AudioToolbox.h"
#include "AudioToolbox/AudioServices.h"
#include "AudioToolbox/AudioFile.h"
#import "AVFoundation/AVFoundation.h"
#import "AVFoundation/AVAudioSession.h"
#import "CoreMedia/CoreMedia.h"
#include <stdio.h>
#include "MediaPlayer/MediaPlayer.h"
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
#include "../libtg/tg/user.h"
#include "../libtg/tg/channel.h"
#include "../libtg/tg/updates.h"
#include "../libtg/tg/messages.h"
#include "../libtg/tg/files.h"
#include "../libtg/tg/queue.h"
#include "UIImage+Utils/UIImage+Utils.h"
#include "opus/include/opus/opus.h"
#include "opusenc/opusenc.h"
#include "opusfile/opusfile.h"
#include "../libtg/tools/cafextract.h"
#include "../libtg/tools/pcm_to_opusogg.h"

@interface  ChatViewController()
{
}
@property float toolbarOrigY;
@end

@implementation ChatViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	self.title = self.dialog.title;
	
	self.appDelegate = UIApplication.sharedApplication.delegate;
	self.appDelegate.authorizationDelegate = self;
	self.appDelegate.appActivityDelegate = self;
	
	self.syncData = [[NSOperationQueue alloc]init];
	self.syncData.maxConcurrentOperationCount = 1;
	self.download = [[NSOperationQueue alloc]init];
	//self.download.maxConcurrentOperationCount = 1;

	//self.moviePlayerController = 
		//[[MPMoviePlayerViewController alloc]init];
	
	// system sound
	NSString *recordStartPath = 
		[NSString stringWithFormat:@"%@/102.m4a", NSBundle.mainBundle];
	SystemSoundID recordStart;
	AudioServicesCreateSystemSoundID(
			(__bridge CFURLRef)[NSURL fileURLWithPath:recordStartPath],
		 	&recordStart);
	self.recordStart = recordStart;

	// set background
	self.view.backgroundColor = 
		[UIColor colorWithPatternImage:
			[UIImage imageNamed:@"wallpaper.jpg"]];

	// bubble table view
	self.bubbleTableView = 
			[[UIBubbleTableView alloc]initWithFrame:
			self.view.bounds
			style:UITableViewStylePlain];
	self.bubbleTableView.autoresizingMask = 
		UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
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
	self.textFieldIsEditable = YES; // testing
	self.textField = [[UITextField alloc]
	//self.textField = [[UITextView alloc]
		initWithFrame:CGRectMake(
				0,0,
				self.navigationController.toolbar.frame.size.width - 110, 
				29)];
	self.textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
	//[self.textField.layer setCornerRadius:14.0f];
	self.textField.delegate = self;
	//self.textField.inputAccessoryView = self.navigationController.toolbar;
	self.textFieldItem = [[UIBarButtonItem alloc] 
		initWithCustomView:self.textField];
	
	self.flexibleSpace = [[UIBarButtonItem alloc] 
		initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		target:nil action:nil];
		
	self.attach = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"InputAttachmentsSeparatorAttachments"]	
		style:UIBarButtonItemStylePlain 
		target:self action:@selector(onAdd:)];

	self.send = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"Send"]	
		style:UIBarButtonItemStyleDone 
		target:self action:@selector(onSend:)];

	//UISwitch *record = [[UISwitch alloc] initWithFrame:
		//CGRectMake(0, 0, 30, 30)];
	//[record setOffImage:[UIImage imageNamed:@"record"]];
	//[record addTarget:self 
						 //action:@selector(recordSwitch:) 
	 //forControlEvents:UIControlEventValueChanged];

	//self.record = [[UIBarButtonItem alloc]
		//initWithCustomView:record];
	
	self.record = [[UIBarButtonItem alloc]
		initWithImage:[UIImage imageNamed:@"ios-mic-32"] 
						style:UIBarButtonItemStyleBordered
					 target:self action:@selector(recordSwitch:)];
	
	//self.add = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"UIButtonBarAction"] 
						//style:UIBarButtonItemStylePlain
						//target:self action:@selector(onAdd:)];
	
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
	[super viewWillAppear:animated];
	// add timer
	self.timer = [NSTimer 
		scheduledTimerWithTimeInterval:60 
		target:self selector:@selector(timer:) 
		userInfo:nil repeats:YES];

	// hide toolbar if channel
	if (self.dialog.broadcast)
	{
		[self toolbarForChannel];
	}

	// set icon
	self.icon = [[UIImageView alloc]
		initWithFrame:CGRectMake(
		0, 0,
		30, 30)];
	UIBarButtonItem *iconItem = [[UIBarButtonItem alloc]
		initWithCustomView:self.icon];
	self.navigationItem.rightBarButtonItem = iconItem;
	UIImage *image;
	NSString *photoPath = 
			[NSString stringWithFormat:@"%@/%lld.%lld", 
				self.appDelegate.peerPhotoCache, 
				self.dialog.peerId, self.dialog.photoId]; 
		if ([NSFileManager.defaultManager fileExistsAtPath:photoPath])
			image = [UIImage 
				imageWithData:[NSData dataWithContentsOfFile:photoPath]];
		else
			image = [UIImage imageNamed:@"missingAvatar.png"]; 
	self.icon.image = [UIImage imageWithImage:image 
			scaledToSize:CGSizeMake(30, 30)];


	// set updates handler
	if (self.appDelegate.tg){
		self.appDelegate.tg->on_update_data = (__bridge void *)self;
		self.appDelegate.tg->on_update = on_update;
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[self.textField endEditing:YES];
	[self.textField resignFirstResponder];
	//[self cancelAll];
	[self.icon removeFromSuperview];
	// remove updates handler
	if (self.appDelegate.tg)
		self.appDelegate.tg->on_update = NULL;
	
	[super viewWillDisappear:animated];
}

- (void)cancelAll{
	[self.spinner stopAnimating];
	if (self.refreshControl)
		[self.refreshControl endRefreshing];
	if (self.appDelegate.tg)
		tg_queue_cancell_all(self.appDelegate.tg);
	[self.syncData cancelAllOperations];
	[self.download cancelAllOperations];
}

-(void)toolbarForChannel{
	[self 
		setToolbarItems:nil 
	  animated: YES];
}

-(void)toolbarAsEntry{
	[self 
		setToolbarItems:@[
											self.flexibleSpace,
											self.attach, 
											self.flexibleSpace,
											self.textFieldItem, 
											self.flexibleSpace,
											self.record,
											self.flexibleSpace]
		animated:YES];
}

-(void)toolbarAsEntryTyping{
	[self 
		setToolbarItems:@[
											self.flexibleSpace,
											self.attach, 
											self.flexibleSpace,
											self.textFieldItem, 
											self.flexibleSpace,
											self.send,
											self.flexibleSpace]
		animated:YES];
}

-(void)toolbarAsProgress{
	[self 
		setToolbarItems:@[self.progress, 
											self.label, 
											self.flexibleSpace,
											self.cancel,
											self.flexibleSpace]
		animated:YES];
}

-(void)timer:(id)sender{
	// do timer funct
	//[self cancelAll];
	if (self.appDelegate.isOnLineAndAuthorized)
	{
		[self.syncData addOperationWithBlock:^{
			[self appendDataFrom:0 date:[NSDate date] scrollToBottom:NO];
		}];
	}
}

- (void)onSend:(id)sender{
	NSString *text = self.textField.text;
	if (self.appDelegate.isOnLineAndAuthorized)
	{
		[self.syncData addOperationWithBlock:^{
			tg_peer_t peer = {
					self.dialog.peerType, 
					self.dialog.peerId, 
					self.dialog.accessHash
			};
			pthread_t p = tg_message_send(
					self.appDelegate.tg, 
					peer, text.UTF8String);
			pthread_join(p, NULL);
			[self appendDataFrom:0 date:[NSDate date] scrollToBottom:YES];
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
		initWithTitle:@"Send" 
		delegate:self 
		cancelButtonTitle:@"cancel" 
		destructiveButtonTitle:nil 
		otherButtonTitles:
			@"file",
			@"camera",
			@"image/video",
			@"geopoint",
		nil];
	[as showFromToolbar:self.navigationController.toolbar];
}

- (void)onCancel:(id)sender{
	[self.download cancelAllOperations];
	if (self.dialog.broadcast)
		[self toolbarForChannel];
	else
		[self toolbarAsEntry];
}

-(void)refresh:(id)sender{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date] scrollToBottom:NO];
	}];
}

#pragma mark <Data Functions>
-(void)getPhotoForMessageCached:(NSBubbleData *)d
											 download:(Boolean)download{
	if (!d.message.photo)
		d.message.photo = [UIImage imageNamed:@"filetype_icon_png@2x.png"];
	
	if (!download)
		return;
	
	if (self.appDelegate.isOnLineAndAuthorized)
		{
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
				if (d.message.isVoice){
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
					d.videoPlayButton.hidden = NO;
				}
				else if ([d.message.mimeType isEqualToString:@"video/mov"] ||
					  [d.message.docFileName.pathExtension.lowercaseString 
							isEqualToString:@"mov"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mov@2x.png"];
					d.message.isVideo = YES;
					d.videoPlayButton.hidden = NO;
				}
				
				else if ([d.message.mimeType isEqualToString:@"video/mp4"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"mp4"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp4@2x.png"];
					d.message.isVideo = YES;
					d.videoPlayButton.hidden = NO;
				}
				
				else if ([d.message.mimeType isEqualToString:@"audio/ogg"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"ogg"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
					d.message.isVoice = YES;
					d.videoPlayButton.hidden = NO;
				}
				
				else if ([d.message.mimeType isEqualToString:@"audio/mp3"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"mp3"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp3@2x.png"];
					d.videoPlayButton.hidden = NO;
				}
				else if ([d.message.mimeType 
									isEqualToString:@"application/x-pdf"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"pdf"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_pdf@2x.png"];
				}
				else if ([d.message.mimeType 
									isEqualToString:@"application/msword"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"doc"] ||
								 [d.message.mimeType 
									isEqualToString:@"application/vnd.openxmlformats-officedocument.wordprocessingml.document"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"docx"])

				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_doc@2x.png"];
				}
				else if ([d.message.mimeType 
									isEqualToString:@"application/vnd.ms-excel"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"xls"] ||
								 [d.message.mimeType 
									isEqualToString:@"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"xlsx"])

				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_xls@2x.png"];
				}
				else if ([d.message.mimeType 
									isEqualToString:@"application/vnd.ms-popwerpoint"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"ppt"] ||
								 [d.message.mimeType 
									isEqualToString:@"application/vnd.openxmlformats-officedocument.presentationtml.presentation"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"pptx"])

				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_ppt@2x.png"];
				}

				else if (d.message.isVideo)
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_video@2x.png"];
				
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
}

- (void)appendDataFrom:(int)offset date:(NSDate *)date 
		scrollToBottom:(Boolean)scrollToBottom
{
	//[self.syncData cancelAllOperations];
	
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}

	if (self.appDelegate.isOnLineAndAuthorized)
	{
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

		NSDictionary *dict = 
			@{@"self":self, @"update": @1, @"scroll": [NSNumber numberWithBool:scrollToBottom]};

		pthread_t p = tg_messages_get_history_async(
				self.appDelegate.tg, 
				peer, 
				offset, 
				[date timeIntervalSince1970], 
				0, 
				limit, 
				0, 
				0, 
				NULL, 
				(__bridge void*)dict, 
				messages_callback,
				NULL);

		pthread_join(p, NULL);
		
		// on done
		dispatch_sync(dispatch_get_main_queue(), ^{
					[self.refreshControl endRefreshing];
					[self.spinner stopAnimating];
					[self.bubbleTableView reloadData];
					if (scrollToBottom)
						[self.bubbleTableView scrollBubbleViewToBottomAnimated:YES];
		});

		// set read history
		if (peer.type == TG_PEER_TYPE_CHANNEL){
			tg_channel_set_read(
					self.appDelegate.tg, 
					peer, 
					0);
		} else {
			tg_messages_set_read(
					self.appDelegate.tg, 
					peer, 
					0);
		}
	}
}

- (void)reloadData {
	if (!self.appDelegate.tg)
		return;

	//[self.syncData cancelAllOperations];

	// animate spinner
	[self.spinner startAnimating];

	//[self.bubbleDataArray removeAllObjects];

	tg_peer_t peer = {
			self.dialog.peerType,
			self.dialog.peerId,
			self.dialog.accessHash
	};

	[self.syncData addOperationWithBlock:^{
		
		NSDictionary *dict = @{@"self":self, @"update": @0, @"scroll": @0};
		
		tg_get_messages_from_database(
			self.appDelegate.tg, 
			peer, 
			(__bridge void *)dict, 
			messages_callback);

		dispatch_sync(dispatch_get_main_queue(), ^{
			//[self.spinner stopAnimating];
			[self.bubbleTableView reloadData];
			[self.bubbleTableView scrollToBottomWithAnimation:YES];
		});

		// update data
		[self appendDataFrom:0 date:[NSDate date] scrollToBottom:NO];
		
	}];
}


#pragma mark <LibTG Functions>
static void on_update(void *d, int type, void *value)
{
	ChatViewController *self = (__bridge ChatViewController *)d;
	switch (type) {
		case TG_UPDATE_USER_TYPING:
			{
				uint64_t *user_id = value;
				if (self.dialog.peerType == TG_PEER_TYPE_USER &&
						*user_id == self.dialog.peerId)
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.bubbleTableView.typingBubble = 
							NSBubbleTypingTypeSomebody;
						[self.bubbleTableView reloadData];
					});

			}
		case TG_UPDATE_CHAT_USER_TYPING:
			{
				struct {uint64_t chat_id; uint64_t user_id;} *t = value; 
				if (self.dialog.peerId == t->chat_id)
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.bubbleTableView.typingBubble = 
							NSBubbleTypingTypeSomebody;
						[self.bubbleTableView reloadData];
					});
			}
		case TG_UPDATE_USER_RECORD_AUDIO:
			{
				uint64_t *user_id = value;
				if (self.dialog.peerType == TG_PEER_TYPE_USER &&
						*user_id == self.dialog.peerId)
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.bubbleTableView.typingBubble = 
							NSBubbleTypingTypeSomebody;
						[self.bubbleTableView reloadData];
					});
			}
		case TG_UPDATE_USER_RECORD_ROUND:
			{
				uint64_t *user_id = value;
				if (self.dialog.peerType == TG_PEER_TYPE_USER &&
						*user_id == self.dialog.peerId)
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.bubbleTableView.typingBubble = 
							NSBubbleTypingTypeSomebody;
						[self.bubbleTableView reloadData];
					});
			}
		case TG_UPDATE_USER_CANCEL:
			{
				uint64_t *user_id = value;
				if (self.dialog.peerType == TG_PEER_TYPE_USER &&
						*user_id == self.dialog.peerId)
					dispatch_sync(dispatch_get_main_queue(), ^{
						self.bubbleTableView.typingBubble = 
							NSBubbleTypingTypeNobody;
						[self.bubbleTableView reloadData];
					});
			}
	
		default:
			break;
	}
}

static int messages_callback(void *d, const tg_message_t *m){
	
	NSDictionary *dict = (__bridge NSDictionary*)d; //@{@"self":self, @"update": @1};
	ChatViewController *self = [dict objectForKey:@"self"];
	NSNumber *update = [dict objectForKey:@"update"];

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
			item.message = 
				[[TGMessage alloc]initWithMessage:m dialog:self.dialog];
			
			if (m->photo_id){
				[self getPhotoForMessageCached:item 
					download:[update boolValue]];
			} else if (m->doc_id){
				[self getDocumentForMessageChached:item
					download:[update boolValue]];
			}
		});
	} else {
		item = [NSBubbleData alloc]; 
		if (self.dialog.peerType == TG_PEER_TYPE_CHANNEL)
			item.width = 280;

		// init TGMessage
		item.message = 
			[[TGMessage alloc]initWithMessage:m dialog:self.dialog];
		
		NSBubbleType type = 
			item.message.mine?BubbleTypeMine:BubbleTypeSomeoneElse; 
		
		dispatch_sync(dispatch_get_main_queue(), ^{
			
			if (self.dialog.peerType != TG_PEER_TYPE_USER && 
					!item.message.mine)
			{
				// add sender name
				tg_user_t *user = tg_user_get(
					self.appDelegate.tg, m->from_id_);	
				if (user){
					if (user->first_name_)
						item.name = 
							[NSString stringWithUTF8String:user->first_name_];
					else if (user->username_) 	
						item.name = 
							[NSString stringWithFormat:@"@%s", user->username_];
					else 
						item.name = 
							[NSString stringWithFormat:@"id%lld", m->from_id_];

					// set color
					//for	(NSDictionary *c in self.appDelegate.colorset){
						//NSNumber *color_id = [c valueForKey:@"color_id"];
						//if (color_id.intValue == user->color){
							//NSNumber *color = [c valueForKey:@"0"];
							//int rgb = color.intValue;

							//item.nameColor = [UIColor 
								//colorWithRed:rgb & 0xff 
											 //green:(rgb >> 8) & 0xff 
												//blue:(rgb >> 16) & 0xff 
											 //alpha:(rgb >> 24) * 0xff];
							//break;
						//}
					//}
				}
			}	

			if (m->photo_id){
				[self getPhotoForMessageCached:item 
					download:[update boolValue]];
			} else if (m->doc_id){
				[self getDocumentForMessageChached:item
					download:[update boolValue]];
			}
				
			if (item.message.photo &&
					!item.message.isSticker)
			{
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

	return 0;
}

#pragma mark <Files Handler>
int get_document_cb(void *d, const tg_file_t *f){
	NSDictionary *dict = (__bridge NSDictionary *)d;
	ChatViewController *self = [dict objectForKey:@"self"];
	NSMutableData *data = [dict objectForKey:@"d"];

	// write data
	[data appendBytes:f->bytes_.data length:f->bytes_.size];
	
	// update progress view
	self.progressCurrent += f->bytes_.size;
			
	return 0;
}

int get_document_progress(void *d, int size, int total){
	ChatViewController *self = (__bridge ChatViewController *)d;
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

-(void)openUrl:(NSURL *)url data:(NSBubbleData *)bubbleData{
	
	//if (data.message.isVideo || data.message.isVoice){
		NSString *raw =  nil;
		
		// handle with OGG
		if (bubbleData.message.isVoice){
			OggOpusFile *file;
			int error = OPUS_OK;		
			
			// check opus file
			file = op_test_file(url.path.UTF8String, &error);	
			if (file != NULL){
				 error = op_test_open(file);
				 op_free(file);
				 if (error != OPUS_OK){
						[self.appDelegate showMessage:@"not OPUS OGG file"];
						return;
				 }
			} else {
				[self.appDelegate showMessage:@"can't open file"];
				return;
			}

			// read file to NSData
			NSMutableData *data = [NSMutableData data];
			file = op_open_file(url.path.UTF8String, &error);	
			NSAssert(file, @"op_open_file");
			int c = op_channel_count(file, -1);

			opus_int16 pcm[(160*48*c)/2];
			int size = sizeof(pcm)/sizeof(*pcm);
			while (op_read_stereo(file, pcm, size) > 0) 
			{
				[data appendBytes:pcm length:size];
			}

			// convert data to wav
			int readcount=0;
			short NumChannels = 2;
			short BitsPerSample = 16;
			int SamplingRate = 48000;
			short numOfSamples = 160;

			int ByteRate = NumChannels*BitsPerSample*SamplingRate/8;
			short BlockAlign = NumChannels*BitsPerSample/8;
			//int DataSize = NumChannels*numOfSamples *  BitsPerSample/8;
			int DataSize = data.length;
			int chunkSize = 16;
			int totalSize = 36 + DataSize;
			short audioFormat = 1;

			NSString *tmpFile = 
				[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.wav"];
			[NSFileManager.defaultManager removeItemAtPath:tmpFile error:nil];

			FILE *fout;
			if((fout = fopen(tmpFile.UTF8String, "w")) == NULL)
			{
				[self.appDelegate showMessage:@"Error opening out file "];
				return;
			}

			//totOutSample = 0;
			fwrite("RIFF", sizeof(char), 4,fout);
			fwrite(&totalSize, sizeof(int), 1, fout);
			fwrite("WAVE", sizeof(char), 4, fout);
			fwrite("fmt ", sizeof(char), 4, fout);
			fwrite(&chunkSize, sizeof(int),1,fout);
			fwrite(&audioFormat, sizeof(short), 1, fout);
			fwrite(&NumChannels, sizeof(short),1,fout);
			fwrite(&SamplingRate, sizeof(int), 1, fout);
			fwrite(&ByteRate, sizeof(int), 1, fout);
			fwrite(&BlockAlign, sizeof(short), 1, fout);
			fwrite(&BitsPerSample, sizeof(short), 1, fout);
			fwrite("data", sizeof(char), 4, fout);
			fwrite(&DataSize, sizeof(int), 1, fout);

			fwrite(data.bytes, data.length, 1, fout);	
			fclose(fout);

			url = [NSURL fileURLWithPath:tmpFile];

			MPMoviePlayerViewController *mpc = 
				[[MPMoviePlayerViewController alloc]initWithContentURL:url];
			[self presentMoviePlayerViewControllerAnimated:mpc];
			[mpc.moviePlayer prepareToPlay];
			[mpc.moviePlayer play];
			
			return;
		}
			
		QuickLookController *qlc = [[QuickLookController alloc]
			initQLPreviewControllerWithData:@[url]];	
		[self presentViewController:qlc animated:TRUE completion:nil];
}

-(void)getDoc:(NSBubbleData *)data{
	TGMessage *m = data.message;
	
	NSString *filepath;
	if (m.isVoice){
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.ogg", 
		m.docId]];
	} else if (m.isVideo){
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.mp4", 
		m.docId]];
	} else {
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.%@", 
		m.docId, m.docFileName]];
	}
	
	NSURL *url = [NSURL fileURLWithPath:filepath];
	
	unsigned long long fileSize = 
				[[[NSFileManager defaultManager] 
					attributesOfItemAtPath:filepath error:nil] fileSize];

	[data.spinner startAnimating];
			
	if ([NSFileManager.defaultManager fileExistsAtPath:filepath] 
			//&&
			//fileSize >= data.message.docSize
			// check hashes
			)
	{
		[self openUrl:url data:data];
	} else {
		// check connection
		if (!self.appDelegate.tg ||
				!self.appDelegate.authorizedUser ||
				!self.appDelegate.reach.isReachable)
			return;

		// download file
		[self toolbarAsProgress];
		[self.progressView setProgress:0.0];
		[self.progressLabel 
			setText:[NSString stringWithFormat:@"%d /\n%lld",
			0, m.docSize]];
		
		[self.download addOperationWithBlock:^{
		
			// remove file
			[NSFileManager.defaultManager removeItemAtPath:filepath 
																						 error:nil];

			[NSFileManager.defaultManager createFileAtPath:filepath 
								                            contents:nil 
							                            attributes:nil];

			// open stream
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
					(__bridge void *)dict, 
					get_document_cb,
					(__bridge void *)self,
					get_document_progress);
			
			// on done
			[d writeToFile:filepath atomically:YES];
			dispatch_sync(dispatch_get_main_queue(), ^{
				if (self.dialog.broadcast)
					[self toolbarForChannel];
				else
					[self toolbarAsEntry];
				[self openUrl:url data:data];
			});
		}];
	}
	[data.spinner stopAnimating];
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
			if (!self.appDelegate.tg ||
					!self.appDelegate.authorizedUser ||
					!self.appDelegate.reach.isReachable)
				return;

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

#pragma mark <UIBubbleTableViewDelegate>
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
}

- (void)bubbleTableViewDidBeginDragging:(UIBubbleTableView *)bubbleTableView 
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
		[self appendDataFrom:0 date:data.date scrollToBottom:NO];
	}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToBottom:(Boolean)bottom
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date] scrollToBottom:NO];
	}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToTop:(Boolean)top
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:self.bubbleDataArray.count-1 date:[NSDate date] scrollToBottom:NO];
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
#pragma mark <UITextView Delegate>
-(void)textViewDidBeginEditing:(UITextView *)textView {
	//[self.navigationController.toolbar retain];
}

-(void)textViewDidEndEditing:(UITextView *)textView {
	//[self.navigationController.toolbar retain];
	//self.navigationController.toolbar.frame = CGRectMake(
			//0, 
			//self.view.bounds.size.height - 44, 
			//self.view.bounds.size.width, 
			//44);
	//[self.navigationController.toolbar retain];
	//[self.navigationController.view addSubview:self.navigationController.toolbar];
	//[self.navigationController setToolbarHidden:NO];
}

#pragma mark <UITextField Delegate>
- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self toolbarAsEntryTyping];
	if (self.appDelegate.isOnLineAndAuthorized)
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
	[self.bubbleTableView scrollToBottomWithAnimation:YES];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	[self toolbarAsEntry];
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

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	return self.textFieldIsEditable;
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	// get selected item
	switch (buttonIndex){
		case 0:
			{
				FilePickerController *fpc = [[FilePickerController alloc]
					initWithPath:@"/var/mobile" isNew:YES];
				fpc.filePickerControllerDelegate = self;
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
				
				CFStringRef mTypes[2] = { kUTTypeImage, kUTTypeMovie  };
				CFArrayRef mTypesArray = 
					CFArrayCreate(CFAllocatorGetDefault(), (const void**)mTypes, 2, &kCFTypeArrayCallBacks);
				ipc.mediaTypes = (__bridge NSArray*)mTypesArray;
				CFRelease(mTypesArray);
				ipc.videoMaximumDuration = 60.0f;
				ipc.showsCameraControls = YES;
				ipc.allowsEditing = YES;
        [self presentViewController:ipc animated:YES completion:nil];
			}
			break;

		case 2:
			{
				UIImagePickerController *ipc = 
					[[UIImagePickerController alloc] init];
				ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
				ipc.delegate = self;
				CFStringRef mTypes[2] = { kUTTypeImage, kUTTypeMovie  };
				CFArrayRef mTypesArray = 
					CFArrayCreate(CFAllocatorGetDefault(), (const void**)mTypes, 2, &kCFTypeArrayCallBacks);
				ipc.mediaTypes = (__bridge NSArray*)mTypesArray;
				CFRelease(mTypesArray);
				ipc.videoMaximumDuration = 60.0f;
				ipc.allowsEditing = YES;
        [self presentViewController:ipc animated:YES completion:nil];
			}
			break;

		default:
			break;
	}
}	

#pragma mark <UIImagePickerController Delegate>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	
 [self dismissViewControllerAnimated:YES completion:nil];
	 
 // UIImagePickerControllerMediaType
 if([info[UIImagePickerControllerMediaType] isEqualToString:(__bridge NSString *)(kUTTypeImage)]){
    
	//image
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	NSLog(@"UIMAGE: %@", image);
	if (image){
		[self sendPhoto:image];
		UIImageWriteToSavedPhotosAlbum(
				image, self, 
				@selector(image:didFinishSavingWithError:contextInfo:), 
				(__bridge void *)image);
	}

 } else {
    
	//video
	NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];	
	if (url){
		NSString* mimeType = [self mimeTypeFromUrl:url];
	
		[self sendDocument:tg_document(
				self.appDelegate.tg, 
				url.path.UTF8String, 
				url.lastPathComponent.UTF8String, 
				mimeType.UTF8String)
		];
	 }
 }
}

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
	if (error){
		[self.appDelegate showMessage:error.localizedDescription];
		return;
	}
	//[self sendPhoto:image];
} 

#pragma mark <Keyboard Functions>
- (void)keyboardWillShow:(NSNotification *)notification {
		CGSize keyboardSize = [[[notification userInfo] 
			objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

		UIInterfaceOrientation interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;

		float newVerticalPosition;
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
			newVerticalPosition = -keyboardSize.height;
		else 
			newVerticalPosition = -keyboardSize.width;

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
		} else {
				//newVerticalPosition = -keyboardSize.height;
			UIInterfaceOrientation interfaceOrientation = 
				UIApplication.sharedApplication.statusBarOrientation;

			if (UIInterfaceOrientationIsPortrait(interfaceOrientation)){
				toolbarFrame.origin.y = 
					self.appDelegate.window.bounds.size.height -
					self.navigationController.toolbar.bounds.size.height;
			} else {
				toolbarFrame.origin.y = 
					self.appDelegate.window.bounds.size.width -
					self.navigationController.toolbar.bounds.size.height;
			} 
		}

    [UIView animateWithDuration:duration animations:^{
        self.view.frame = frame;
				self.navigationController.toolbar.frame = toolbarFrame;
    }];
}

#pragma mark <Audio Recording>
-(void)startRecording:(id)sender{
	
	// Init audio with record capability
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryRecord error:nil];

	self.recordSettings = [[NSMutableDictionary alloc] 
		initWithCapacity:10];

	[self.recordSettings setObject:
				 [NSNumber numberWithInt: kAudioFormatLinearPCM] 
													forKey: AVFormatIDKey];
	[self.recordSettings setObject:
			 [NSNumber numberWithFloat:48000.0] 
													forKey: AVSampleRateKey];
	[self.recordSettings setObject:
		[NSNumber numberWithInt:1] 
										 forKey:AVNumberOfChannelsKey];
	[self.recordSettings setObject:
		[NSNumber numberWithInt:16] 
										 forKey:AVLinearPCMBitDepthKey];
	[self.recordSettings setObject:
	 [NSNumber numberWithBool:NO] 
										 forKey:AVLinearPCMIsBigEndianKey];
	[self.recordSettings setObject:
	 [NSNumber numberWithBool:NO] 
										 forKey:AVLinearPCMIsFloatKey];

	NSString *tmpFile = 
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.caf"];
	[NSFileManager.defaultManager removeItemAtPath:tmpFile error:nil];
	
	NSURL *url = [NSURL fileURLWithPath: tmpFile];

	NSError *error = nil;
	self.audioRecorder = [[ AVAudioRecorder alloc] 
		initWithURL:url settings:self.recordSettings error:&error];

	if ([self.audioRecorder prepareToRecord] == YES){
		//start recording
		[self.audioRecorder stop];
		// vibration
		AudioServicesPlaySystemSound(
				kSystemSoundID_Vibrate);
		AudioServicesPlaySystemSound(
				self.recordStart);
		// sound
		[self.audioRecorder record];
	}else {
			int errorCode = CFSwapInt32HostToBig ([error code]);
			NSLog(@"Error: %@ [%4.4s])" , 
					[error localizedDescription], (char*)&errorCode);

	}
	NSLog(@"recording");
}

-(void)recordSwitch:(id)sender{
	//UISwitch *s = sender;
	UIBarButtonItem *record = sender;
	if (record.style == UIBarButtonItemStyleBordered){
		record.style = UIBarButtonItemStyleDone;
		self.textFieldIsEditable = NO;
		self.textField.text = @"";
		self.textField.placeholder = @"Recording audio...";
		[self startRecording:nil];
	}
	else {
		record.style = UIBarButtonItemStyleBordered;
		[self stopRecording:nil];
		self.textFieldIsEditable = YES;
		self.textField.text = @"";
		self.textField.placeholder = @"";
	}
}


-(void)sendPhoto:(UIImage *)image {
	NSString *tmpFile = 
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.png"];
	NSData *data = UIImagePNGRepresentation(image);
	[data writeToFile:tmpFile atomically:YES];

	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.appDelegate showMessage:@"no network"];
		});
		return;
	}
	
	tg_document_t *photo = tg_photo(
			self.appDelegate.tg, tmpFile.UTF8String);
	[self sendDocument:photo];
}

-(void)sendVoiceMessage {

	NSString *cafFile = 
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.caf"];
	NSString *oggFile = 
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"tmp.ogg"];
	
	// extract caf file
	FILE *pcm = caf_extract(
			cafFile.UTF8String, 
			NULL);
	if (pcm == NULL){
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.appDelegate showMessage:@"can't extract data from caf file"];
		});
		return;
	}

	// write opus ogg
	int err = pcm_to_opusogg(
			pcm, 
			oggFile.UTF8String, 
			"unknown",
		 	"message", 
			48000.0, 
			1, 
			960);
	if (err){
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.appDelegate showMessage:[NSString 
				stringWithFormat:@"can't encode opus, err: %d", err]];
		});
		return;
	}

	tg_document_t *vm = tg_voice_message(
			self.appDelegate.tg, oggFile.UTF8String);
	[self sendDocument:vm];	
}

- (void)sendDocument:(tg_document_t *)document {
	if (!self.appDelegate.tg ||
			!self.appDelegate.reach.isReachable ||
			!self.appDelegate.authorizedUser)
	{
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.appDelegate showMessage:@"no network"];
		});
		return;
	}
		
	// send
	[self.download addOperationWithBlock:^{
		
		tg_peer_t peer = {
			self.dialog.peerType, 
			self.dialog.peerId, 
			self.dialog.accessHash
		};	
		
		int err = tg_document_send(
				self.appDelegate.tg, 
				&peer, 
				document,
				NULL,
				NULL, NULL);
		
		free(document);
		
		if (err){
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.appDelegate showMessage:@"error to send"];
			});
			return;
		}
		
		// on done
		[self appendDataFrom:0 date:[NSDate date] scrollToBottom:YES];
	}];
}

-(void)stopRecording:(id)sender{
	//[self.appDelegate showMessage:@"STOP"];
	NSLog(@"stopRecording");
	[self.audioRecorder stop];
	NSLog(@"stopped");
	
	[self.appDelegate askYesNo:@"Send voice message?" 
		onYes:^{
			[self sendVoiceMessage];
		}];
}

#pragma mark <AppActivity Delegate>
-(void)willResignActive {
	//[self cancelAll];
	if (self.timer)
		[self.timer fire];
  //[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark <Authorization Delegate>
-(void)tgLibLoaded{
}
-(void)authorizedAs:(tl_user_t *)user{
	[self appendDataFrom:0 date:[NSDate date] scrollToBottom:NO];
}

#pragma mark <FilePickerController Delegate>
-(void)filePickerControllerSelectedURL:(NSURL *)url {
	
	NSString* mimeType = [self mimeTypeFromUrl:url];
	
	[self sendDocument:tg_document(
			self.appDelegate.tg, 
			url.path.UTF8String, 
			url.lastPathComponent.UTF8String, 
			mimeType.UTF8String)
	];
}

-(NSString *)mimeTypeFromUrl:(NSURL *)url{
	NSURLRequest* fileUrlRequest = 
		[[NSURLRequest alloc] initWithURL:url 
													cachePolicy:NSURLCacheStorageNotAllowed 
											timeoutInterval:.1];
	NSError* error = nil;
	NSURLResponse* response = nil;
	NSData* fileData = 
		[NSURLConnection sendSynchronousRequest:fileUrlRequest 
													returningResponse:&response 
																			error:&error];
	return [response MIMEType];
}

@end
// vim:ft=objc
