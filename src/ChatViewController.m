#import "ChatViewController.h"
#include "TGVideoPlayer.h"
#include "ChatBox.h"
#include "CoreLocation/CoreLocation.h"
#include "MapKit/MapKit.h"
#include "AddressBook/AddressBook.h"
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
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define kStatusBarHeight 20
#define kDefaultToolbarHeight 40
#define kKeyboardHeightPortrait 216
#define kKeyboardHeightLandscape 140

@interface  ChatViewController()
{
}
@property (strong) UIColor *defaultBarColor;
@property float toolbarOrigY;
@property int numLines;
@property CGRect toolbarOrigFrame;
@property TGVideoPlayer *videoPlayer;
@end

@implementation ChatViewController


const UIEdgeInsets 
Mine = {1, 10, 11, 17};
const UIEdgeInsets 
Someone = {1, 15, 11, 10};

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

	self.mpc = 
		[[MPMoviePlayerController alloc]init];
	//self.videoPlayer = [[TGVideoPlayer alloc]initWithView:self.view];
	

	self.locationManager = [[CLLocationManager alloc] init];
	
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
	//CGRect viewFrame = self.view.bounds;
	//viewFrame.size.height -= 100;
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
	if (self.dialog.peerType == TG_PEER_TYPE_CHAT ||
			(self.dialog.peerType == TG_PEER_TYPE_CHANNEL &&
			 !self.dialog.broadcast))
	{
		self.bubbleTableView.showAvatars = YES; 
	}
	
	// refresh control
	self.refreshControl= [[UIRefreshControl alloc]init];
	//self.refreshControl.tintColor = [UIColor blackColor];
	NSString *s = @"more messages...";
	NSMutableAttributedString *str = [[NSMutableAttributedString alloc] 
		initWithString:s];
	[str addAttribute:NSForegroundColorAttributeName 
							value:[UIColor whiteColor] range:[s rangeOfString:s]];
	self.refreshControl.attributedTitle = str;

	[self.refreshControl 
		addTarget:self 
		action:@selector(loadMoreMessages:) 
		forControlEvents:UIControlEventValueChanged];
	[self.bubbleTableView addSubview:self.refreshControl];

	// footer
	//UIView* footerView = 
		//[[UIView alloc] initWithFrame:CGRectMake(
				//0, 0, 320, 50)];
	//[footerView setBackgroundColor:[UIColor 
					 //colorWithPatternImage:[UIImage 
											//imageNamed:@"refreshImage.png"]]];
	//self.bubbleTableView.tableFooterView = footerView;
	//self.bubbleTableView.tableFooterView.hidden = YES;

	// ToolBar
	//self.navigationController.toolbar.tintColor = [UIColor lightGrayColor];
	//self.textFieldIsEditable = YES; // testing
	//self.textField = [[UITextField alloc]
	////self.textField = [[UITextView alloc]
		//initWithFrame:CGRectMake(
				//0,0,
				//self.navigationController.toolbar.frame.size.width - 110, 
				////34)];
				//30)];
	//self.textField.autoresizingMask = 
		//UIViewAutoresizingFlexibleWidth|
		//UIViewAutoresizingFlexibleHeight;
	//[self.textField setBorderStyle:UITextBorderStyleRoundedRect];
	////[self.textField.layer setCornerRadius:12.0f];
	//self.textField.delegate = self;
	////self.textField.font = [UIFont systemFontOfSize:14];
	////self.textField.inputAccessoryView = self.navigationController.toolbar;
	//self.numLines = 1;
	//self.textFieldItem = [[UIBarButtonItem alloc] 
		//initWithCustomView:self.textField];
	
	//self.flexibleSpace = [[UIBarButtonItem alloc] 
		//initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
		//target:nil action:nil];
		
	//self.attach = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"InputAttachmentsSeparatorAttachments"]	
		//style:UIBarButtonItemStylePlain 
		//target:self action:@selector(onAdd:)];

	//self.send = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"Send"]	
		//style:UIBarButtonItemStyleDone 
		//target:self action:@selector(onSend:)];
	//self.send.customView.autoresizingMask = 
		//UIViewAutoresizingFlexibleTopMargin;

	//UISwitch *record = [[UISwitch alloc] initWithFrame:
		//CGRectMake(0, 0, 30, 30)];
	//[record setOffImage:[UIImage imageNamed:@"record"]];
	//[record addTarget:self 
						 //action:@selector(recordSwitch:) 
	 //forControlEvents:UIControlEventValueChanged];

	//self.record = [[UIBarButtonItem alloc]
		//initWithCustomView:record];
	
	//self.record = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"ios-mic-32"] 
						//style:UIBarButtonItemStyleBordered
					 //target:self action:@selector(recordSwitch:)];
		//self.add = [[UIBarButtonItem alloc]
		//initWithImage:[UIImage imageNamed:@"UIButtonBarAction"] 
						//style:UIBarButtonItemStylePlain
						//target:self action:@selector(onAdd:)];
	
	//self.cancel = [[UIBarButtonItem alloc]
		//initWithBarButtonSystemItem:UIBarButtonSystemItemCancel 
		//target:self action:@selector(onCancel:)];

	//self.progressLabel = [[UILabel alloc]
		//initWithFrame:CGRectMake(0, 0, 60, 40)];
	//self.progressLabel.numberOfLines = 2;
	//self.progressLabel.lineBreakMode = NSLineBreakByCharWrapping;
	//self.progressLabel.backgroundColor = [UIColor clearColor];
	//self.progressLabel.font = [UIFont systemFontOfSize:8];
	//self.label = [[UIBarButtonItem alloc]
		//initWithCustomView:self.progressLabel];

	//self.progressView = [[UIProgressView alloc]
		//initWithProgressViewStyle:UIProgressViewStyleBar];
	//self.progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	//self.progress = [[UIBarButtonItem alloc]
		//initWithCustomView:self.progressView];

	////[self.navigationController setToolbarHidden:NO];
	//[self toolbarAsEntry];
    
		// resize bubbleview
		CGRect frame = self.bubbleTableView.frame;
		frame.size.height -= kDefaultToolbarHeight;
		self.bubbleTableView.frame = frame;

		keyboardIsVisible = NO;
		/* Calculate screen size */
		//CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
		self.inputToolbar = [[BHInputToolbar alloc] 
			initWithFrame:CGRectMake(0, 
					self.view.bounds.size.height -
						 kDefaultToolbarHeight, 
					self.view.bounds.size.width, 
					kDefaultToolbarHeight)];
		[self.view addSubview:self.inputToolbar];
		self.inputToolbar.inputDelegate = self;
		self.inputToolbar.autoresizingMask =
			UIViewAutoresizingFlexibleTopMargin|
			UIViewAutoresizingFlexibleWidth;
		self.inputAccessoryToolbar = self.inputToolbar;
	
	if (self.dialog.broadcast)
		[self.inputToolbar setToolbarEmpty];
	else
		[self.inputToolbar setToolbarDefault];

	//ChatBox *cb = [[ChatBox alloc]init];
	//cb.frame = CGRectMake(
			//0, self.view.bounds.size.height - 100, 
			//self.view.bounds.size.width, 
			//40);
	//[self.view addSubview:cb];
	
	// keyboard
	//[[NSNotificationCenter defaultCenter] 
		//addObserver:self selector:@selector(keyboardWillHide:)
		//name:UIKeyboardWillHideNotification object:nil];
	//[[NSNotificationCenter defaultCenter] 
		//addObserver:self selector:@selector(keyboardWillShow:)
		//name:UIKeyboardWillShowNotification object:nil];

	// load data
	[self reloadData];
}

