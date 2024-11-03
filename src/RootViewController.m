/**
 * File              : RootViewController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 11.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#include "CoreGraphics/CoreGraphics.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
//#include "YDFile.h"
#include "../libtg/libtg.h"
#import <UIKit/UIKit.h>
#import "RootViewController.h"
//#import "YandexDiskConnect.h"
//#import "FilePickerController.h"

@implementation RootViewController 

//- (id)initWithFile:(YDFile *)file
//{
	//if (self = [super init]) {
		//self.file = file;
	//}
	//return self;
//}

- (void)viewDidLoad {
	[self setTitle:@"Telegram"];
	[self initTgLib];

		//// start Yandex Disk Connect
		//YandexDiskConnect *yc = 
			//[[YandexDiskConnect alloc]initWithFrame:[[UIScreen mainScreen] bounds]];
		//[self presentViewController:yc 
											 //animated:TRUE completion:nil];
	// add buttons
	//UIBarButtonItem *addButtonItem = 
		//[[UIBarButtonItem alloc]
				//initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
				//target:self action:@selector(addButtonPushed:)]; 
	//self.navigationItem.rightBarButtonItem = addButtonItem;
	
	//// search bar
	//self.searchBar = 
		//[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	//self.tableView.tableHeaderView=self.searchBar;	
	//self.searchBar.delegate = self;
	//self.searchBar.placeholder = @"Поиск:";

	// editing style
	//self.tableView.allowsMultipleSelectionDuringEditing = false;
	
	// refresh control
	//self.refreshControl=
		//[[UIRefreshControl alloc]init];
	//[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	//[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	//spinner
	//self.spinner = 
		//[[UIActivityIndicatorView alloc] 
		//initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
	//[self.tableView addSubview:self.spinner];
	//self.spinner.tag = 12;

	// allocate array
	//self.loadedData = [NSMutableArray array];

	// load data
	//[self reloadData];
}

-(void)filterData{
	//if (self.searchBar.text && self.searchBar.text.length > 0)
		//self.data = [self.loadedData filteredArrayUsingPredicate:
				//[NSPredicate predicateWithFormat:@"self.name contains[c] %@", self.searchBar.text]];
	//else
		//self.data = self.loadedData;
	//[self.tableView reloadData];
}

//int callback(const c_yd_file_t *f, void *d, const char *error){
	//RootViewController *self = d;
	//if (error){
		//NSLog(@"%s", error);
		//UIAlertView *alert = 
			//[[UIAlertView alloc]initWithTitle:@"error" 
			//message:[NSString stringWithUTF8String:error] 
			//delegate:nil 
			//cancelButtonTitle:@"Закрыть" 
			//otherButtonTitles:nil];

		//[alert show];
	//}
	//if (f){
		//YDFile *file = [YDFile fromCYDFile:f];
		//[self.loadedData addObject:file];
	//}
	//return 0;
//}

//-(void)reloadData{
	//NSString *token = 
		//[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
	//// animate spinner
	//CGRect rect = self.view.bounds;
	//self.spinner.center = CGPointMake(rect.size.width/2, rect.size.height/2);
	//if (!self.refreshControl.refreshing)
		//[self.spinner startAnimating];

	//dispatch_async(dispatch_get_main_queue(), ^{
				//NSString *path;
		//if (self.file)
			//path = self.file.path;
		//else 
			//path = @"/";
		//[self.loadedData removeAllObjects];
		//c_yandex_disk_ls([token UTF8String], [path UTF8String], self, callback);
		//[self.spinner stopAnimating];
		//[self.refreshControl endRefreshing];
		//[self filterData];
	//});
//}

char * callback(void *userdata, TG_AUTH auth, const tl_t *tl)
{
	switch (auth) {
		case TG_AUTH_PHONE_NUMBER:
			{
				char phone[32];
				printf("enter phone number (+7XXXXXXXXXX): \n");
				scanf("%s", phone);
				return strdup(phone);
			}
			break;
		//case TG_AUTH_SENDCODE:
			//{
				//int code;
				//printf("enter code: \n");
				//scanf("%d", &code);
				//printf("code: %d\n", code);
				//char phone_code[32];
				//sprintf(phone_code, "%d", code);
				//return strdup(phone_code);
			//}
			//break;
		//case TG_AUTH_PASSWORD_NEEDED:
			//{
				//char password[64];
				//printf("enter password: \n");
				//scanf("%s", password);
				//printf("password: %s\n", password);
				//return strdup(password);
			//}
			//break;
		//case TG_AUTH_SUCCESS:
			//{
				//printf("Connected as ");
				//tl_user_t *user = (tl_user_t *)tl;
				//printf("%s (%s)!\n"
						//, user->username_, user->phone_);
			//}
			//break;

		default:
			break;
	}

	return NULL;
}

-(void)tgConnect{
	tg_connect(tg, self, callback);
}

-(void)initTgLib{
	 NSArray *paths =
		 NSSearchPathForDirectoriesInDomains(
				 NSDocumentDirectory, NSUserDomainMask, YES);
	  NSString *documentsDirectory = [paths objectAtIndex:0];
		NSString *filePath = 
			[documentsDirectory 
			stringByAppendingPathComponent:@"libtg.db"];

		self->tg = tg_new(
				[filePath UTF8String],
				24646404,
				"818803c99651e8b777c54998e6ded6a0");
}

-(void)refresh:(id)sender{
	[self reloadData];
}

//-(void)addButtonPushed:(id)selector{
	//FilePickerController *fc;
	//if (self.file)
		//fc = 
			//[[FilePickerController alloc]initWithPath:@"/" ydDir:self.file.path new:true];
	//else 
		//fc = 
			//[[FilePickerController alloc]initWithPath:@"/" ydDir:@"disk:" new:true];
	//UINavigationController *nc =
		//[[UINavigationController alloc]initWithRootViewController:fc];
	//[self presentViewController:nc 
			//animated:TRUE completion:nil];
//}

#pragma mark - TableViewDelegate Meythods
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	//return 1;
//}

//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	//return self.data.count;
//}

//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	//YDFile *file = [self.data objectAtIndex:indexPath.item];
	//UITableViewCell *cell = nil;
	//if ([file.type isEqual:@"dir"]){
		//cell = [self.tableView dequeueReusableCellWithIdentifier:@"dir"];
		//if (cell == nil){
			//cell = [[UITableViewCell alloc]
			//initWithStyle: UITableViewCellStyleDefault 
			//reuseIdentifier: @"dir"];
			//cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
			//cell.imageView.image = [UIImage imageNamed:@"Directory"];
		//}
	//} else {
		//cell = [self.tableView dequeueReusableCellWithIdentifier:@"file"];
		//if (cell == nil){
			//cell = [[UITableViewCell alloc]
			//initWithStyle: UITableViewCellStyleSubtitle 
			//reuseIdentifier: @"file"];
		//}
		////cell.detailTextLabel.text = [NSString stringWithFormat:@"%d Mb", self.selected.size/1024];
	//}
	
	//[cell.textLabel setText:file.name];
	//return cell;
//}

//- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Загрузить ZIP", @"Поделиться", nil];
	//[as showInView:tableView];
//}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = [self.data objectAtIndex:indexPath.item];
	//if ([self.selected.type isEqual:@"dir"]){
		//// open directory in new controller
		//RootViewController *vc = [[RootViewController alloc]initWithFile:self.selected];
		//[self.navigationController pushViewController:vc animated:true];
		//// unselect row
		//[tableView deselectRowAtIndexPath:indexPath animated:true];
		//return;
	//}
	//// open menu
	//UIActionSheet *as = 
			//[[UIActionSheet alloc]
				//initWithTitle:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//destructiveButtonTitle:@"Удалить" 
				//otherButtonTitles:@"Открыть/Загрузить", @"Поделиться", nil];
	//[as showInView:tableView];
	//// unselect row
	//[tableView deselectRowAtIndexPath:indexPath animated:true];
//}
//- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	//// hide keyboard
	//[self.searchBar resignFirstResponder];
//}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	//YDFile *file = [self.data objectAtIndex:indexPath.item];
	//return true;
//}

//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	//self.selected = nil;
	//if (editingStyle == UITableViewCellEditingStyleDelete){
		//self.selected = [self.data objectAtIndex:indexPath.item];
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить файл?" 
				//message:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];
	//}
//}

#pragma mark <SEARCHBAR FUNCTIONS>

//- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	//[self filterData];
//}

//-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
//{
//}

#pragma mark <ALERT DELEGATE FUNCTIONS>
//- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	//if (buttonIndex == 1){
		//NSString *token = 
				//[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		
		//char *error = NULL;
		//int res = c_yandex_disk_rm([token UTF8String], [self.selected.path UTF8String], &error);
		//if (error){
			//NSLog(@"%s", error);
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"error" 
				//message:[NSString stringWithUTF8String:error] 
				//delegate:self 
				//cancelButtonTitle:@"Закрыть" 
				//otherButtonTitles:nil];
			//[alert show];
			//free(error);
			//return;
		//}
		//[self.loadedData removeObject:self.selected];
		//[self filterData];
	//}
//}
#pragma mark <ACTION SHEET DELEGATE>
//- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	//if (buttonIndex == 0){
		//// delete
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"Удалить файл?" 
				//message:self.selected.name 
				//delegate:self 
				//cancelButtonTitle:@"Отмена" 
				//otherButtonTitles:@"Удалить", nil];
			//[alert show];

	//} else if (buttonIndex == 1 || buttonIndex == 2){
		//NSString *token = 
			//[[NSUserDefaults standardUserDefaults]valueForKey:@"token"];
		//char *error = NULL;
		//char *fileurl = c_yandex_disk_file_url([token UTF8String], 
				//[self.selected.path UTF8String], &error);
		//if (error){
			//NSLog(@"%s", error);
			//UIAlertView *alert = 
				//[[UIAlertView alloc]initWithTitle:@"error" 
				//message:[NSString stringWithUTF8String:error] 
				//delegate:nil 
				//cancelButtonTitle:@"Закрыть" 
				//otherButtonTitles:nil];
			//[alert show];
			//free(error);
		//}
		//if (buttonIndex == 1){
			//// open
			//if (fileurl){
				//NSURL *url = [NSURL URLWithString:[NSString stringWithUTF8String:fileurl]];
				//free(fileurl);
				//[[UIApplication sharedApplication]openURL:url];
			//}
		//} else {
			//// make link
			//if (fileurl){
				//char *error = NULL;
				//c_yandex_disk_publish([token UTF8String], [self.selected.path UTF8String], &error);
				//if (error){
					//NSLog(@"%s", error);
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"error" 
							//message:[NSString stringWithUTF8String:error] 
							//delegate:nil 
							//cancelButtonTitle:@"Закрыть" 
							//otherButtonTitles:nil];
					//[alert show];
					//free(error);
					//error = NULL;
				//}
				//c_yd_file_t f;
				//c_yandex_disk_file_info([token UTF8String], [self.selected.path UTF8String], &f, &error);
				//if (error){
					//NSLog(@"%s", error);
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"error" 
							//message:[NSString stringWithUTF8String:error] 
							//delegate:nil 
							//cancelButtonTitle:@"Закрыть" 
							//otherButtonTitles:nil];
					//[alert show];
					//free(error);
					//error = NULL;
				//}
				//if (strlen(f.public_url)>0){
					//NSString *str = [NSString stringWithUTF8String:f.public_url];
					//NSURL *url = [NSURL URLWithString:str];
					//// copy to clipboard
					//[UIPasteboard generalPasteboard].URL = url;
					//[UIPasteboard generalPasteboard].string = str;
					////show massage
					//UIAlertView *alert = 
							//[[UIAlertView alloc]initWithTitle:@"Сылка скопирована в буфер" 
							//message:str 
							//delegate:nil 
							//cancelButtonTitle:@"Ок" 
							//otherButtonTitles:nil];
					//[alert show];
				//}
			//}
		//}
	//}
//}
@end
// vim:ft=objc
