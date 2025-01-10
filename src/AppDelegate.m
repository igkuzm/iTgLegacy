/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#include "TGDialog.h"
#include "DialogsViewController.h"
#include "ChatViewController.h"
#include "AudioToolbox/AudioToolbox.h"
#include <string.h>
#include <stdio.h>
#import <UIKit/UIResponder.h>
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"
#include "../libtg/libtg.h"
#include "../libtg/tg/dialogs.h"
#include "../libtg/api_id.h"
#include "../libtg/tg/user.h"
#include "../libtg/tg/peer.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// lock crush
	UIApplication.sharedApplication.idleTimerDisabled = YES;

	// logging
	NSString *log = 
		[NSTemporaryDirectory() stringByAppendingPathComponent:@"iTgLegacy.txt"];
	[[NSFileManager defaultManager] removeFileAtPath:log handler:nil];
	self.log = freopen([log UTF8String], "a+", stderr);

	NSLog(@"start...");

	self.syncData = [[NSOperationQueue alloc]init];
	self.syncData.maxConcurrentOperationCount = 1;
	
	// set badge number
	application.applicationIconBadgeNumber = 0;

	// create cache
	NSString *cache = [NSSearchPathForDirectoriesInDomains(
			NSCachesDirectory, 
			NSUserDomainMask,
		 	YES) objectAtIndex:0]; 
	
	self.smallPhotoCache = [cache 
			stringByAppendingPathComponent:@"s"];
	[NSFileManager.defaultManager 
		createDirectoryAtPath:self.smallPhotoCache attributes:nil];
		
	self.peerPhotoCache = [cache 
			stringByAppendingPathComponent:@"peer"];
	[NSFileManager.defaultManager 
		createDirectoryAtPath:self.peerPhotoCache attributes:nil];
	
	self.imagesCache = [cache 
			stringByAppendingPathComponent:@"images"];
	[NSFileManager.defaultManager 
		createDirectoryAtPath:self.imagesCache attributes:nil];
	
	self.filesCache = [cache 
			stringByAppendingPathComponent:@"files"];
	[NSFileManager.defaultManager 
		createDirectoryAtPath:self.filesCache attributes:nil];
	
	self.thumbDocCache = [cache 
			stringByAppendingPathComponent:@"docThumbs"];
	[NSFileManager.defaultManager 
		createDirectoryAtPath:self.thumbDocCache attributes:nil];
	
  //[[NSNotificationCenter defaultCenter] addObserver:@"" selector:@selector(callMyWebService) name:nil object:nil];

	// Override point for customization after application launch.
	[application beginReceivingRemoteControlEvents];
	[application registerForRemoteNotificationTypes:
		(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
	
	// start reachability
	self.reach = [Reachability reachabilityWithHostname:@"www.google.ru"];
	// Set the blocks
	self.reach.reachableBlock = ^(Reachability*reach)
	{
			// keep in mind this is called on a background thread
			// and if you are updating the UI it needs to happen
			// on the main thread, like this:

			dispatch_async(dispatch_get_main_queue(), ^{
					if (self.reachabilityDelegate)
						[self.reachabilityDelegate isOnLine];
					NSLog(@"REACHABLE!");
			});
	};

	self.reach.unreachableBlock = ^(Reachability*reach)
	{
			dispatch_async(dispatch_get_main_queue(), ^{
					if (self.reachabilityDelegate)
						[self.reachabilityDelegate isOffLine];
			});

			NSLog(@"UNREACHABLE!");
	};

	// Start the notifier, which will cause the reachability object to retain itself!
	[self.reach startNotifier];

	// change current directory path to bundle
	[[NSFileManager defaultManager]changeCurrentDirectoryPath:
		[[NSBundle mainBundle] bundlePath]];

	// start window
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	self.rootViewController = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:self.rootViewController];
	[self.window makeKeyAndVisible];	

	[self loadTgLib];
	[self authorize];
	
	return true;
}