- (void)viewDidUnload
{
  //[[NSNotificationCenter defaultCenter] removeObserver:self];
  [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];


	/* Listen for keyboard */
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	// set updates handler
	if (self.appDelegate.tg){
		self.appDelegate.tg->on_update_data = (__bridge void *)self;
		self.appDelegate.tg->on_update = on_update;
	}

	// add timer
	NSInteger sec = [NSUserDefaults.standardUserDefaults 
		integerForKey:@"chatUpdateInterval"];
	if (sec < 5 || sec > 120)
		sec = 120;
	self.timer = [NSTimer 
		scheduledTimerWithTimeInterval:sec 
		target:self selector:@selector(timer:) 
		userInfo:nil repeats:YES];

	// show navigation bar
	[self.navigationController setNavigationBarHidden:NO animated:YES];

	// hide toolbar if channel
	//if (self.dialog.broadcast)
	//{
		//[self toolbarForChannel];
	//}

	// set icon
	//self.icon = [[UIImageView alloc]
	self.icon = [UIButton buttonWithType:UIButtonTypeCustom];
	self.icon.frame = CGRectMake(
		0, 0,
		30, 30);
	UIBarButtonItem *iconItem = [[UIBarButtonItem alloc]
		initWithCustomView:self.icon];
	self.navigationItem.rightBarButtonItem = iconItem;
	NSString *photoPath = 
			[NSString stringWithFormat:@"%@/%lld.%lld", 
				self.appDelegate.peerPhotoCache, 
				self.dialog.peerId, self.dialog.photoId];
	TGDialog *dialog = self.dialog;
	[self.icon 
		setImageWithSize:CGSizeMake(30, 30) 
		placeholder:[UIImage imageNamed:@"missingAvatar.png"] 
		cachePath:photoPath 
		forState:UIControlStateNormal 
		downloadBlock: ^NSData *{
			return [TGDialog dialogPhotoDownloadBlock:dialog];
		}];
	}

- (void)viewWillDisappear:(BOOL)animated {
	self.inputToolbar.textView.internalTextView.text = @"";
	[self.inputToolbar.textView.internalTextView resignFirstResponder];

	/* No longer listen for keyboard */
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

	//[self cancelAll];
	[self.icon removeFromSuperview];
	// remove updates handler
	if (self.appDelegate.tg){
		self.appDelegate.tg->on_update = NULL;
	}

	if (self.timer)
		[self.timer fire];
	
	[super viewWillDisappear:animated];
}

- (void)cancelAll{
	[self.spinner stopAnimating];
	if (self.refreshControl)
		[self.refreshControl endRefreshing];
	//[self.syncData cancelAllOperations];
	//[self.download cancelAllOperations];
}

//-(void)toolbarForChannel{
	//[self 
		//setToolbarItems:nil 
		//animated: YES];
//}

//-(void)toolbarAsEntry{
	//[self 
		//setToolbarItems:@[
											//self.flexibleSpace,
											//self.attach, 
											//self.flexibleSpace,
											//self.textFieldItem, 
											//self.flexibleSpace,
											//self.record,
											//self.flexibleSpace]
		//animated:YES];
//}

//-(void)toolbarAsEntryTyping{
	//[self 
		//setToolbarItems:@[
											//self.flexibleSpace,
											//self.attach, 
											//self.flexibleSpace,
											//self.textFieldItem, 
											//self.flexibleSpace,
											//self.send,
											//self.flexibleSpace]
		//animated:YES];
//}

//-(void)toolbarAsProgress{
	//[self.navigationController.topViewController.view
		//addSubview:self.progressView];
	////[self 
		////setToolbarItems:@[self.progress, 
											////self.label, 
											////self.flexibleSpace,
											////self.cancel,
											////self.flexibleSpace]
		////animated:YES];
//}

-(void)timer:(id)sender{
	// do timer funct
	//[self cancelAll];
	if (self.appDelegate.isOnLineAndAuthorized)
	{
		[self.syncData addOperationWithBlock:^{
			[self appendDataFrom:0 date:[NSDate date] 
						scrollToBottom:NO];
		}];
	}
}

-(void)attachButtonPressed{
	self.inputToolbar.textView.internalTextView.text = @"";
	[self.inputToolbar.textView.internalTextView resignFirstResponder];
	[self becomeFirstResponder];
	[self onAdd:nil];
}

- (void)onAdd:(id)sender{
	// create actionSheet
	self.actionSheetType = ActionSheetAttach;
	UIActionSheet *as = [[UIActionSheet alloc]
		initWithTitle:@"Send" 
		delegate:self 
		cancelButtonTitle:@"cancel" 
		destructiveButtonTitle:nil 
		otherButtonTitles:
			@"file",
			@"camera",
			@"image/video",
			@"contact",
			@"geopoint",
		nil];
	[as showFromToolbar:self.navigationController.toolbar];
}

- (void)cancelButtonPressed{
	// create actionSheet
	self.actionSheetType = ActionSheetProgress;
	UIActionSheet *as = [[UIActionSheet alloc]
		initWithTitle:@"Send" 
		delegate:self 
		cancelButtonTitle:@"cancel" 
		destructiveButtonTitle:@"stop transfer" 
		otherButtonTitles:
			@"hide transfer",
		nil];
	[as showFromToolbar:self.navigationController.toolbar];
}

- (void)cancelTransfer:(Boolean)drop{
	if (drop){
		[self.download cancelAllOperations];
		self.stopTransfer = YES;
	}

	if (self.dialog.broadcast)
		[self.inputToolbar setToolbarEmpty];
	else
		[self.inputToolbar setToolbarDefault];
}

-(void)loadMoreMessages:(id)sender{
	NSInteger count = self.bubbleDataArray.count;
	// load more messages
	[self.syncData addOperationWithBlock:^{
		[self appendMessagesFrom:count date:[NSDate date] scrollToBottom:NO];
		[self.bubbleTableView reloadData];
		NSInteger delta = self.bubbleDataArray.count - count;
		// now scroll delta messages from top
			int i = 0;
			NSInteger section = 0;
			for (NSArray *s in self.bubbleTableView.bubbleSection)
			{
				NSInteger row = 0;
				for (NSBubbleData *d in s){
					i++;
					if (i == delta){
						NSIndexPath *indexPath = 
							[NSIndexPath indexPathForRow:row inSection:section]; 
						dispatch_sync(dispatch_get_main_queue(), ^{
							[self.bubbleTableView scrollToRowAtIndexPath:indexPath
								atScrollPosition:UITableViewScrollPositionTop 
								animated:NO];
						});

						return;
					}
					
					row++;
				}

				section++;
			}

			// if no messages - just reload data
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.bubbleTableView reloadData];
			});
	}];
}

