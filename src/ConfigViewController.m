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
#import "InputToolBar.h"

@implementation ConfigViewController

enum {
	STEPPER_CHAT_INTERVAL,
};

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
	return 4;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
	switch (section){
		case 0:
			return @"Acounts";
			break;						
		case 1:
			return @"Dialogs settings";
			break;						
		case 2:
			return @"Donations";
			break;						
		case 3:
			return @"Developing";
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
		rows = 2;
	if (section == 3)
		rows = 3;
	
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell; 
	if ((indexPath.section == 1 && indexPath.row == 0) || 
			(indexPath.section == 1 && indexPath.row == 1) || 
	    (indexPath.section == 3 && indexPath.row == 0)) 
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
							cell.textLabel.text = @"Show notifications in dialogs";
							cell.detailTextLabel.text = @"";
							cell.selectionStyle = UITableViewCellSelectionStyleNone;
							UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectZero];
							cell.accessoryView = sw;
							if ([NSUserDefaults.standardUserDefaults 
								boolForKey:@"showNotifications"])
								[sw setOn:YES animated:NO];
							[sw addTarget:self 
									action:@selector(showNotificationsSwitch:) 
									forControlEvents:UIControlEventValueChanged];
						}
						break;
					case 1:
						{
							cell.selectionStyle = UITableViewCellSelectionStyleNone;
							UIStepper *st = [[UIStepper alloc]initWithFrame:CGRectZero];
							cell.accessoryView = st;
							st.tag = STEPPER_CHAT_INTERVAL;
							st.minimumValue = 5;
							st.maximumValue = 120;
							st.stepValue = 5; 
							NSInteger sec = [NSUserDefaults.standardUserDefaults 
								integerForKey:@"chatUpdateInterval"];
							if (sec < 5 || sec > 120)
								sec = 120;
							st.value = sec;
							cell.textLabel.text = 
								[NSString stringWithFormat:@"Update interval %lds", sec];
							cell.detailTextLabel.text = @"";
							//cell.detailTextLabel.text = 
								//[NSString stringWithFormat:@"%ld sec", sec];
							//cell.textLabel.text = @"Chat update interval";
							[st addTarget:self 
									action:@selector(stepperChanged:) 
					        forControlEvents:UIControlEventValueChanged];
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
							cell.textLabel.text = @"Make a donation";
							cell.detailTextLabel.text = @"https://www.donationalerts.com/r/igkuzm";
						}
						break;
					case 1:
						{
							cell.textLabel.text = @"QR-code";
						}
						break;
					

					default:
						break;
				}
			}
			break;


		case 3: 
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
							cell.textLabel.text = @"Current log";
						}
						break;
					
					case 2:
						{
							cell.textLabel.text = @"Last log";
						}
						break;
					case 3:
						{
							cell.textLabel.text = @"test input bar";
						}
					
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

		case 2: 
			{
				switch (indexPath.row) 
				{
				 case 0:
					 {
						 // open donation URL
						 UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
						 NSURL *url = [NSURL URLWithString:cell.detailTextLabel.text];
						 [UIApplication.sharedApplication openURL:url];
					 }
					 break;
					case 1:
					 {
						 // show QR-code
						 NSString *qrcodePath = [[NSBundle mainBundle] 
							 pathForResource:@"qrcode" ofType:@"jpg"];	 
						 NSURL *url = [NSURL fileURLWithPath:qrcodePath];
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

		case 3: 
			{
				switch (indexPath.row) 
				{
				 case 1:
					 {
						NSString *cache = [NSSearchPathForDirectoriesInDomains(
						NSCachesDirectory, 
						NSUserDomainMask,
						YES) objectAtIndex:0]; 
	
						NSString *log = [cache 
								stringByAppendingPathComponent:@"log.txt"];
						//NSString *log = [NSTemporaryDirectory() 
								//stringByAppendingPathComponent:@"log.txt"];
						 NSURL *url = [NSURL fileURLWithPath:log];
						QuickLookController *qlc = [[QuickLookController alloc]
							initQLPreviewControllerWithData:@[url]];	
						[self presentViewController:qlc 
															 animated:TRUE completion:nil];
					 }
					 break;
					
				 case 2:
					 {
						NSString *log = [NSTemporaryDirectory() 
								stringByAppendingPathComponent:@"lastlog.txt"];
						 NSURL *url = [NSURL fileURLWithPath:log];
						QuickLookController *qlc = [[QuickLookController alloc]
							initQLPreviewControllerWithData:@[url]];	
						[self presentViewController:qlc 
															 animated:TRUE completion:nil];
					 }
					 break;

				 //case 3:
					 //{
						 //InputToolBar *ip = [[InputToolBar alloc]init];
						 //ip.frame = CGRectMake(
								 //0, self.view.frame.size.height-40, 
								 //self.view.frame.size.width, 40);
						 //[self.view addSubview:ip];
					 //}
						//break;

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
#pragma mark <UITextField DELEGATE FUNCTIONS>
- (void)textFieldDidEndEditing:(UITextField *)textField {
	[NSUserDefaults.standardUserDefaults 
		setInteger:textField.text.intValue 
				forKey:@"chatUpdateInterval"];	
}
#pragma mark <UIStepper FUNCTIONS>
-(void)stepperChanged:(UIStepper *)stepper{
	[NSUserDefaults.standardUserDefaults
	 setInteger:stepper.value forKey:@"chatUpdateInterval"];
	NSIndexPath* indexPath = 
		[NSIndexPath indexPathForRow:1 inSection:1];
	[self.tableView reloadRowsAtIndexPaths:@[indexPath] 
									withRowAnimation:UITableViewRowAnimationNone];
}
@end
// vim:ft=objc
