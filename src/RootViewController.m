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
#import "ContactsListViewController.h"

@implementation RootViewController
- (void)viewDidLoad {
	
	// contacts view
	ContactsListViewController *cvc = 
		[[ContactsListViewController alloc]init];
	cvc.title = @"Contacts";
	[cvc getContacts];
	UINavigationController *cvnc =
		[[UINavigationController alloc]initWithRootViewController:cvc];
	UITabBarItem *cvtbi = [[UITabBarItem alloc]
			initWithTabBarSystemItem:UITabBarSystemItemContacts tag:0];
	[cvnc setTabBarItem:cvtbi];

	// chats view
	DialogsViewController *dvc = 
		[[DialogsViewController alloc]init];
	dvc.title = @"Dialogs";
	UINavigationController *dvcnc =
		[[UINavigationController alloc]initWithRootViewController:dvc];
	UITabBarItem *dvctbi = [[UITabBarItem alloc]
		initWithTabBarSystemItem:UITabBarSystemItemRecents tag:1];
	[dvcnc setTabBarItem:dvctbi];

	// config view
	ConfigViewController *configvc = 
		[[ConfigViewController alloc]initWithStyle:UITableViewStyleGrouped];
	configvc.title = @"Config";
	UINavigationController *confignc =
		[[UINavigationController alloc]initWithRootViewController:configvc];
	UITabBarItem *configtbi = [[UITabBarItem alloc]
		initWithTabBarSystemItem:UITabBarSystemItemMore tag:2];

	[confignc setTabBarItem:configtbi];

	[self setViewControllers:@[cvnc, dvcnc, confignc] animated:TRUE];
	[self setSelectedViewController:dvcnc];
}

@end


// vim:ft=objc