#pragma mark <Data Functions>
-(void)getPhotoForMessageCached:(NSBubbleData *)d
											 download:(Boolean)download
{
	// get photo size
	CGSize size = {0,0};
	if (d.message.photoSizes){
		// find size with name "x"
		for (NSDictionary *dict in d.message.photoSizes){
			if ([[dict valueForKey:@"type"] isEqualToString:@"x"])
			 size = [[dict valueForKey:@"size"]CGSizeValue];
		}
	}
	
	UIImage *placeholder = 
		[UIImage imageNamed:@"filetype_icon_png@2x.png"];
	if (d.message.photoStripped){
		placeholder = [UIImage imageWithImage:d.message.photoStripped 
															scaledToSize:placeholder.size];
	}
	
	// resize placeholder
	if (size.height > 0 && size.width > 0){
		if (size.width > d.width)
		{
				size.height /= (size.width / d.width);
				size.width = d.width;
		}
		placeholder = [UIImage imageWithImage:placeholder 
														 scaledToSize:size];
	}

	d.message.photo = [UIImage 
		imageWithPlaceholder:placeholder 
		cachePath:d.message.photoPath 
		view:d.imageView 
		downloadBlock:^NSData *(void){
			if (d.message.photoId && !d.message.photoData){
				char *photo  = 
					tg_get_photo_file(
							self.appDelegate.tg, 
							d.message.photoId, 
							d.message.photoAccessHash, 
							d.message.photoFileReference.UTF8String, 
							"x");
				if (photo){
					d.message.photoData = [NSData dataFromBase64String:
							[NSString stringWithUTF8String:photo]];
					d.message.photo = [UIImage imageWithData:d.message.photoData];
					free(photo);
					//d.imageView.image = d.message.photo;
					return d.message.photoData;
				}
			}
			return NULL;
		} 
		onUpdate:^(UIImage *image){
			 if (image){
				 [d initWithImage:image 
					           date:d.date 
					           type:d.type
					           text:d.message.message];
				 [self.bubbleTableView reloadData];
			 }
		}];
}

