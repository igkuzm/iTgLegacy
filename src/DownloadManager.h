#import <Foundation/Foundation.h>
#import "TGMessage.h"
#import "AppDelegate.h"

@protocol DownloadManagerDelegate <NSObject>
-(void)downloadManagerProgress:(int)size
												 total:(int)total;

-(void)downloadManagerStart:(NSURL *)url;
-(void)downloadManagerDownloading:(NSURL *)url;

@end

@interface DownloadManager : NSObject
<NSStreamDelegate>
{
	NSInteger progressTotal;
	NSInteger progressCurrent;
	NSInteger chunkNumber;
	Boolean stopTransfer;
	NSString *path;
	NSURL *url;
	NSOutputStream *file;
	NSOutputStream *socketWrite;
	NSInputStream *socketRead;
	NSString *mimeType;
}

@property (strong) AppDelegate *appDelegate;
@property (strong) id<DownloadManagerDelegate>delegate;

+(DownloadManager *)downloadManager;
-(NSString *)filePathForMessage:(TGMessage *)message;
-(NSURL *)downloadFileForMessage:(TGMessage *)message;
-(void)stopTransfer;

@end
// vim:ft=objc
