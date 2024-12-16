/**
 * File              : QuickLookController.m
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 31.07.2021
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import "QuickLookController.h"

@implementation QuickLookController
- (id)init
{
	if (self = [super init]) {
		
	}
	return self;
}

-(QuickLookController *)initQLPreviewControllerWithData:(NSArray *)data{
	self = [self init];
	self.data = data;
	self.currentPreviewItemIndex=0;
	self.dataSource = self;
	self.delegate = self;
	return self;
}

#pragma mark - QLPreview Delegate
- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index{
	NSURL *url = [self.data objectAtIndex:index];
	return url;
}
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller{
	return self.data.count;
}

@end