-(void)getDocumentForMessageChached:(NSBubbleData *)d
											 download:(Boolean)download{
	// add image placeholder to BubbleData
	switch (d.message.mediaType) {
		case id_messageMediaDocument:
			{
				if (d.message.isVoice){
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
					//d.videoPlayButton.hidden = NO;
					d.showPlayButton = YES;
				}
				else if ([d.message.mimeType isEqualToString:@"video/mov"] ||
					  [d.message.docFileName.pathExtension.lowercaseString 
							isEqualToString:@"mov"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mov@2x.png"];
					d.message.isVideo = YES;
					d.showPlayButton = YES;
				}

				else if ([d.message.mimeType isEqualToString:@"text/html"] ||
					  [d.message.docFileName.pathExtension.lowercaseString 
							isEqualToString:@"html"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_txt@2x.png"];
				}

				else if ([d.message.mimeType isEqualToString:@"video/mp4"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"mp4"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp4@2x.png"];
					d.message.isVideo = YES;
					d.showPlayButton = YES;
				}
				
				else if ([d.message.mimeType isEqualToString:@"audio/ogg"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"ogg"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_audio@2x.png"];
					d.message.isVoice = YES;
					d.showPlayButton = YES;
				}
				
				else if ([d.message.mimeType isEqualToString:@"audio/mp3"] ||
						     [d.message.docFileName.pathExtension.lowercaseString 
									isEqualToString:@"mp3"])
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_mp3@2x.png"];
					d.showPlayButton = YES;
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
				{
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_video@2x.png"];
					d.showPlayButton = YES;
				}
				
				else
					d.message.photo = 
						[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];


				// try to load video placeholder
					CGSize size = {0,0};
					// find size with name "v" - video preview
					if (d.message.videoSizes.count){
						for (NSDictionary *dict in d.message.videoSizes){
							if ([[dict valueForKey:@"type"] isEqualToString:@"v"])
							 size = [[dict valueForKey:@"size"]CGSizeValue];
						}
					}
					
					UIImage *placeholder = d.message.photo;
					if (d.message.photoStripped){
							placeholder = [UIImage 
								imageWithImage:d.message.photoStripped 
								scaledToSize:placeholder.size];
					}

					d.message.photo = [UIImage 
						imageWithPlaceholder:placeholder 
						cachePath:d.message.videoThumbPath 
						view:d.imageView 
						downloadBlock:^NSData *(void){
							if (d.message.docId && !d.message.photoData){
								//NSLog(@"GET DOCUMENT THUMB!");
								char *photo  = 
									tg_get_document_thumb(
											self.appDelegate.tg, 
											d.message.docId, 
											d.message.docAccessHash, 
											d.message.docFileReference.UTF8String, 
											"m");
								//NSLog(@"GOT DOCUMENT THUMB: %s", 
																//photo?"OK":"NULL");
								if (photo){
									d.message.photoData = [NSData dataFromBase64String:
											[NSString stringWithUTF8String:photo]];
									d.message.photo = [UIImage imageWithData:d.message.photoData];
									free(photo);
									//d.imageView.image = d.message.photo;
									return d.message.photoData;
								}
							}
							return NULL;
						} 
						onUpdate:^(UIImage *image){
							 if (image){
								 [d initWithImage:image 
														 date:d.date 
														 type:d.type
														 text:d.message.message];
								 [self.bubbleTableView reloadData];
							 }
						}];
			}
			break;
		case id_messageMediaGeo:
			{
				d.message.photo = 
					[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];
			}
			break;
	
		case id_messageMediaContact:
			{
				d.message.photo = 
					[UIImage imageWithImage:[UIImage 
									 imageNamed:@"missingAvatar.png"] 
								 scaledToSize:CGSizeMake(20, 20)];
			}
			break;
	

		default:
				d.message.photo = 
					[UIImage imageNamed:@"filetype_icon_unknown@2x.png"];
			break;
	} // end switch (d.message.mediaType)
}

- (void)appendMessagesFrom:(int)offset date:(NSDate *)date 
		scrollToBottom:(Boolean)scrollToBottom
{
	//[self.syncData cancelAllOperations];
	
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}
	
	if (!self.appDelegate.isOnLineAndAuthorized){
		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.appDelegate showMessage:@"no network!"];
		});
		return;
	}
	
	tg_new_session(self.appDelegate.tg);

	dispatch_sync(dispatch_get_main_queue(), ^{
		[self.spinner startAnimating];
	});

	tg_peer_t peer = {
		self.dialog.peerType,
		self.dialog.peerId,
		self.dialog.accessHash
	};

	int limit = self.dialog.broadcast?5:10;
		//peer.type == TG_PEER_TYPE_CHANNEL?10:10;

	NSDictionary *dict = 
		@{@"self":self, @"update": @1, @"scroll": [NSNumber numberWithBool:scrollToBottom]};

	tg_messages_get_history(
			self.appDelegate.tg, 
			peer, 
			0, 
			date?[date timeIntervalSince1970]:0, 
			offset, 
			limit, 
			0, 
			0, 
			NULL, 
			(__bridge void*)dict, 
			messages_callback);

	// on done
	dispatch_sync(dispatch_get_main_queue(), ^{
				[self.refreshControl endRefreshing];
				[self.spinner stopAnimating];
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

	self.dialog.unread_count = 0;
	[self.appDelegate removeUnredId:self.dialog.peerId];
}

- (void)appendDataFrom:(int)offset date:(NSDate *)date 
		scrollToBottom:(Boolean)scrollToBottom
{
	Boolean scrollAnimated = self.bubbleDataArray.count?YES:NO;

	[self appendMessagesFrom:offset 
											date:date scrollToBottom:scrollToBottom];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		[self.bubbleTableView reloadData];
		if (scrollToBottom)
			[self.bubbleTableView 
				scrollBubbleViewToBottomAnimated:scrollAnimated];
	});
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
		
		//NSDictionary *dict = @{@"self":self, @"update": @0, @"scroll": @0};
		
		//tg_get_messages_from_database(
			//self.appDelegate.tg, 
			//peer, 
			//(__bridge void *)dict, 
			//messages_callback);

		//dispatch_sync(dispatch_get_main_queue(), ^{
			////[self.spinner stopAnimating];
			//[self.bubbleTableView reloadData];
			//[self.bubbleTableView scrollToBottomWithAnimation:YES];
		//});

		// update data
		[self appendDataFrom:0 date:[NSDate date] 
					scrollToBottom:YES];
		
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
						//[self.bubbleTableView scrollToBottomWithAnimation:YES];
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
						//[self.bubbleTableView scrollToBottomWithAnimation:YES];
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
						//[self.bubbleTableView scrollToBottomWithAnimation:YES];
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
						//[self.bubbleTableView scrollToBottomWithAnimation:YES];
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
		
			//if (item.message.isService){
				//// update message
				//[item initWithServiceMessage:item.message.message 
															//date:item.message.date];
			//} else {
				if (m->photo_id){
					[self getPhotoForMessageCached:item 
						download:[update boolValue]];
				} else if (m->doc_id || 
						m->media_type == id_messageMediaContact)
				{
					[self getDocumentForMessageChached:item
						download:[update boolValue]];
				} else if (m->media_type == id_messageMediaGeo){

				}
			//} // not service message
		});
	} else {
		item = [NSBubbleData alloc]; 
		item.showPlayButton = NO;

		item.delegate = self;

		if (self.dialog.broadcast)
			item.width = 280;

		// init TGMessage
		item.message = 
			[[TGMessage alloc]initWithMessage:m dialog:self.dialog];

		//if (item.message.isService){
			//dispatch_sync(dispatch_get_main_queue(), ^{
				//[item initWithServiceMessage:item.message.message 
																//date:item.message.date];
			//});
			//return 0;
		//}
		
		NSBubbleType type = 
			item.message.mine?BubbleTypeMine:BubbleTypeSomeoneElse; 
		
			
			if (self.dialog.peerType != TG_PEER_TYPE_USER && 
					!item.message.mine && !item.message.isBroadcast)
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
					if (self.appDelegate.colorset.count){
						for	(NSDictionary *c in self.appDelegate.colorset){
							NSNumber *color_id = [c valueForKey:@"color_id"];
							if (color_id.intValue == user->color){
								NSNumber *color = [c valueForKey:@"rgb0"];
								int rgb = color.intValue;

								item.nameColor = [UIColor colorFromHex:rgb];

								break;
							}
						}
					}

					// add avatar
					if (self.bubbleTableView.showAvatars){

							NSString *photoPath = 
							[NSString stringWithFormat:@"%@/%lld.%lld", 
								self.appDelegate.peerPhotoCache, 
								user->id_, user->photo_id];
						
								tg_peer_t peer = {
										TG_PEER_TYPE_USER,
										user->id_,
										user->access_hash_
								};

							item.avatar = [UIImage 
								imageWithPlaceholder:
								 [UIImage imageNamed:@"missingAvatar.png"] 
								cachePath:photoPath 
								view:nil 
								downloadBlock:^NSData *(void){
									if (!self.appDelegate.isOnLineAndAuthorized)
											return nil;
									char *photo = tg_get_peer_photo_file(
												self.appDelegate.tg, 
												&peer, 
												false, 
												user->photo_id);
									if (photo){
										NSData *data = [NSData 
											dataFromBase64String:
												[NSString stringWithUTF8String:photo]];
										return data;
									}
									return nil;
								} 
								onUpdate:^(UIImage *image){
					 
								}];
							

						}
						
					// free user
					tg_user_free(user);	
					}
				}

			if (m->photo_id){
				[self getPhotoForMessageCached:item 
					download:[update boolValue]];
			//} else if (item.message.isVoice) { 
				// do not add photo to voice	
				
			} else if (m->doc_id || 
					m->media_type == id_messageMediaContact)
			{
				[self getDocumentForMessageChached:item
					download:[update boolValue]];
			}
				
		dispatch_sync(dispatch_get_main_queue(), ^{

			if (item.message.photo &&
					!item.message.isSticker)
			{
				NSString *text = nil;
				if (item.message.message)
					text = item.message.message;
				
				[item initWithImage:item.message.photo 
						date:item.message.date 
						type:type text:text];
				
				if ((m->doc_id && item.message.docFileName) 
						|| m->media_type == id_messageMediaContact)
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

			//} else if (item.message.isVoice) { 
				//// setup voice
				//NSString *filepath = [self.appDelegate.filesCache 
					//stringByAppendingPathComponent:
						//[NSString stringWithFormat:@"%lld.ogg", item.message.docId]];
				//item.mpc = 
					//[[MPMoviePlayerController alloc]init];
				//[item.mpc setControlStyle:MPMovieControlStyleEmbedded];
				//[item.mpc setScalingMode:MPMovieScalingModeFill];
				//item.mpc.view.frame = CGRectMake(
						//0, 0, 220, 60);

				//[item initWithView:item.mpc.view 
							//date:item.message.date 
							//type:type 
							//insets:item.message.mine?Mine:Someone];
				
				//item.mpc.view.hidden = YES;
				
				//if ([NSFileManager.defaultManager fileExistsAtPath:filepath])
				//{
					//item.mpc.contentURL = [NSURL fileURLWithPath:filepath];
					//[item.mpc prepareToPlay];
					//item.mpc.view.hidden = NO;
				//}

			} else if (m->media_type == id_messageMediaGeo) {
				UIView *view = [[UIView alloc]init];
				view.frame = CGRectMake(
						0, 0, 200, 120);
				MKMapView *mv = [[MKMapView alloc]init]; 
				mv.frame = CGRectMake(
						10, 10, 180, 100);
				[view addSubview:mv];
				CLLocationCoordinate2D lc;
				lc.latitude = item.message.geoLat;
				lc.longitude = item.message.geoLong;
				//[mv setCenterCoordinate:lc];


				[item initWithView:view 
							date:item.message.date 
							type:type 
							insets:item.message.mine?Mine:Someone];

			} else {
				[item initWithImage:nil 
											 date:item.message.date 
											 type:type 
											 text:item.message.message];
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

	// video
	//NSUUID *uuid = [[NSUUID alloc]init];
	//NSString *tmp = [NSTemporaryDirectory() 
		//stringByAppendingPathComponent:uuid.UUIDString];
	//NSData *dd = [NSData dataWithBytes:f->bytes_.data 
															//length:f->bytes_.size];
	//[dd writeToFile:tmp atomically:YES];
	//dispatch_sync(dispatch_get_main_queue(), ^{
			//[self.videoPlayer addUrl:[NSURL fileURLWithPath:tmp]];
	//});
			
	return 0;
}

int download_progress(void *d, int size, int total){
	ChatViewController *self = (__bridge ChatViewController *)d;
	dispatch_sync(dispatch_get_main_queue(), ^{
		int downloaded = self.progressCurrent + size;
		float fl = (float)downloaded / self.progressTotal;
		[self.inputToolbar.progressView setProgress:fl];
		self.inputToolbar.progressLabel.text = 
			[NSString stringWithFormat:@"%d /\n%d",
				downloaded, self.progressTotal];
	});
	return self.stopTransfer;
}

int upload_progress(void *d, int size, int total){
	ChatViewController *self = (__bridge ChatViewController *)d;
	dispatch_sync(dispatch_get_main_queue(), ^{
		self.progressCurrent += size;
		float fl = (float)self.progressCurrent / total;
		[self.inputToolbar.progressView setProgress:fl];
		self.inputToolbar.progressLabel.text = 
			[NSString stringWithFormat:@"%d /\n%d",
				self.progressCurrent, total];
	});
	return self.stopTransfer;
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

			NSUUID *uuid = [[NSUUID alloc]init];
			NSString *tmpFile = [NSTemporaryDirectory() 
				stringByAppendingPathComponent:
				[NSString stringWithFormat: @"%@.wav", uuid.UUIDString]];

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

			[self.appDelegate setupPlayAndRecordAudioSession];
			MPMoviePlayerViewController *mpc = 
				[[MPMoviePlayerViewController alloc]initWithContentURL:url];
			[self presentMoviePlayerViewControllerAnimated:mpc];
			[mpc.moviePlayer prepareToPlay];
			[mpc.moviePlayer play];

			//[self.mpc.view removeFromSuperview];

			//self.mpc = 
				//[[MPMoviePlayerController alloc]init];
			//[self.mpc setControlStyle:MPMovieControlStyleDefault];
			//[self.mpc setScalingMode:MPMovieScalingModeFill];
			//CGRect frame = bubbleData.view.bounds;
			//frame.origin.y = frame.size.height - 50;
			//self.mpc.view.frame = frame;
			//self.mpc.view.backgroundColor = [UIColor clearColor];
			//self.mpc.backgroundView.backgroundColor = 
				//[UIColor clearColor];
			//for(UIView* subV in self.mpc.view.subviews) {
				//subV.backgroundColor = [UIColor clearColor];
			//}
			//for(UIView* subV in self.mpc.backgroundView.subviews) {
				//subV.backgroundColor = [UIColor clearColor];
			//}
			//[bubbleData.view addSubview:self.mpc.view];
			//self.mpc.contentURL = url;
			//[self.mpc prepareToPlay];
			//[self.mpc play];

			//[item initWithView:item.mpc.view 
						//date:item.message.date 
						//type:type 
						//insets:item.message.mine?Mine:Someone];
				

			
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
		if (!self.appDelegate.isOnLineAndAuthorized){
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.appDelegate showMessage:@"no network"];
			});
		}

		// download file
		[self.inputToolbar setToolbarWithProgress];
		[self.inputToolbar.progressView setProgress:0.0];
		[self.inputToolbar.progressLabel 
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
			self.stopTransfer = NO;
			int err = tg_get_document(
					self.appDelegate.tg, 
					m.docId,
					m.docSize, 
					m.docAccessHash, 
					[m.docFileReference UTF8String], 
					(__bridge void *)dict, 
					get_document_cb,
					(__bridge void *)self,
					download_progress);

			if (err){
				NSLog(@"document download error");
			} else {
				[d writeToFile:filepath atomically:YES];
			}
			
			dispatch_sync(dispatch_get_main_queue(), ^{
				if (self.dialog.broadcast)
					[self.inputToolbar setToolbarEmpty];
				else
					[self.inputToolbar setToolbarDefault];

				if (!err)
					[self openUrl:url data:data];
			});
		}];
	}
	[data.spinner stopAnimating];
}

