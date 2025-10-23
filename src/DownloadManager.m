#import "DownloadManager.h"
#include <stdio.h>
#include <stdint.h>
#include "CoreFoundation/CoreFoundation.h"
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
		
	int downloaded = self->progressCurrent + size;
	// do delagate method
	if([[self delegate] respondsToSelector:@selector(downloadManagerProgress:total:)])
		[[self delegate] downloadManagerProgress:downloaded
																			 total:self->progressTotal];
	return self->stopTransfer;
}

int get_document_cb(void *d, const tg_file_t *f){
	DownloadManager *self = (__bridge DownloadManager *)d;

	// stream data
	if (self->chunkNumber == 0){
		char header[BUFSIZ]; 
		sprintf(header,
			"HTTP/1.1 200 OK\\r\\n"
			"Content-Type: %s\\r\\n"
			"Transfer-Encoding: chunked\\r\\n"
			"Connection: keep-alive\\r\\n"
			"\\r\\n", self->mimeType.UTF8String);
	
		[self->socketWrite write:(uint8_t *)header maxLength:strlen(header)];
	}
	
	// write sizeof stream
	char size[32];
	sprintf(size, "%d\\r\\n", f->bytes_.size);
	[self->socketWrite write:(uint8_t *)size maxLength:strlen(size)];

	// write stream data
	[self->socketWrite write:f->bytes_.data maxLength:f->bytes_.size];
	
	// write stream new line
	char newLine[] = "\\r\\n";
	[self->socketWrite write:(uint8_t *)newLine maxLength:strlen(newLine)];
	
	// write file
	[self->file write:f->bytes_.data maxLength:f->bytes_.size];
	
	// update progress
	self->progressCurrent += f->bytes_.size;

	// do delegate
	if([[self delegate] respondsToSelector:@selector(downloadManagerDownloading:)])
		[[self delegate] downloadManagerDownloading:self->url];

	self->chunkNumber++;
	return 0;
}


-(NSString *)filePathForMessage:(TGMessage *)message 
{
	NSString *filepath = nil;
	if (message.isVoice){
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.ogg", 
		message.docId]];
	} else if (message.isVideo){
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.mp4", 
		message.docId]];
	} else {
		filepath = [self.appDelegate.filesCache 
				stringByAppendingPathComponent:
					[NSString stringWithFormat:@"%lld.%@", 
		message.docId, message.docFileName]];
	}
	return filepath;
}

-(NSURL *)downloadFileForMessage:(TGMessage *)message;
{
	NSFileManager *fm = [NSFileManager defaultManager];
	path = [self filePathForMessage:message];
	url = nil;
	progressTotal = message.docSize;
	progressCurrent = 0;
	chunkNumber = 0;
	stopTransfer = NO;
	mimeType = message.mimeType;

	// check file size
	if ([fm fileExistsAtPath:path])
	{
		NSError *error = nil;
		unsigned long long fileSize = 
			[[fm attributesOfItemAtPath:path error:&error] fileSize];
		if (error){
			NSLog(@"%s: ERROR: %@", __func__, error.debugDescription);
		} else {
			if (fileSize == message.docSize)
				return [NSURL fileURLWithPath:path];
		}
	}
	
	// remove file
	[fm removeItemAtPath:path error:nil];
	[fm createFileAtPath:path contents:nil attributes:nil];

	// open file stream
	file = [NSOutputStream outputStreamToFileAtPath:path
																           append:YES];
	if (file == nil){
		NSLog(@"%s: ERROR: can't create output stream", __func__);
	}
	[file open];

	// open socket
	NSString *host = @"127.0.0.1";
	CFStringRef CFShost = (__bridge CFStringRef)host;
	
	int port = 8080;
	
	url = [NSURL URLWithString:
		[NSString stringWithFormat:@"http://%@:%d/%@", 
		host, port, message.docFileName]];

	CFWriteStreamRef writeStream;
	CFReadStreamRef readStream;

	CFStreamCreatePairWithSocketToHost(
			NULL, CFShost, 
			port, &readStream, &writeStream);

	socketRead = (__bridge NSInputStream *)readStream;
	[socketRead setDelegate:self];
	[socketRead scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[socketRead open];
	
	socketWrite = (__bridge NSOutputStream *)writeStream;
	[socketWrite setDelegate:self];
	[socketWrite scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[socketWrite open];

	// download
	if([[self delegate] respondsToSelector:@selector(downloadManagerStart:)])
		[[self delegate] downloadManagerStart:url];
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

	// write stream end
	char end[] = "0\\r\\n";
	[self->socketWrite write:(uint8_t *)end maxLength:strlen(end)];

	[socketRead close];
	[socketWrite close];
	[socketRead removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[socketWrite removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	if (err){
		NSLog(@"document download error");
	} else {
		// check file MD5 SUM

		// write file
		[file close];
		return [NSURL fileURLWithPath:path];
	}

	return nil;
}

-(void)stopTransfer
{
	stopTransfer = YES;
}

-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode 
{
	NSLog(@"STREAM EVENT: %lu", eventCode);
	uint8_t buffer[1024];
	int len;
	switch (eventCode) {
		case NSStreamEventOpenCompleted:
			NSLog(@"STREAM OPENED!");
			break;
		case NSStreamEventHasBytesAvailable:
			if (aStream == socketRead){
				while([socketRead hasBytesAvailable]){
					len = [socketRead read:buffer maxLength:sizeof(buffer)];
					if (len > 0){
						NSLog(@"%s: read %d bytes", __func__, len);
						NSString *out = [[NSString alloc]initWithBytes:buffer 
																									 length:len 
																								 encoding:NSASCIIStringEncoding];
						NSLog(@"GOT MESSAGE: %@", out);
					}
				}
			}
			break;
		case NSStreamEventHasSpaceAvailable:
			if (aStream == socketWrite)
			{
				NSLog(@"HAS SPACE AVAILABLE");
			}
			break;
		case NSStreamEventErrorOccurred:
			NSLog(@"ERROR");
			break;
		case NSStreamEventEndEncountered:
			// todo close streams
			break;

		default:
			break;
	}
}

@end

// vim:ft=objc