- (void)showAlarm:(NSString *)text {
  UIAlertView *alertView = [[UIAlertView alloc] 
		initWithTitle:@"Alarm"
		message:text 
		delegate:nil
		cancelButtonTitle:@"OK"
		otherButtonTitles:nil];
	[alertView show];
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
	//if (event.type == UIEventTypeRemoteControl) {
		//switch (event.subtype) {
			//case UIEventSubtypeRemoteControlTogglePlayPause:
					//// Pause or play action
					//if (self.player.currentPlaybackRate != 0)
						//[self.player pause];
					//else
						//[self.player play];
					//break;
			//case UIEventSubtypeRemoteControlNextTrack:
					//// Next track action
					//[self.player next];
					//break;
			//case UIEventSubtypeRemoteControlPreviousTrack:
					//// Previous track action
					//[self.player prev];
					//break;
			//case UIEventSubtypeRemoteControlStop:
					//// Stop action
					//[self.player stop];
					//break;
			//case UIEventSubtypeRemoteControlPlay:
					//// Stop action
					//[self.player play];
					//break;
			//case UIEventSubtypeRemoteControlPause:
					//// Stop action
					//[self.player pause];
					//break;

			//default:
					//// catch all action
					//break;
		//}
	//}
}

-(void)showMessage:(NSString *)msg {
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"" 
			message:msg 
			delegate:nil 
			cancelButtonTitle:@"Закрыть" 
			otherButtonTitles:nil];

		[alert show];
}

-(void)askInput:(NSString *)msg onDone:(void (^)(NSString *text))onDone{
	self.askInput_onDone = onDone;
	self.allertType = ALLERT_TYPE_ASK_INPUT;
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"" 
			message:msg 
			delegate:self 
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];

	[alert setAlertViewStyle:UIAlertViewStylePlainTextInput]; 
	[alert show];
}

-(void)askYesNo:(NSString *)msg onYes:(void (^)())onYes{
	self.allertType = ALLERT_TYPE_YES_NO;
	self.askYesNo_onYes = onYes;
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"" 
			message:msg 
			delegate:self 
			cancelButtonTitle:@"cancel" 
			otherButtonTitles:@"OK", nil];

	[alert show];
}

-(void)alertView:(UIAlertView *)alertView 
	clickedButtonAtIndex:(NSInteger)buttonIndex
{	
	switch (self.allertType) {
		case ALLERT_TYPE_ASK_INPUT:
			{
				UITextField *textField = [alertView textFieldAtIndex:0];
				if (self.askInput_onDone)
					self.askInput_onDone(textField.text);
			}
			break;
		case ALLERT_TYPE_YES_NO:
			{
				if (buttonIndex == 1){
					if (self.askYesNo_onYes)
						self.askYesNo_onYes();
				}
			}
			break;
	
		default:
			break;
	}
	
}

