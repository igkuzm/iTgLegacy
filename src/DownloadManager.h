#import <Foundation/Foundation.h>
#import "TGMessage.h"
#import "AppDelegate.h"

@protocol DownloadManagerDelegate <NSObject>
-(void)downloadManagerProgress:(int)size
												 total:(int)total;

-(void)downloadManagerChunk:(NSString *)chunkPath;

@end

@interface DownloadManager : NSObject
{
	NSInteger progressTotal;
	NSInteger progressCurrent;
	NSInteger chunkNumber;
	Boolean stopTransfer;
	NSString *path;
	NSOutputStream *file;
}

@property (strong) AppDelegate *appDelegate;
@property (strong) id<DownloadManagerDelegate>delegate;

+(DownloadManager *)downloadManager;
-(NSString *)downloadFileForMessage:(TGMessage *)message;
-(void)stopTransfer;

@end
// vim:ft=objc
