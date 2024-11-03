/**
 * File              : AppDelegate.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 10.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#include "RootViewController.h"

#define CLIENTID "e6018bd0ccda4ea5b1db3c612a8db314"
#define CLIENTSECRET "b4eb1d22066145d094c6b0bd7a2a27f6"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];	
	//if ([[NSUserDefaults standardUserDefaults] valueForKey:@"launchBool"]){
		//[self handleWithURL:self.url onWindow:self.window];
	//} else {
		//YandexDiskConnect *yc = 
			//[[YandexDiskConnect alloc]initWithFrame:self.window.frame];
		RootViewController *vc = 
			[[RootViewController alloc]init];
		UINavigationController *nc = 
			[[UINavigationController alloc]initWithRootViewController:vc];
		[self.window setRootViewController:nc];
	//}	
	[self.window makeKeyAndVisible];	
	
	return true;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
	return true;
}


@end
// vim:ft=objc

