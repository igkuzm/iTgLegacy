/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#include <string.h>
#include <stdio.h>
#import <UIKit/UIResponder.h>
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"
#include "../libtg/libtg.h"
#include "../libtg/tg/dialogs.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// lock crush
	UIApplication.sharedApplication.idleTimerDisabled = YES;

	// logging
	NSString *log = [[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] 
			stringByAppendingPathComponent:@"iTgLegacy.log"];
	[[NSFileManager defaultManager] removeFileAtPath:log handler:nil];
	self.log = freopen([log UTF8String], "a+", stderr);

	NSLog(@"start...");

	self.syncData = [[NSOperationQueue alloc]init];

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
	RootViewController *vc = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:vc];
	[self.window makeKeyAndVisible];	

	[self loadTgLib];
	[self authorize];
	
	return true;
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
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo{
	[self showMessage:@"NOTIFICATION"];
			//NSString *aStrEventType = userInfo[@"eventType"];
			//if ([aStrEventType isEqualToString:@"callWebService"]) {
								//[[NSNotificationCenter defaultCenter] postNotificationName:@"callWebService" object:nil];
										
			//}else{
								//// Implement other notification here
								////     
			//}
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
		 NSLog(@"TOKEN: %@", deviceToken);
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"FAILD TO GET TOKEN: %@", error);
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
	
	if ([[NSUserDefaults standardUserDefaults] valueForKey:@"ApiId"] &&
			[[NSUserDefaults standardUserDefaults] valueForKey:@"ApiHash"])
	{
		self.tg = tg_new(
				[databasePath UTF8String],
				0,
				[[NSUserDefaults standardUserDefaults] integerForKey:@"ApiId"], 
				[[[NSUserDefaults standardUserDefaults] valueForKey:@"ApiHash"] UTF8String],
				"pub.pkcs");
		if (!self.tg){
			[self showMessage:@"can't init LibTg"];
		} else {
				NSLog(@"LibTg inited");
				if (self.authorizationDelegate)
					[self.authorizationDelegate tgLibLoaded];
		}
		tg_set_on_error(self.tg, self, on_err);
		//tg_set_on_log(self.tg, self, on_log);
	}
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
	NSNumber *userId = [NSNumber numberWithLongLong:user->id_];
	[NSUserDefaults.standardUserDefaults 
		setValue:userId forKey:@"userId"];
	//[NSUserDefaults.standardUserDefaults 
		//setValue:[NSString stringWithUTF8String:(char*)user->username_.data] 
			//forKey:@"userName"];
	//[self showMessage:@"authorized!"];
	if (self.authorizationDelegate)
		[self.authorizationDelegate authorizedAs:user];
	self.authorizationDelegate = nil;
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

	if (![[NSUserDefaults standardUserDefaults] valueForKey:@"ApiId"] ||
			![[NSUserDefaults standardUserDefaults] valueForKey:@"ApiHash"])
	{
		// no config
		[self showMessage:@"no ApiId or ApiHash"];
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
@end

// vim:ft=objc
