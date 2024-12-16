/**
 * File              : FilePickerController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 10.08.2023
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "FilePickerController.h"
#include "sys/syslimits.h"
#include <stddef.h>
#include "stdbool.h"
#include <stdlib.h>
#include <stdio.h>
#include "UIKit/UIKit.h"
#include "sys/dirent.h"
#include "Foundation/Foundation.h"
#include <dirent.h>
#include <sys/stat.h>

@implementation FileObj
- (id)initWithDirent:(struct dirent *)d
{
	if (self = [super init]) {
		self.name = [NSString stringWithUTF8String:d->d_name];	
		self.type = isDir(d) ? DT_DIR : d->d_type;
	}
	return self;
}
static _Bool isDir(struct dirent *d)
{
	if (d->d_type == DT_DIR)
		return true;
	if (d->d_type == DT_LNK){
		// try to open dir
		DIR *dir = opendir(d->d_name);
		if (dir){
			closedir(dir);
			return true;
		}
	}
	return false;
}
@end

@implementation FilePickerController

- (id)initWithPath:(NSString *)path isNew:(BOOL)new
{
	if (self = [super init]) {
		self.path = path;
		self.new = new;
	}
	return self;
}

- (void)viewDidLoad {
	// set title
	self.title = [self.path lastPathComponent];

	// add buttons
	UIBarButtonItem *doneButtonItem = 
		[[UIBarButtonItem alloc]
				initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
				target:self action:@selector(doneButtonPushed:)]; 
	self.navigationItem.rightBarButtonItem = doneButtonItem;

	
	// search bar
	self.searchBar = 
		[[UISearchBar alloc] initWithFrame:CGRectMake(0,70,320,44)];
	self.tableView.tableHeaderView=self.searchBar;	
	self.searchBar.delegate = self;
	self.searchBar.placeholder = @"Поиск:";

	// refresh control
	self.refreshControl=
		[[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@""]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];

	// load data
	self.loadedData = [NSMutableArray array];
	[self reloadData];

	if (self.new){
		if ([self.path isEqual:@"/"]){
			NSString *path = 
				[NSString stringWithFormat:@"/var"];
				FilePickerController *fc = 
						[[FilePickerController alloc]initWithPath:path isNew:true];
				[self.navigationController pushViewController:fc animated:false];
		} else if ([self.path isEqual:@"/var"]){
				NSString *path = 
				[NSString stringWithFormat:@"/var/mobile"];
				FilePickerController *fc = 
						[[FilePickerController alloc]initWithPath:path isNew:false];
				[self.navigationController pushViewController:fc animated:false];
		}
	} 
}

static int 
file_select_filter(const struct dirent *d){
	// no names start with dot
	if (d->d_name[0] == '.')
			return 0;
	return 1;
}

-(void)reloadData{
		dispatch_async(dispatch_get_main_queue(), ^{
			[self.loadedData removeAllObjects];
			struct dirent **dirents;
			int count = scandir ([self.path UTF8String], &(dirents), 
					file_select_filter, alphasort);
			NSMutableArray *dirs = [NSMutableArray array];
			NSMutableArray *files = [NSMutableArray array];
			int i;
			for (i = 0; i < count; ++i) {
				struct dirent *d = dirents[i];
				FileObj *file = 
						[[FileObj alloc]initWithDirent:d];
				// sort - directories first
				if (file.type == DT_DIR)
					[dirs addObject:file];
				else
					[files addObject:file];
			}
			// add files to data
			[self.loadedData addObjectsFromArray:dirs];
			[self.loadedData addObjectsFromArray:files];
			if (self.searchBar.text && self.searchBar.text.length > 0)
				self.data = [self.loadedData filteredArrayUsingPredicate:
						[NSPredicate predicateWithFormat:@"self.name contains[c] %@", self.searchBar.text]];
			else
				self.data = self.loadedData;
		[self.tableView reloadData];
	});
}

-(void)refresh:(id)sender{
	[self reloadData];
}

-(void)doneButtonPushed:(id)sender{
	[self.navigationController dismissViewControllerAnimated:true completion:nil];
}

#pragma mark <TableViewDelegate Meythods>
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return self.path;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	FileObj *file = [self.data objectAtIndex:indexPath.item];
	UITableViewCell *cell = nil;
	NSString *path = 
			[NSString stringWithFormat:@"%@/%@", self.path, file.name];
	if (file.type == DT_DIR){
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"dir"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
			initWithStyle: UITableViewCellStyleDefault 
			reuseIdentifier: @"dir"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.imageView.image = [UIImage imageNamed:@"Directory"];
		}
	} else {
		cell = [self.tableView dequeueReusableCellWithIdentifier:@"file"];
		if (cell == nil){
			cell = [[UITableViewCell alloc]
			initWithStyle: UITableViewCellStyleSubtitle 
			reuseIdentifier: @"file"];
		}
	}
	
	[cell.textLabel setText:file.name];
	//[cell.description setText:[NSString stringWithFormat:@"%d Mb", file.size/1024]];
	return cell;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];
	// open directory in new controller
	NSString *path = 
		[NSString stringWithFormat:@"%@/%@", self.path, self.selected.name];
	FilePickerController *fc = 
			[[FilePickerController alloc]initWithPath:path isNew:false];
	[self.navigationController pushViewController:fc animated:true];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	self.selected = [self.data objectAtIndex:indexPath.item];
	NSString *path = 
			[NSString stringWithFormat:@"%@/%@", self.path, self.selected.name];
	if (self.selected.type == DT_DIR){
		// open directory in new controller
		FilePickerController *fc = 
				[[FilePickerController alloc]initWithPath:path isNew:false];
		[self.navigationController pushViewController:fc animated:true];
		return;
	}
	UIActionSheet *as = 
			[[UIActionSheet alloc]
				initWithTitle:self.selected.name 
				delegate:self 
				cancelButtonTitle:@"Отмена" 
				destructiveButtonTitle:nil 
				otherButtonTitles:@"Отправить", nil];
	[as showInView:tableView];
	// unselect row
	[self.tableView deselectRowAtIndexPath:indexPath animated:true];
}
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// hide keyboard
	[self.searchBar resignFirstResponder];
}

#pragma mark <SEARCHBAR FUNCTIONS>

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText{
	if (searchBar.text && searchBar.text.length > 0)
		self.data = [self.loadedData filteredArrayUsingPredicate:
			[NSPredicate predicateWithFormat:@"self.name contains[c] %@", self.searchBar.text]];
	else 
		self.data = self.loadedData;

	[self.tableView reloadData];
}

-(void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
}

void upload_file_callback(FILE *fp, size_t size, void *d, const char *error){
	FilePickerController *self = d;
	if (error){
			NSLog(@"%s", error);
			UIAlertView *alert = 
				[[UIAlertView alloc]initWithTitle:@"error" 
				message:[NSString stringWithUTF8String:error] 
			  delegate:self 
				cancelButtonTitle:@"Закрыть" 
				otherButtonTitles:nil];
			[alert show];
	}
	if (size){
		NSLog(@"uploaded: %zu", size);
	}
	fclose(fp);
}
	

#pragma mark <ALERT DELEGATE FUNCTIONS>
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// send image
	}
}	
@end

// vim:ft=objc
