/**
 * File              : ActionSheet.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.08.2023
 * Last Modified Date: 10.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import "ActionSheet.h"
//#include "Item.h"
#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import "AppDelegate.h"

@implementation ActionSheet
- (id)initWithItem:(Item *)item isDir:(BOOL)isDir onDone:(void (^)())onDone
{
	if (self = [super 
			initWithTitle:nil 
					 delegate:self 
					 cancelButtonTitle:@"отмена" 
					 destructiveButtonTitle:nil 
					 otherButtonTitles:
													@"играть", 
													@"играть следующей",
												  @"добавить в плэйлист",	nil]) 
	{
		self.item = item;
		self.onDone = onDone;
		self.isDir = isDir;
		self.additional = NO;
	}
	return self;
}

static int get_tracks(void *data, track_t *track, const char *error)
{ 
	ActionSheet *self = (__bridge ActionSheet *)data;
	if (error){
		NSLog(@"%s", error);
	}

	if (track){
		Item *t = [[Item alloc]initWithTrack:track token:self.item.token];
		self.onAdd(t);
		dispatch_sync(dispatch_get_main_queue(), ^{
			// Update your UI
		});
	}
	return 0;
}

-(void)addTracks:(void (^)(Item *item))onAdd{
	self.onAdd = onAdd;
	if (self.item.itemType == ITEM_PLAYLIST)
		{
			[[[NSOperationQueue alloc]init] addOperationWithBlock:^{
				c_yandex_music_get_playlist_tracks(
						[self.item.token UTF8String], "100x100",
						self.item.uid, self.item.kind,	
						(__bridge void *)self, get_tracks);
			}];
		}
	else if (self.item.itemType == ITEM_PODCAST ||
						 self.item.itemType == ITEM_ALBUM)
		{
			[[[NSOperationQueue alloc]init] addOperationWithBlock:^{
				c_yandex_music_get_album_tracks(
						[self.item.token UTF8String], "100x100",
						[self.item.itemId intValue],	
						(__bridge void *)self, get_tracks);
			}];
		}
}

#pragma mark <ACTION SHEET DELEGATE>
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	AppDelegate *a = [[UIApplication sharedApplication]delegate];
	switch (buttonIndex){
		case 0: 
			{
				if (self.isDir){
					[self addTracks:^(Item *item){
						if(self.additional)	
							[a.player addToLast:item];
						else {
							[a.player addToTopAndPlay:item onDone:self.onDone];
							self.additional = YES;
						}
					}];
				} else
					[a.player addToTopAndPlay:self.item onDone:self.onDone];
				break;
			}
		case 1:
			{
				if (self.isDir){
					[self addTracks:^(Item *item){
						if(self.additional)	
							[a.player addToLast:item];
						else {
							[a.player addAfterCurrent:item];
							self.additional = YES;
						}
					}];
				} else
					[a.player addAfterCurrent:self.item];
				if (self.onDone)
					self.onDone();
				break;
			}
		case 2:
			{
				if (self.isDir){
					[self addTracks:^(Item *item){
						[a.player addToLast:item];
					}];
				} else
					[a.player addToLast:self.item];
				if (self.onDone)
					self.onDone();
				break;
			}
		
		default:
			{
				if (self.onDone)
					self.onDone();
				break;
			} 
	}
}
@end

// vim:ft=objc
