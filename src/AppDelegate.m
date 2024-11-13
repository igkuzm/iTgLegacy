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

char * tg_connect_cb(
			void *userdata,
			TG_AUTH auth,
			const tl_t *tl,
			const char *error)
{
	AppDelegate *self = userdata;
	switch (auth) {
		case TG_AUTH_PHONE_NUMBER:
			{
				[self askInput:@"enter phone number (+7XXXXXXXXXX)"];
				return [self.askInputText UTF8String];
			}
			break;
		case TG_AUTH_SENDCODE:
			{
				[self askInput:@"enter code"];
				return [self.askInputText UTF8String];
			}
			break;
		case TG_AUTH_PASSWORD_NEEDED:
			{
				[self showMessage:@"password needed - not implyed yet"];
			}
			break;
		case TG_AUTH_SUCCESS:
			{
				tl_user_t *user = (tl_user_t *)tl;
				[self showMessage:[NSString stringWithFormat:
					@"Connected as %s (%s)!", 
						string_from_buf(user->username_), 
						string_from_buf(user->phone_)
				]];
			}
			break;
		case TG_AUTH_ERROR:
			{
				[self showMessage:[NSString stringWithUTF8String:error]];
			}
			break;

		default:
			break;
	}

	return NULL;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	// Override point for customization after application launch.
	//[[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
	//self.player = [[PlayerController alloc]init];
	
		self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	RootViewController *vc = 
			[[RootViewController alloc]init];
	[self.window setRootViewController:vc];
	[self.window makeKeyAndVisible];	
	
	// connect to telegram
	NSString *databasePath = [[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, NSUserDomainMask, YES) 
						objectAtIndex:0] 
			stringByAppendingPathComponent:@"tgdata.db"];
	
	tg_t *tg = tg_new(
			[databasePath UTF8String],
			24646404, 
			"818803c99651e8b777c54998e6ded6a0");
	
	tg_connect(tg, self, tg_connect_cb);

	return true;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
	if (event.type == UIEventTypeRemoteControl) {
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
	}
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

-(void)askInput:(NSString *)msg{
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
	self.askInputText = textField.text;
	//if (buttonIndex == 1){
	//}
}
@end
// vim:ft=objc

