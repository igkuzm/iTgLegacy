#import "TGVideoPlayer.h"
#include "Foundation/Foundation.h"
#include "AVFoundation/AVFoundation.h"

@interface  TGVideoPlayer()

@end

@implementation TGVideoPlayer
- (id)initWithView:(UIView *)view
{
	if (self = [super init]) {
		self.items = [NSMutableArray array];
		self.view = view;
		self.player = [AVQueuePlayer alloc];
	}
	return self;
}

- (void)addUrl:(NSURL *)url{
	AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
	[self.items addObject:item];
	//if (self.items.count > 1){
		//AVPlayerItem *prev = 
			//(AVPlayerItem *)([self.items objectAtIndex:self.items.count - 2]);
		//[self.player insertItem:item afterItem:prev];
	//} else{
		[self.player initWithPlayerItem:item];
		self.layer = [AVPlayerLayer playerLayerWithPlayer:self.player];
		[self.view.layer addSublayer:self.layer];
	//}

	[self.player play];
}
@end


// vim:ft=objc
