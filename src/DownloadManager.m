#import "DownloadManager.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "../libtg/libtg.h"
#import "../libtg/tg/files.h"

@implementation DownloadManager
- (id)init
{
	if (self = [super init]) {
		progressCurrent = 0;
		progressTotal = 0;
		chunkNumber = 0; 
		self.appDelegate = 
			[[UIApplication sharedApplication]delegate];
	}
	return self;
}

+(DownloadManager *)downloadManager{
	DownloadManager *dm = [[DownloadManager alloc]init];
	return dm;
}

int download_progress(void *d, int size, int total){
	DownloadManager *self = (__bridge DownloadManager *)d;
	// do delagate method
	if([[self delegate] respondsToSelector:@selector(downloadManagerProgres:total:)])
		[[self delegate] downloadManagerProgress:size
																			 total:total];
	return self->stopTransfer;
}

int get_document_cb(void *d, const tg_file_t *f){
	DownloadManager *self = (__bridge DownloadManager *)d;
	NSString *path = 
		[self->path stringByAppendingFormat:@".part%ld", 
		self->chunkNumber++]; 
	
	// write chunk
	NSOutputStream *chunk = 
				[NSOutputStream outputStreamToFileAtPath:path
																      append:YES];
	if (chunk == nil){
		NSLog(@"%s: ERROR: can't create output stream", __func__);
	}
	[chunk open];
	[chunk write:f->bytes_.data maxLength:f->bytes_.size];
	[chunk close];

	// write file
	[self->file write:f->bytes_.data maxLength:f->bytes_.size];
	
	// update progress
	self->progressCurrent += f->bytes_.size;

	// do delegate
	if([[self delegate] respondsToSelector:@selector(downloadManagerChunk:)])
		[[self delegate] downloadManagerChunk:path];
	return 0;
}

-(NSString *)downloadFileForMessage:(TGMessage *)message;
{
	if (message.isVoice){
		path = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.ogg", 
		message.docId]];
	} else if (message.isVideo){
		path = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.mp4", 
		message.docId]];
	} else {
		path = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.%@", 
		message.docId, message.docFileName]];
	}

	// check file SUMM
	//
	
	// remove file
	[NSFileManager.defaultManager removeItemAtPath:path 
																				 error:nil];

	[NSFileManager.defaultManager createFileAtPath:path 
																				contents:nil 
																			attributes:nil];

	// open stream
	file = [NSOutputStream outputStreamToFileAtPath:path
																           append:YES];
	if (file == nil){
		NSLog(@"%s: ERROR: can't create output stream", __func__);
	}
	[file open];

	// download
	progressTotal = message.docSize;
	progressCurrent = 0;
	stopTransfer = NO;

	int err = tg_get_document(
			self.appDelegate.tg, 
			message.docId,
			message.docSize, 
			message.docAccessHash, 
			[message.docFileReference UTF8String], 
			(__bridge void *)self,
			get_document_cb,
			(__bridge void *)self,
			download_progress);

	if (err){
		NSLog(@"document download error");
		// do delegate 
	} else {
		// check file MD5 SUM

		// write file
		[file close];

		// remove parts
		return path;
	}
}

-(void)stopTransfer
{
	stopTransfer = YES;
}

@end

// vim:ft=objc
