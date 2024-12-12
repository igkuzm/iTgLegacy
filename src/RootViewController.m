/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "RootViewController.h"
#include "AppDelegate.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "DialogsViewController.h"
#import "ConfigViewController.h"

@implementation RootViewController
- (void)viewDidLoad {
	
	// contacts view
	//DialogsViewController *cvc = 
		//[[DialogsViewController alloc]init];
	//UINavigationController *svnc =
		//[[UINavigationController alloc]initWithRootViewController:cvc];
	UITabBarItem *cvtbi = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemContacts tag:0];
	//[chatsnc setTabBarItem:chatstbi];


	// chats view
	DialogsViewController *chatsvc = 
		[[DialogsViewController alloc]init];
	UINavigationController *chatsnc =
		[[UINavigationController alloc]initWithRootViewController:chatsvc];
	UITabBarItem *chatstbi = [[UITabBarItem alloc]
			initWithTitle:@"Messages" 
			image:[UIImage imageNamed:@"tab-ims"] 
			tag:1];
	[chatsnc setTabBarItem:chatstbi];

	// config view
	ConfigViewController *configvc = 
		[[ConfigViewController alloc]initWithStyle:UITableViewStyleGrouped];
	UINavigationController *confignc =
		[[UINavigationController alloc]initWithRootViewController:configvc];
	UITabBarItem *configtbi = [[UITabBarItem alloc]
			initWithTitle:@"Settings" 
			image:[UIImage imageNamed:@"tab-settings"] 
			tag:2];
	[confignc setTabBarItem:configtbi];


	// search view
	//SearchViewController *searchvc = 
		//[[SearchViewController alloc]init];
	//UINavigationController *searchnc =
		//[[UINavigationController alloc]initWithRootViewController:searchvc];
	//UITabBarItem *searchtbi = [[UITabBarItem alloc]
			//initWithTabBarSystemItem:UITabBarSystemItemSearch tag:1];
	//[searchnc setTabBarItem:searchtbi];

	// player view
	//PlayerViewController *pvc = 
		//[[PlayerViewController alloc]init];
	//UINavigationController *pnc =
		//[[UINavigationController alloc]initWithRootViewController:pvc];
	//UITabBarItem *ptbi = [[UITabBarItem alloc]
		//initWithTitle:@"Плеер" image:[UIImage imageNamed:@"player"] tag:2];
			////initWithTabBarSystemItem:UITabBarSystemItemRecents tag:3];
	//[pnc setTabBarItem:ptbi];


	// favorites view
	//FavoritesViewController *favvc = 
		//[[FavoritesViewController alloc]init];
	//UINavigationController *favnc =
		//[[UINavigationController alloc]initWithRootViewController:favvc];
	//UITabBarItem *favtbi = [[UITabBarItem alloc]
			//initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:3];
	//[favnc setTabBarItem:favtbi];

	// playlists view
	//PlaylistsViewController *plvc = 
		//[[PlaylistsViewController alloc]init];
	//UINavigationController *plnc =
		//[[UINavigationController alloc]initWithRootViewController:plvc];
	//UITabBarItem *pltbi = [[UITabBarItem alloc]
		//initWithTitle:@"Плейлисты" image:[UIImage imageNamed:@"playlist"] tag:4];
			////initWithTabBarSystemItem:UITabBarSystemItemRecents tag:3];
	//[plnc setTabBarItem:pltbi];


	//[self setViewControllers:@[feednc, searchnc, pnc, favnc, plnc] animated:TRUE];
	[self setViewControllers:@[chatsnc, chatsnc, confignc] animated:TRUE];
}

@end


// vim:ft=objc
