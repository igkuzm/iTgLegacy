/**
 * File              : PlaylistsViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 22.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "ConfigViewController.h"
#import "TextEditViewController.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"

@implementation ConfigViewController

- (void)viewDidLoad {
	self.title = @"Config";
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	[self reloadData];
}

-(void)reloadData{
	[self.tableView reloadData];	
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section){
		case 0:
			return @"Настройки API";
			break;						
	}
	return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSInteger rows = 0;
	if (section == 0)
		rows = 3;
	
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil){
			cell = [[UITableViewCell alloc]
				initWithStyle: UITableViewCellStyleSubtitle 
				reuseIdentifier: @"cell"];
	}

	switch (indexPath.section) {
		case 0: {
							switch (indexPath.row) {
								case 0:{
													[cell setAccessoryType:
														UITableViewCellAccessoryDisclosureIndicator];
													[cell.textLabel setText:@"ApiId"];
													[cell.detailTextLabel setText:
														[[NSUserDefaults standardUserDefaults]valueForKey:@"ApiId"]];
													break;
											 }
								case 1:{
													[cell setAccessoryType:
														UITableViewCellAccessoryDisclosureIndicator];
													[cell.textLabel setText:@"ApiHash"];
													[cell.detailTextLabel setText:
														[[NSUserDefaults standardUserDefaults]valueForKey:@"ApiHash"]];
													break;
											 }
								case 2:{
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
	
		default:
			break;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
	switch (indexPath.section) {
		case 0: {
							switch (indexPath.row) {
								case 0:{
													self.selectedKey = @"ApiId";
													TextEditViewController *twc = 
														[[TextEditViewController alloc]init];
													[twc setText:[[NSUserDefaults standardUserDefaults]
														valueForKey:@"ApiId"]];
													[twc setDelegate:self];
													[self.navigationController pushViewController:twc animated:true];
													break;
											 }
								case 1:{
													self.selectedKey = @"ApiHash";
													TextEditViewController *twc = 
														[[TextEditViewController alloc]init];
													[twc setText:[[NSUserDefaults standardUserDefaults]
														valueForKey:@"ApiHash"]];
													[twc setDelegate:self];
													[self.navigationController pushViewController:twc animated:true];
													break;
											 }
							 case 2:{
													self.appDelegate.authorizationDelegate = self;
													[self.appDelegate authorize];
													break;
											 }
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