#pragma mark <NOTIFICATIONS FUNCTIONS>
-(void)openDislogForNotification:(NSDictionary *)userInfo{
	if ([userInfo valueForKey:@"from_id"]){
		NSNumber *n = [userInfo valueForKey:@"from_id"];
		uint64_t from_id = [n longLongValue]; 
		tg_user_t *user = tg_user_get(self.tg, from_id);
		if (user){
			UINavigationController *nc =
					[((RootViewController *)self.rootViewController).viewControllers objectAtIndex:1]; 
			if (nc){
				[((RootViewController *)self.rootViewController) setSelectedViewController:nc];
				[nc popToRootViewControllerAnimated:NO];

				TGDialog *dialog = [[TGDialog alloc] init];
				dialog.peerType = TG_PEER_TYPE_USER;
				dialog.peerId = from_id;
				dialog.accessHash = user->access_hash_;
				dialog.photoId = user->photo_id;
				if (user->first_name_)
					dialog.title = [NSString stringWithUTF8String:user->first_name_];

				DialogsViewController *dc = 
					(DialogsViewController *)[nc visibleViewController];
				
				ChatViewController *vc = [[ChatViewController alloc]init];
				vc.hidesBottomBarWhenPushed = YES;
				vc.dialog = dialog;
				vc.spinner = dc.spinner;
				[nc pushViewController:vc animated:TRUE];
			}
		}
	}
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
	//[self showMessage:[NSString stringWithFormat:@"%@", userInfo]];
	UIApplication.sharedApplication.applicationIconBadgeNumber++;

	if(application.applicationState == UIApplicationStateInactive) {

     NSLog(@"Inactive - the user has tapped in the notification when app was closed or in background");
     //do some tasks
    //[self manageRemoteNotification:userInfo];
     //completionHandler(UIBackgroundFetchResultNewData);
		 [self openDislogForNotification:userInfo];
 } else if (application.applicationState == UIApplicationStateBackground) {

     NSLog(@"application Background - notification has arrived when app was in background");
     NSString* contentAvailable = [NSString stringWithFormat:@"%@", [[userInfo valueForKey:@"aps"] valueForKey:@"content-available"]];

     if([contentAvailable isEqualToString:@"1"]) {
         // do tasks
         //[self manageRemoteNotification:userInfo];
         NSLog(@"content-available is equal to 1");
         //completionHandler(UIBackgroundFetchResultNewData);
     }
		 [self openDislogForNotification:userInfo];
 } else {
     NSLog(@"application Active - notication has arrived while app was opened");
      //play sound
			NSURL *url = [NSBundle.mainBundle.resourceURL URLByAppendingPathComponent:@"2.m4a"];
			SystemSoundID soundID;
			AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
			AudioServicesPlaySystemSound(soundID);
			// add bange to tabBarItem
			UINavigationController *nc =
				[((RootViewController *)self.rootViewController).viewControllers objectAtIndex:1]; 
			if (nc){
				int badge = nc.tabBarItem.badgeValue.intValue;
				badge++;
				nc.tabBarItem.badgeValue = 
					[NSString stringWithFormat:@"%d", badge];
			}

			// reload data
			if (self.dialogsViewController){
				[(DialogsViewController *)self.dialogsViewController getDialogsFrom:[NSDate date]];
			}
  }
}


-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	self.tokenAlreadyRequested = YES;
	NSLog(@"TOKEN: %@", deviceToken);
	NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
  NSLog(@"Device token: %@", token);
	self.token = token;
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"FAILD TO GET TOKEN: %@", error);
} 

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [self showAlarm:notification.alertBody];
    //application.applicationIconBadgeNumber = 0;
    NSLog(@"AppDelegate didReceiveLocalNotification %@", notification.userInfo);
}

#pragma <LibTg FUNCTIONS>

-(void)loadTgLib{
	if (self.tg)
		return;

	// connect to libtg
	NSString *databasePath = [[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] 
			stringByAppendingPathComponent:@"tgdata.db"];
	
	int SETUP_API_ID(apiId)
	char * SETUP_API_HASH(apiHash)
	
	self.tg = tg_new(
			[databasePath UTF8String],
			0,
			apiId, 
			apiHash,
			"pub.pkcs");
	if (!self.tg){
		[self showMessage:@"can't init LibTg"];
	} else {
			NSLog(@"LibTg inited");
			if (self.authorizationDelegate)
				[self.authorizationDelegate tgLibLoaded];
	}
	tg_set_on_error(self.tg, self, on_err);
	if ([NSUserDefaults.standardUserDefaults  boolForKey:@"debug"])
		tg_set_on_log(self.tg, self, on_log);
}

static void on_err(void *d, const char *err)
{
	AppDelegate *self = d;
	NSLog(@"%s", err);
	//dispatch_sync(dispatch_get_main_queue(), ^{
		//[self showMessage: 
				//[NSString stringWithFormat:@"%s", err]];	
	//});	
}

static void on_log(void *d, const char *msg)
{
	AppDelegate *self = d;
	NSLog(@"%s", msg);
}

