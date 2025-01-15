/**
 * File              : PlaylistsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "ConfigViewController.h"
#include "CoreGraphics/CoreGraphics.h"
#import "TextEditViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#include "QuickLookController.h"

@implementation ConfigViewController

- (void)viewDidLoad {
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	[self reloadData];
}

-(void)reloadData{
	[self.tableView reloadData];	
}

-(void)debugSwitch:(id)sender{
	UISwitch *sw = sender;
	[NSUserDefaults.standardUserDefaults 
		setBool:sw.isOn forKey:@"debug"];
	[self.appDelegate setDebug:sw.isOn];
}

-(void)showNotificationsSwitch:(id)sender{
	UISwitch *sw = sender;
	[self.appDelegate toggleShowNotifications:sw.isOn];
}


#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 3;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section){
		case 0:
			return @"Acounts";
			break;						
		case 1:
			return @"Developing";
			break;						
		case 2:
			return @"Dialogs settings";
			break;						

	}
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = 0;
	if (section == 0)
		rows = 1;
	if (section == 1)
		rows = 2;
	if (section == 2)
		rows = 1;
	
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell; 
	if ((indexPath.section == 1 && indexPath.row == 0) || 
	    (indexPath.section == 2 && indexPath.row == 0)) 
	{
		cell = [self.tableView 
			dequeueReusableCellWithIdentifier:@"cell"];
		if (!cell)
			cell = [[UITableViewCell alloc]
				initWithStyle: UITableViewCellStyleValue1
				reuseIdentifier: @"cell"];
	} else {
		cell = [self.tableView 
			dequeueReusableCellWithIdentifier:@"cellSubTitle"];
		if (!cell)
			cell = [[UITableViewCell alloc]
				initWithStyle: UITableViewCellStyleSubtitle 
				reuseIdentifier: @"cell"];
	}
	
	switch (indexPath.section) {
		case 0: 
			{
				switch (indexPath.row) {
					case 0:
						{
							if (self.appDelegate.authorizedUser) {
								[cell setAccessoryType:
									UITableViewCellAccessoryCheckmark];
								[cell.textLabel setText:@"Authorized!"];
								[cell.detailTextLabel setText:
									[NSString stringWithFormat:@"%s", (char *)self.appDelegate.authorizedUser->username_.data]];
							} else {
								[cell setAccessoryType:
									UITableViewCellAccessoryNone];
								[cell.textLabel setText:@"Not authorize"];
								[cell.detailTextLabel setText:@"click to authorize"];
							}
							break;
						}

					default:
						break;
				}

				break;
			}
		case 1: 
			{
				switch (indexPath.row) {
					case 0:
						{
							cell.textLabel.text = @"Debugging";
							cell.detailTextLabel.text = @"";
							cell.selectionStyle = UITableViewCellSelectionStyleNone;
							UISwitch *sw = [[UISwitch alloc] 
								initWithFrame:CGRectZero];
							cell.accessoryView = sw;
							if ([NSUserDefaults.standardUserDefaults 
								boolForKey:@"debug"])
								[sw setOn:YES animated:NO];
							[sw addTarget:self 
									action:@selector(debugSwitch:) 
									forControlEvents:UIControlEventValueChanged];
						}
						break;
					
					case 1:
						{
							cell.textLabel.text = @"Show log file";
						}
						break;
					
					default:
						break;
				}
			}
			break;
	
		case 2: 
			{
				switch (indexPath.row) {
					case 0:
						{
							cell.textLabel.text = @"Show notifications in dialogs";
							cell.detailTextLabel.text = @"";
							cell.selectionStyle = UITableViewCellSelectionStyleNone;
							UISwitch *sw = [[UISwitch alloc] 
								initWithFrame:CGRectZero];
							cell.accessoryView = sw;
							if ([NSUserDefaults.standardUserDefaults 
								boolForKey:@"showNotifications"])
								[sw setOn:YES animated:NO];
							[sw addTarget:self 
									action:@selector(showNotificationsSwitch:) 
									forControlEvents:UIControlEventValueChanged];
						}
						break;
					
					default:
						break;
				}
			}
			break;

		default:
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case 0: 
			{
				switch (indexPath.row) 
				{
				 case 0:
					 {
						self.appDelegate.authorizationDelegate = self;
						[self.appDelegate authorize];
					 }
					 break;

					default:
						break;
				}

				break;
			}
		case 1: 
			{
				switch (indexPath.row) 
				{
				 case 1:
					 {
						NSString *log = [NSTemporaryDirectory() 
								stringByAppendingPathComponent:@"iTgLegacy.txt"];
						 NSURL *url = [NSURL fileURLWithPath:log];
						QuickLookController *qlc = [[QuickLookController alloc]
							initQLPreviewControllerWithData:@[url]];	
						[self presentViewController:qlc 
															 animated:TRUE completion:nil];
					 }
					 break;

					default:
						break;
				}

				break;
			}
		default:
			break;
	}
	
	// unselect row
	[tableView deselectRowAtIndexPath:indexPath animated:true];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
	//UIActivityIndicatorView *spinner = (UIActivityIndicatorView*)cell.accessoryView;
	//[spinner startAnimating];
	//ActionSheet *as = [[ActionSheet alloc]initWithItem:self.selected isDir:YES onDone:^{
		//[spinner stopAnimating];
	//}];
	//[as showFromTabBar:self.tabBarController.tabBar];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	return false;
}

#pragma mark <AUTHORIZATION DELEGATE FUNCTIONS>
-(void)authorizedAs:(tl_user_t *)user {
	[self reloadData];
}

#pragma mark <TextEditViewController DELEGATE FUNCTIONS>
-(void)textEditViewControllerSaveText:(NSString *)text{
	[[NSUserDefaults standardUserDefaults]setValue:text forKey:self.selectedKey];
	[self reloadData];
}
@end
// vim:ft=objc
