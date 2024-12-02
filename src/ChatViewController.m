#import "ChatViewController.h"
#include "Foundation/Foundation.h"
#include "BubbleView/NSBubbleData.h"
#include "BubbleView/UIBubbleTableView.h"
#include "../libtg/tg/peer.h"
#include "../libtg/tg/messages.h"

@interface  ChatViewController()
{
}
@end

@implementation ChatViewController

int peerType;
long peerId;
long accessHash;

-(ChatViewController *)initWithPeerId:(long)peerId peerType:(int)type accessHash:(long)accessHash;
{
	if (self = [super init]) {
		UIBubbleTableView *bubbleTableView = 
			[[UIBubbleTableView alloc]initWithFrame:self.view.bounds
			style:UITableViewStylePlain];
		[self.view addSubview:bubbleTableView];
		self.bubbleTableView = bubbleTableView;
		peerId = peerId;
		peerType = type;
		accessHash = accessHash;
	}
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
		
	self.appDelegate = [[UIApplication sharedApplication]delegate];
	
	self.bubbleTableView.bubbleDataSource = self;
	self.bubbleTableView.watchingInRealTime = YES;
	self.bubbleTableView.snapInterval = 2800;
	self.bubbleDataArray = [NSMutableArray array];
	self.bubbleTableView.showAvatars = [[NSUserDefaults standardUserDefaults] boolForKey:@"showPFP"];
	[self.bubbleTableView reloadData];
		
  //self.imagePicker = [[UIImagePickerController alloc] init];
  //self.imagePicker.delegate = self;
  //self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	[self reloadData];
}

int messages_callback(void *d, const tg_message_t *m){
	ChatViewController *self = d;
	[self.appDelegate showMessage:[NSString stringWithUTF8String:m->message_]];
	return 0;
	NSBubbleData *bd = 
		[[NSBubbleData alloc]
			initWithText:[NSString stringWithUTF8String:m->message_] 
			date:[NSDate dateWithTimeIntervalSince1970:m->date_] 
			type:BubbleTypeSomeoneElse];

	[self.bubbleDataArray addObject:bd];

	return 0;
}

- (void)reloadData {
	[self.bubbleDataArray removeAllObjects];
	
	buf_t peer = 
		tg_inputPeer(peerType, peerId, accessHash);
	
	tg_messages_getHistory(
			self.appDelegate.tg, 
			&peer, 
			0, 
			time(NULL), 
			0, 
			20, 
			0, 
			0, 
			NULL, 
			self, 
			messages_callback);
	
	//[self.bubbleTableView reloadData];
}
			
#pragma mark <UIBubbleTableViewDelegate>
- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectRow:(int)row 
{
  NSLog(@"selected");
}


#pragma mark <UIBubbleTableViewDataSource>
- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row 
{
	return [self.bubbleDataArray objectAtIndex:row];
}
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView 
{
	return self.bubbleDataArray.count;
}

@end
// vim:ft=objc