-(void)getContact:(NSBubbleData *)data{
	TGMessage *m = data.message;
	
	NSString *tmpFile = [NSTemporaryDirectory() 
		stringByAppendingPathComponent:@"tmp.vcard"];
	[NSFileManager.defaultManager removeItemAtPath:tmpFile error:nil];
	[m.contactVcard writeToFile:tmpFile atomically:YES];
	NSURL *url = [NSURL fileURLWithPath: tmpFile];
	QuickLookController *qlc = [[QuickLookController alloc]
		initQLPreviewControllerWithData:@[url]];	
	[self presentViewController:qlc animated:TRUE completion:nil];
}

-(void)getPhoto:(NSBubbleData *)data{
	TGMessage *m = data.message;
	//NSString *filepath = [self.appDelegate.imagesCache 
				//stringByAppendingPathComponent:
					//[NSString stringWithFormat:@"%lld.png", m.photoId]];
		//NSURL *url = [NSURL fileURLWithPath:filepath]; 
		//if ([NSFileManager.defaultManager fileExistsAtPath:filepath]){
				//QuickLookController *qlc = [[QuickLookController alloc]
					//initQLPreviewControllerWithData:@[url]];	
				//[self presentViewController:qlc animated:TRUE completion:nil];
		//} else {
			//if (!self.appDelegate.tg ||
					//!self.appDelegate.authorizedUser ||
					//!self.appDelegate.reach.isReachable)
				//return;

			//// download photo
			//if (data.spinner)
				//[data.spinner startAnimating]; 

			//[self.syncData addOperationWithBlock:^{
				//char *photo = tg_get_photo_file(
						//self.appDelegate.tg, 
						//m.photoId, 
						//m.photoAccessHash, 
						//[m.photoFileReference UTF8String], 
						//"x"); 

				//// on done
				//if (data.spinner){
					//dispatch_sync(dispatch_get_main_queue(), ^{
						//[data.spinner stopAnimating]; 
					//});
				//}
				//if (photo){
					//NSData *data = [NSData dataFromBase64String:
						//[NSString stringWithUTF8String:photo]];
					//if (data){
						//[data writeToFile:filepath atomically:YES];
						//dispatch_sync(dispatch_get_main_queue(), ^{
							NSURL *url = [NSURL fileURLWithPath:m.photoPath]; 
							QuickLookController *qlc = [[QuickLookController alloc]
								initQLPreviewControllerWithData:@[url]];	
							[self presentViewController:qlc 
																 animated:TRUE completion:nil];
						//});
					//}
					//free(photo);

				//} else { // no photo
					//dispatch_sync(dispatch_get_main_queue(), ^{
						//[self.appDelegate 
							//showMessage:@"can't download full-sized photo"];
					//});
				//}
			//}];
		//}
}


-(void)getGeo:(NSBubbleData *)data{
	TGMessage *m = data.message;
	NSLog(@"LOCATION: %lf:%lf", m.geoLat, m.geoLong);
	
	//Create an MKMapItem to pass to the Maps app
		CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(
				m.geoLat, m.geoLong);
		MKPlacemark *placemark = 
			[[MKPlacemark alloc] initWithCoordinate:coordinate
																						addressDictionary:nil];
		MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
		[mapItem setName:@"Geopoint"];
		// Pass the map item to the Maps app
		[mapItem openInMapsWithLaunchOptions:nil];
}

#pragma mark <UIBubbleTableView Delegate>
-(void)bubbleDataDidTapText:(id)bubbleData{
	NSBubbleData *data = bubbleData;
	TGMessage *m = data.message;
	TextEditViewController *vc = [[TextEditViewController alloc]init];
	vc.text = m.message; 
	vc.title = @"Message";
	[self.navigationController pushViewController:vc animated:YES];
	vc.textView.dataDetectorTypes = UIDataDetectorTypeAll;
	
	// remove save button
	if (!m.mine){
		vc.navigationItem.rightBarButtonItems = nil;
		vc.textView.editable = NO;
	} else {
		vc.delegate = self;
	}
}