-(void)afteLoginUser:(tl_user_t *)user {
	self.authorizedUser = user;
	NSLog(@"AUTHORIZED! as: %s", user->username_.data);
	NSNumber *userId = [NSNumber numberWithLongLong:user->id_];
	[NSUserDefaults.standardUserDefaults 
		setValue:userId forKey:@"userId"];
	//[NSUserDefaults.standardUserDefaults 
		//setValue:[NSString stringWithUTF8String:(char*)user->username_.data] 
			//forKey:@"userName"];
	if (self.authorizationDelegate)
		[self.authorizationDelegate authorizedAs:user];
	self.authorizationDelegate = nil;
	if (self.token){
		[self.syncData addOperationWithBlock:^{
			if (tg_account_register_ios(self.tg, self.token.UTF8String, true) == 0)	
				NSLog(@"Register device with token: %@", self.token);
			else
				NSLog(@"Can't register device with token: %@", self.token);
		}];
	}
	// get colors
	//[self getPeerColorset];
}

-(void)signIn:(NSString *)phone_number 
				 code:(NSString *)code 
		 sentCode:(tl_auth_sentCode_t *)sentCode
{
	tl_user_t *user = tg_auth_signIn(
			self.tg, 
			sentCode, 
			[phone_number UTF8String], 
			[code UTF8String]);

	if (user){
		[self afteLoginUser:user];
	}
}

-(void)sendCode:(NSString *)phone_number
{
	tl_auth_sentCode_t *sentCode =
		tg_auth_sendCode(
				self.tg,
			 	[phone_number UTF8String]);
	if (sentCode){
		[self askInput:@"enter phone_code" 
						onDone:^(NSString *text){
							[self signIn:phone_number 
											code:text sentCode:sentCode];
						}];
	}
}

-(void)authorize{
	if (!self.reach.isReachable){
		// no network
		[self showMessage:@"network is not reachable"];
		return;
	}

	if (!self.tg)
		[self loadTgLib];
	
	if (!self.tg)
		return;

	// do in background
	[self.syncData addOperationWithBlock:^{
		// check authorized 
		tl_user_t *user = tg_is_authorized(self.tg);
		
		if (self.tg->key.size > 0){
			while (!user){
				NSLog(@"try to get user authorize");
				sleep(1);	
				user = tg_is_authorized(self.tg);
			}
		}
		
		// authorize if needed
		dispatch_async(dispatch_get_main_queue(), ^{
			if (user){
				[self afteLoginUser:user];
			} else{
				[self askInput:@"enter phone number (+7XXXXXXXXXX)" 
								onDone:^(NSString *text){
									[self sendCode:text];
								}];
			}
		});
	}];
}

- (void)applicationWillResignActive:(UIApplication *)application {
	if (self.appActivityDelegate)
		[self.appActivityDelegate willResignActive];
	[self.syncData cancelAllOperations];
}

static int getPeerColorsetCb(void *d, uint32_t color_id, tg_colors_t *colors, tg_colors_t *dark_colors)
{
	AppDelegate *self = d;
	NSDictionary *c = @{
		@"color_id":[NSNumber numberWithInt:color_id],
		@"0":[NSNumber numberWithInt:colors->rgb0],
		@"1":[NSNumber numberWithInt:colors->rgb1],
		@"2":[NSNumber numberWithInt:colors->rgb2],
		@"3":[NSNumber numberWithInt:dark_colors->rgb0],
		@"4":[NSNumber numberWithInt:dark_colors->rgb1],
		@"5":[NSNumber numberWithInt:dark_colors->rgb2],
	};

	[self.colorset addObject:c];
}

- (void) getPeerColorset{
	self.colorset = [NSMutableArray array];
	[self.syncData addOperationWithBlock:^{
		tg_get_peer_profile_colors(
				self.tg, 
				0, 
				self, getPeerColorsetCb);
	}];
}

-(Boolean)isOnLineAndAuthorized{
	return
		self.tg && 
		self.authorizedUser != nil && 
		self.reach.isReachable;
}

-(void)setDebug:(Boolean)debug {
	if (!self.tg)
		return;
	NSLog(@"Set debugging %s", debug?"ON":"OFF");
	if (debug)
		tg_set_on_log(self.tg, self, on_log);
	else 
		tg_set_on_log(self.tg, NULL, NULL);

}

@end

// vim:ft=objc
