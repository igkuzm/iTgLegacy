/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#import <UIKit/UIResponder.h>
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"
#include "../libtg/libtg.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Override point for customization after application launch.
	//[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
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
	
	// start window
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	RootViewController *vc = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:vc];
	[self.window makeKeyAndVisible];	

	// change current directory path to bundle
	[[NSFileManager defaultManager]changeCurrentDirectoryPath:
		[[NSBundle mainBundle] bundlePath]];

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

#pragma <LibTg FUNCTIONS>
static void on_err(void *d, tl_t *tl, const char *err)
{
	AppDelegate *self = d;
	[self showMessage: 
			[NSString stringWithFormat:@"%s", err]];	
}

-(void)signIn:(NSString *)phone_number 
				 code:(NSString *)code 
		 sentCode:(tl_auth_sentCode_t *)sentCode
{
	tl_user_t *user = tg_auth_signIn(
			self.tg, 
			sentCode, 
			[phone_number UTF8String], 
			[code UTF8String], 
			self, on_err);
	if (user){
		self.authorizedUser = user;
		//[self showMessage:@"authorized!"];
		if (self.authorizationDelegate)
			[self.authorizationDelegate authorizedAs:user];
		self.authorizationDelegate = nil;
	}
}

-(void)sendCode:(NSString *)phone_number
{
	tl_auth_sentCode_t *sentCode =
		tg_auth_sendCode(
				self.tg,
			 	[phone_number UTF8String], 
				self, on_err);
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
		
	// connect to telegram
	NSString *databasePath = [[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] 
			stringByAppendingPathComponent:@"tgdata.db"];
	
	self.tg = tg_new(
			[databasePath UTF8String],
			[[NSUserDefaults standardUserDefaults] integerForKey:@"ApiId"], 
			[[[NSUserDefaults standardUserDefaults] valueForKey:@"ApiHash"] UTF8String]);
	if (!self.tg){
		[self showMessage:@"can't init LibTg"];
		return;
	}
	
	dispatch_queue_t backgroundQueue = 
		dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	// do in background
	dispatch_async(backgroundQueue, ^{
		// check authorized 
		tl_user_t *user = 
			tg_is_authorized(self.tg, NULL, NULL);

		// authorize if needed
		dispatch_async(dispatch_get_main_queue(), ^{
			if (user){
					self.authorizedUser = user;
					//[self showMessage:@"authorized!"];
					if (self.authorizationDelegate)
						[self.authorizationDelegate authorizedAs:user];
					self.authorizationDelegate = nil;
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