-(void)bubbleDataDidTapImage:(id)bubbleData{
	NSBubbleData *data = bubbleData;
	TGMessage *m = data.message;
	if (m){
		if (m.mediaType == id_messageMediaGeo){
			[self getGeo:data];
		} else if (m.mediaType == id_messageMediaContact){
			[self getContact:data];
		} else if (m.photoId){
			[self getPhoto:data];
		}	else if (m.docId){
			[self getDoc:data];
		}
	}
}
- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectData:(NSBubbleData *)data 
{
	//TGMessage *m = data.message;
	//if (m){
		//if (m.mediaType == id_messageMediaGeo){
			//[self getGeo:data];
		//} else if (m.mediaType == id_messageMediaContact){
			//[self getContact:data];
		//} else if (m.photoId){
			//[self getPhoto:data];
		//}	else if (m.docId){
			//[self getDoc:data];
		//}
	//}
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didScroll:(UIScrollView *)scrollView
{
	 if ((scrollView.contentOffset.y + scrollView.frame.size.height) >= scrollView.contentSize.height)
    {
      bubbleTableView.tableFooterView.hidden = NO;
			// call method to add data to tableView
    }
}

- (void)bubbleTableViewDidBeginDragging:(UIBubbleTableView *)bubbleTableView 
{
	//[self.inputToolbar.textView.internalTextView resignFirstResponder];
	//[self.inputToolbar resignFirstResponder];
	//[self becomeFirstResponder];
}

- (void)bubbleTableViewOnTap:(UIBubbleTableView *)bubbleTableView
{
	[self.inputToolbar.textView resignFirstResponder];
	//[self.inputToolbar.textView.internalTextView resignFirstResponder];
	[self.inputToolbar.textView clearText];
	//self.inputToolbar.textView.internalTextView.text = @"";
	[self becomeFirstResponder];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToBottom:(Boolean)bottom
{
	[self.syncData addOperationWithBlock:^{
		[self appendDataFrom:0 date:[NSDate date] 
					scrollToBottom:NO];
	}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
				didEndDecelerationgToTop:(Boolean)top
{
	// get top data
	//NSBubbleData *data = nil;
	//NSArray *section = [self.bubbleTableView.bubbleSection 
		//objectAtIndex:0];
	//if (section){
		//data = [section objectAtIndex:1];
	//}
	//NSInteger count = self.bubbleDataArray.count;
	//// load more messages
	//[self.syncData addOperationWithBlock:^{
		//[self appendMessagesFrom:count date:[NSDate date] scrollToBottom:NO];
		//[self.bubbleTableView reloadData];
		//NSInteger delta = self.bubbleDataArray.count - count;
		//// now scroll delta messages from top
			//int i = 0;
			//NSInteger section = 0;
			//for (NSArray *s in self.bubbleTableView.bubbleSection)
			//{
				//NSInteger row = 0;
				//for (NSBubbleData *d in s){
					//i++;
					//if (i == delta){
						//NSIndexPath *indexPath = 
							//[NSIndexPath indexPathForRow:row inSection:section]; 
						//dispatch_sync(dispatch_get_main_queue(), ^{
							//[self.bubbleTableView scrollToRowAtIndexPath:indexPath
								//atScrollPosition:UITableViewScrollPositionTop 
								//animated:NO];
						//});

						//break;;
					//}
					
					//row++;
				//}

				//section++;
			//}
	//}];
}

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView 
	accessoryButtonTappedForData:(NSBubbleData *)data 
{
	// create actionSheet
	//self.actionSheetType = ActionSheetMessage;
	//UIActionSheet *as = [[UIActionSheet alloc]
		//initWithTitle:@"" 
		//delegate:self 
		//cancelButtonTitle:@"cancel" 
		//destructiveButtonTitle:nil 
		//otherButtonTitles:
			//@"reply",
		//nil];
	//[as showFromToolbar:self.navigationController.toolbar];
}

- (void)performSwipeToLeftAction:(NSBubbleData *)data {
	NSString *title = @"";
	TGMessage *m = data.message;
	if (m.message.length > 0){
		if (m.message.length > 10)
			title = [m.message substringToIndex:10];
		else
			title = m.message;
	}
	else if (m.mediaType == id_messageMediaContact)
		title = @"*contact*";
	else if (m.mediaType == id_messageMediaGeo)
		title = @"*geopoint*";
	else if (m.mediaType == id_messageMediaPhoto)
		title = @"*photo*";
	else if (m.mediaType == id_messageMediaDocument){
		if (m.docFileName.length > 1)
			title = m.docFileName;
		else if (m.isVideo)
			title = @"*video*";
		else if (m.isVoice)
			title = @"*voice message*";
		else
			title = @"*document*";
	}

	self.actionSheetType = ActionSheetMessage;
	UIActionSheet *as = [[UIActionSheet alloc]
		initWithTitle:title 
		delegate:self 
		cancelButtonTitle:@"cancel" 
		destructiveButtonTitle:@"remove" 
		otherButtonTitles:
			@"reply", @"cyte",
		nil];
	[as showFromToolbar:self.navigationController.toolbar];
}

- (void)performSwipeToRightAction:(NSBubbleData *)data{

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
//#pragma mark <UITextView Delegate>
//-(void)textViewDidBeginEditing:(UITextView *)textView {
	//int numLines = 
		//textView.contentSize.height / textView.font.lineHeight;
	//[self textViewSetHeight:textView numLines:numLines];
	
	//[self toolbarAsEntryTyping];
	//if (self.appDelegate.isOnLineAndAuthorized)
	//{
		//[self.syncData addOperationWithBlock:^{
			//tg_peer_t peer = {
						//self.dialog.peerType, 
						//self.dialog.peerId, 
						//self.dialog.accessHash
			//};
			//tg_messages_set_typing(
					//self.appDelegate.tg, 
					//peer, 
					//true);
		//}];
	//}

//}

//-(void)textViewDidEndEditing:(UITextView *)textView {
	//[self toolbarAsEntry];
	//if (self.appDelegate.tg &&
			//self.appDelegate.authorizedUser && 
			//self.appDelegate.reach.isReachable)
	//{
		//[self.syncData addOperationWithBlock:^{
			//tg_peer_t peer = {
						//self.dialog.peerType, 
						//self.dialog.peerId, 
						//self.dialog.accessHash
			//};
			//tg_messages_set_typing(
					//self.appDelegate.tg, 
					//peer, 
					//false);
		//}];
	//}
//}

//-(void)textViewSetHeight:(UITextView *)textView numLines:(int)numLines{
	//CGRect frame = self.navigationController.toolbar.frame;
	//if (numLines < 8){
		////CGFloat height = textView.contentSize.height;
		//frame.origin.y -= (numLines - self.numLines)*textView.font.lineHeight; 
		//frame.size.height += (numLines - self.numLines)*textView.font.lineHeight; 
		//self.navigationController.toolbar.frame = frame;
		//self.numLines = numLines;
		//textView.showsVerticalScrollIndicator = NO;
	//} else
		//textView.showsVerticalScrollIndicator = YES;
//}

//- (void)textViewDidChange:(UITextView *)textView {
	//// resize text view
	//int numLines = 
		//textView.contentSize.height / textView.font.lineHeight;
	//[self textViewSetHeight:textView numLines:numLines];
//}

//#pragma mark <UITextField Delegate>
//- (void)textFieldDidBeginEditing:(UITextField *)textField {
	//[self toolbarAsEntryTyping];
	//if (self.appDelegate.isOnLineAndAuthorized)
	//{
		//[self.syncData addOperationWithBlock:^{
			//tg_peer_t peer = {
						//self.dialog.peerType, 
						//self.dialog.peerId, 
						//self.dialog.accessHash
			//};
			//tg_messages_set_typing(
					//self.appDelegate.tg, 
					//peer, 
					//true);
		//}];
	//}

	////self.bubbleTableView.typingBubble = NSBubbleTypingTypeMe;
	////[self.bubbleTableView reloadData];
	////[self.bubbleTableView scrollToBottomWithAnimation:YES];
//}

//- (void)textFieldDidEndEditing:(UITextField *)textField {
	//[self toolbarAsEntry];
	//if (self.appDelegate.tg &&
			//self.appDelegate.authorizedUser && 
			//self.appDelegate.reach.isReachable)
	//{
		//[self.syncData addOperationWithBlock:^{
			//tg_peer_t peer = {
						//self.dialog.peerType, 
						//self.dialog.peerId, 
						//self.dialog.accessHash
			//};
			//tg_messages_set_typing(
					//self.appDelegate.tg, 
					//peer, 
					//false);
		//}];
	//}

	////self.bubbleTableView.typingBubble = NSBubbleTypingTypeNobody;
	////[self.bubbleTableView reloadData];
//}

//- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
	//return self.textFieldIsEditable;
//}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	// get selected item
	if (self.actionSheetType == ActionSheetProgress)
	{
		switch (buttonIndex){
			case 0:
				{
					[self cancelTransfer:YES];
				}
				break;
			case 1:
				{
					[self cancelTransfer:NO];
				}
				break;
			

			default:
				break;
		}
	}
	else if (self.actionSheetType == ActionSheetAttach)
	{
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

			case 3:
				{
					ABPeoplePickerNavigationController *picker =
						[[ABPeoplePickerNavigationController alloc] init];
					picker.peoplePickerDelegate = self;
					[self presentViewController:picker 
														 animated:TRUE completion:nil];
				}
				break;
			
			case 4:
				{
					[self askSendGeopoint];
				}
				break;

			default:
				break;
		}
	}
}	

#pragma mark <UIImagePickerController Delegate>
- (void)imagePickerController:(UIImagePickerController *)picker 
				didFinishPickingMediaWithInfo:(NSDictionary *)info 
{
	
 [self dismissViewControllerAnimated:YES completion:nil];
	 
 // UIImagePickerControllerMediaType
 if([info[UIImagePickerControllerMediaType] 
		 isEqualToString:(__bridge NSString *)(kUTTypeImage)])
 {
	//image
	UIImage *image = 
		[info objectForKey:UIImagePickerControllerOriginalImage];
	
	//NSLog(@"UIMAGE: %@", image);

	// send image
	if (image){
		// save image in album
		if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
			UIImageWriteToSavedPhotosAlbum(
					image, self, 
					@selector(image:didFinishSavingWithError:contextInfo:), 
					(__bridge void *)image);
		else
			[self sendPhoto:image];
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

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error 
 contextInfo:(void *)contextInfo
{
	if (error){
		[self.appDelegate showMessage:error.localizedDescription];
		return;
	}
	[self sendPhoto:image];
} 


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
		return YES;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{	
		//CGRect screenFrame = [[UIScreen mainScreen] applicationFrame];
		CGRect frame = self.view.bounds;
		CGRect r = self.inputToolbar.frame;
	if (UIInterfaceOrientationIsPortrait(toInterfaceOrientation))
		{
				r.origin.y = frame.size.height - self.inputToolbar.frame.size.height - kStatusBarHeight;
				if (keyboardIsVisible) {
						r.origin.y -= kKeyboardHeightPortrait;
				}
				[self.inputToolbar.textView setMaximumNumberOfLines:13]; 
	}
	else
		{
				r.origin.y = frame.size.width - self.inputToolbar.frame.size.height - kStatusBarHeight;
				if (keyboardIsVisible) {
						r.origin.y -= kKeyboardHeightLandscape;
				}
				[self.inputToolbar.textView setMaximumNumberOfLines:7];
				[self.inputToolbar.textView sizeToFit];
		}
		self.inputToolbar.frame = r;
}

#pragma mark <Keyboard Functions>
- (void)keyboardWillShow:(NSNotification *)notification {
		CGSize keyboardSize = [[[notification userInfo] 
			objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

		UIInterfaceOrientation interfaceOrientation = UIApplication.sharedApplication.statusBarOrientation;

		float newVerticalPosition;
		if (UIInterfaceOrientationIsPortrait(interfaceOrientation))
			newVerticalPosition = -keyboardSize.height + kDefaultToolbarHeight;
		else 
			newVerticalPosition = -keyboardSize.width + kDefaultToolbarHeight;

		[self moveFrameToVerticalPosition:newVerticalPosition forDuration:0.3f];
    keyboardIsVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification {
		[self moveFrameToVerticalPosition:0.0f forDuration:0.3f];
    keyboardIsVisible = NO;
}

- (void)moveFrameToVerticalPosition:(float)position forDuration:(float)duration {
		CGRect frame = self.bubbleTableView.frame;
		//CGRect toolbarFrame = self.navigationController.toolbar.frame;
		//CGRect toolbarFrame = self.inputToolbar.frame;
		frame.origin.y = position;
		//if (position){
			//self.toolbarOrigY = toolbarFrame.origin.y;
			//toolbarFrame.origin.y += position;
		//} else {
			//toolbarFrame.origin.y = 
				//self.view.bounds.size.height - kDefaultToolbarHeight;
			
			////newVerticalPosition = -keyboardSize.height;
			
			//UIInterfaceOrientation interfaceOrientation = 
				//UIApplication.sharedApplication.statusBarOrientation;

			//if (UIInterfaceOrientationIsPortrait(interfaceOrientation)){
				//toolbarFrame.origin.y = 
					//self.appDelegate.window.bounds.size.height -
					////self.navigationController.toolbar.bounds.size.height;
					//self.inputToolbar.bounds.size.height;
			//} else {
				//toolbarFrame.origin.y = 
					//self.appDelegate.window.bounds.size.width -
					////self.navigationController.toolbar.bounds.size.height;
					//self.inputToolbar.bounds.size.height;
			//} 
		//}

		[UIView animateWithDuration:duration animations:^{
				self.bubbleTableView.frame = frame;
				//self.navigationController.toolbar.frame = toolbarFrame;
				//self.inputToolbar.frame = toolbarFrame;
		}];
}

//- (void)keyboardWillShow:(NSNotification *)notification 
//{
    //[> Move the toolbar to above the keyboard <]
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration:0.3];
	//CGRect frame = self.inputToolbar.frame;
    //if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        //frame.origin.y = self.view.frame.size.height - frame.size.height - kKeyboardHeightPortrait;
    //}
    //else {
        //frame.origin.y = self.view.frame.size.width - frame.size.height - kKeyboardHeightLandscape - kStatusBarHeight - 40;
    //}
	//self.inputToolbar.frame = frame;
	//[UIView commitAnimations];
    //keyboardIsVisible = YES;
//}

//- (void)keyboardWillHide:(NSNotification *)notification 
//{
    //[> Move the toolbar back to bottom of the screen <]
	//[UIView beginAnimations:nil context:NULL];
	//[UIView setAnimationDuration:0.3];
	//CGRect frame = self.inputToolbar.frame;
    //if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        //frame.origin.y = self.view.frame.size.height - frame.size.height;
    //}
    //else {
        //frame.origin.y = self.view.frame.size.width - frame.size.height;
    //}
	//self.inputToolbar.frame = frame;
	//[UIView commitAnimations];
    //keyboardIsVisible = NO;
//}

#pragma mark <Audio Recording>
//-(void)startRecording:(id)sender{
-(void)recordButtonStart {
	// Init audio with record capability
	AVAudioSession *audioSession = [AVAudioSession sharedInstance];
	[audioSession setCategory:AVAudioSessionCategoryRecord error:nil];

	UINavigationBar *bar = [self.navigationController navigationBar];
	self.defaultBarColor = bar.tintColor;
	bar.tintColor = [UIColor redColor];

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
		//[self startRecording:nil];
	}
	else {
		record.style = UIBarButtonItemStyleBordered;
		//[self stopRecording:nil];
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
	[self.download addOperationWithBlock:^{
		if (!self.appDelegate.isOnLineAndAuthorized)
		{
			dispatch_sync(dispatch_get_main_queue(), ^{
				[self.appDelegate showMessage:@"no network"];
			});
			return;
		}

		dispatch_sync(dispatch_get_main_queue(), ^{
			[self.inputToolbar setToolbarWithProgress];
			[self.inputToolbar.progressView setProgress:0.0];
			[self.inputToolbar.progressLabel setText:@"0 /\n0"];
		});

		self.progressTotal = 0;
		self.progressCurrent = 0;
		self.stopTransfer = NO;
		
		// send
		
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
				(__bridge void *)self,
				upload_progress);
		
		free(document);
		
		//if (err){
			//dispatch_sync(dispatch_get_main_queue(), ^{
				//if (self.dialog.broadcast)
					//[self toolbarForChannel];
				//else
					//[self toolbarAsEntry];
				
				//[self.appDelegate showMessage:@"error to send"];
			//});
			//return;
		//}
		
		// on done
		dispatch_sync(dispatch_get_main_queue(), ^{
			if (self.dialog.broadcast)
				[self.inputToolbar setToolbarEmpty];
			else
				[self.inputToolbar setToolbarDefault];
		});
		[self appendDataFrom:0 date:[NSDate date] 
					scrollToBottom:YES];
	}];
}

//-(void)stopRecording:(id)sender{
-(void)recordButtonStop {
	//[self.appDelegate showMessage:@"STOP"];
	NSLog(@"stopRecording");
	[self.audioRecorder stop];
	NSLog(@"stopped");


	UINavigationBar *bar = [self.navigationController navigationBar];
	bar.tintColor = self.defaultBarColor;
	
	[self.appDelegate askYesNo:@"Send voice message?" 
		onYes:^{
			[self sendVoiceMessage];
		}];
}

#pragma mark <AppActivity Delegate>
-(void)willResignActive {
	[self cancelAll];
  //[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark <Authorization Delegate>
-(void)tgLibLoaded{
}
-(void)authorizedAs:(tl_user_t *)user{
	[self appendDataFrom:0 date:[NSDate date] 
				scrollToBottom:YES];
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
	NSString *firstName = (__bridge NSString *)ABRecordCopyValue(
			person, kABPersonFirstNameProperty);
	
	NSString *lastName = (__bridge NSString *)ABRecordCopyValue(
			person, kABPersonLastNameProperty);

	ABMultiValueRef phonesProperty =
		ABRecordCopyValue(person, kABPersonPhoneProperty);
	NSArray *phones = (__bridge NSArray *)
		ABMultiValueCopyArrayOfAllValues(phonesProperty);
	NSString *phone = phones[0];

	// vcard
	ABRecordRef people[1];
	people[0] = person;
	CFArrayRef peopleArray = CFArrayCreate(NULL, (void *)people, 1, &kCFTypeArrayCallBacks);
	NSData *vCardData =
		CFBridgingRelease(ABPersonCreateVCardRepresentationWithPeople(peopleArray));
	NSString *vCard = [[NSString alloc] 
		initWithData:vCardData encoding:NSUTF8StringEncoding];

	NSString *msg = [NSString stringWithFormat:
		@"send contact: %@ %@ %@?", 
		firstName?firstName:@"", 
			lastName?lastName:@"", 
						phone?phone:@""];
	
	[self.appDelegate askYesNo:msg onYes:^{
		if (!self.appDelegate.isOnLineAndAuthorized){
			[self.appDelegate showMessage:@"no network"];
			return;
		}
		[self.download addOperationWithBlock:^{

			tg_peer_t peer = {
				self.dialog.peerType, 
				self.dialog.peerId, 
				self.dialog.accessHash
			};	

			tg_contact_send(
					self.appDelegate.tg, 
					&peer, 
					phone?phone.UTF8String:"", 
	        firstName?firstName.UTF8String:"", 
		      lastName?lastName.UTF8String:"", 
					vCard.UTF8String, 
					NULL);
			
			[self appendDataFrom:0 date:[NSDate date] 
						scrollToBottom:YES];
		}];
		[peoplePicker dismissViewControllerAnimated:true completion:nil];
	}];

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

#pragma mark <MapView Functions>
-(void)askSendGeopoint{
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"Send geopoint" 
			message:@"\n\n\n\n\n\n" 
			delegate:self 
			cancelButtonTitle:@"Cancel" 
			otherButtonTitles:@"Send", nil];

	[alert setAlertViewStyle:UIAlertViewStyleDefault]; 
	[alert show];
	
	MKMapView *mv = [[MKMapView alloc]init]; 
	mv.frame = CGRectMake(
			10, 40, 264, 140);

	[alert addSubview:mv];
	self.mapView = mv;
	self.locationManager.delegate = self;
	[self.locationManager startUpdatingLocation];
	mv.showsUserLocation = YES;
}

-(void)alertView:(UIAlertView *)alertView 
	clickedButtonAtIndex:(NSInteger)buttonIndex
{	
	if (buttonIndex == 1){
		// send location
		NSLog(@"SEND LOCATION: %lf: %lf",
						self.locationManager.location.coordinate.latitude, 
						self.locationManager.location.coordinate.longitude);
		
		uint64_t lat = self.locationManager.location.coordinate.latitude;
		uint64_t lon = self.locationManager.location.coordinate.longitude;
		
		NSLog(@"SEND LOCATION IN 64: %lld: %llld", lat, lon);
		
		if (self.appDelegate.isOnLineAndAuthorized){
			[self.syncData addOperationWithBlock:^{
				tg_peer_t peer = {
						self.dialog.peerType, 
						self.dialog.peerId, 
						self.dialog.accessHash
				};
				tg_send_geopoint(
						self.appDelegate.tg, 
						&peer, 
						lat, 
						lon, 
						NULL);

				[self appendDataFrom:0 date:[NSDate date] 
							scrollToBottom:YES];
			}];
		} else {
			[self.appDelegate showMessage:@"no network!"];
		}
	}

	[self.locationManager stopUpdatingLocation];
	self.locationManager.delegate = nil;
	self.mapView = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation 
{
	if (self.mapView){
		[self.mapView setCenterCoordinate:newLocation.coordinate 
														 animated:YES];
	}
}
#pragma mark <TextEditViewController DELEGATE FUNCTIONS>
-(void)textEditViewControllerSaveText:(NSString *)text{
}

#pragma mark - UIInputToolbar

-(void)inputButtonPressed:(NSString *)inputText
{
    /* Called when toolbar button is pressed */
    //NSLog(@"Pressed button with text: '%@'", inputText);
	
	NSString *text = inputText;
	if (self.appDelegate.isOnLineAndAuthorized)
	{
		[self.syncData addOperationWithBlock:^{
			tg_peer_t peer = {
					self.dialog.peerType, 
					self.dialog.peerId, 
					self.dialog.accessHash
			};
			//if (
					tg_message_send(
					self.appDelegate.tg, 
					peer, text.UTF8String);
				//)
			//{
				//dispatch_sync(dispatch_get_main_queue(), ^{
					//[self.appDelegate showMessage:@"can't send message"];
				//});
			//} else {
				[self appendDataFrom:0 date:[NSDate date] 
							scrollToBottom:YES];
			//}
		}];
	} else {
		[self.appDelegate showMessage:@"no network!"];
	}

	[self becomeFirstResponder];
}
- (BOOL)canBecomeFirstResponder{
    return YES;
}

- (UIView *)inputAccessoryView{
    return self.inputAccessoryToolbar;
}



@end
// vim:ft=objc
