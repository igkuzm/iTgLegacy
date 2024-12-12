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

//- (void)resisterNotifications {
	//// Request permission for push notifications
	//NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
	//[center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge)
												//completionHandler:^(BOOL granted, NSError * _Nullable error) {
			//if (granted) {
					//NSLog(@"Permission granted for push notifications");
			//} else {
					//NSLog(@"Permission denied for push notifications");
			//}
	//}];
//}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// logging
	NSString *log = [[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] 
			stringByAppendingPathComponent:@"iTgLegacy.log"];
	[[NSFileManager defaultManager] removeFileAtPath:log handler:nil];
	freopen([log UTF8String], "a+", stderr);

	NSLog(@"start...");
	
	self.syncDialogs = [[NSOperationQueue alloc]init];

  //[[NSNotificationCenter defaultCenter] addObserver:@"" selector:@selector(callMyWebService) name:nil object:nil];

	// Override point for customization after application launch.
	[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:
		(UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeSound|UIRemoteNotificationTypeAlert)];
	//self.player = [[PlayerController alloc]init];
	
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

	// load tglib
	[self loadTgLib];

	// start window
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	RootViewController *vc = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:vc];
	[self.window makeKeyAndVisible];	

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

-(void)playButtonPushed:(id)sender{
	//PlayerViewController *vc = [[PlayerViewController alloc]init];
	//UINavigationController *nc = [[UINavigationController alloc]initWithRootViewController:vc];
	//[self.window.rootViewController presentViewController:nc animated:TRUE completion:nil];
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
	UIAlertView *alert = 
			[[UIAlertView alloc]initWithTitle:@"" 
			message:msg 
			delegate:self 
			cancelButtonTitle:@"OK" 
			otherButtonTitles:nil];

	[alert setAlertViewStyle:UIAlertViewStylePlainTextInput]; 
	[alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{	
	UITextField *textField = [alertView textFieldAtIndex:0];
	//if (buttonIndex == 1){
	//}
	if (self.askInput_onDone)
		self.askInput_onDone(textField.text);
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
		}
		tg_set_on_error(self.tg, self, on_err);
		//tg_set_on_log(self.tg, self, on_log);
	}
}

static void on_err(void *d, tl_t *tl, const char *err)
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

static void on_dialogs_sync_done(void *d)
{
	AppDelegate *self = d;
	if (self.dialogsSyncDelegate)
		[self.dialogsSyncDelegate onSyncDone];
}

-(void)afteLoginUser:(tl_user_t *)user {
	self.authorizedUser = user;
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

	dispatch_queue_t backgroundQueue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	// do in background
	dispatch_async(backgroundQueue, ^{
		// check authorized 
		tl_user_t *user = 
			tg_is_authorized(self.tg);

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
	});
}
@end

// vim:ft=objc
