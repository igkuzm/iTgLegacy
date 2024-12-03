#import "ChatViewController.h"
#include "CoreGraphics/CoreGraphics.h"
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

- (void)viewWillAppear:(BOOL)animated {
    [UINavigationBar.appearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    //[UINavigationBar.appearance setTintColor:[UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0]];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	CGRect frame = 
		CGRectMake(
				0, 
				0, 
				self.view.frame.size.width, 
				self.view.frame.size.height - 85);

	UIBubbleTableView *bubbleTableView = 
			[[UIBubbleTableView alloc]initWithFrame:frame
			style:UITableViewStylePlain];
		[self.view addSubview:bubbleTableView];
		self.bubbleTableView = bubbleTableView;

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
	
	// refresh control
	self.refreshControl= [[UIRefreshControl alloc]init];
	[self.refreshControl setAttributedTitle:[[NSAttributedString alloc] initWithString:@"more messages..."]];
	[self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
	[self.bubbleTableView addSubview:self.refreshControl];

	[self reloadData];
}

- (void)reloadData {
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}

	[self.bubbleDataArray removeAllObjects];

	buf_t peer = 
		tg_inputPeer(self.dialog.peerType,
				self.dialog.peerId,
			 	self.dialog.accessHash);
	
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

	[self.bubbleTableView reloadData];
}

- (void)appendDataFrom:(int)p {
	if (!self.dialog){
		[self.appDelegate showMessage:@"ERR. Dialog is NULL"];
		return;
	}

	buf_t peer = 
		tg_inputPeer(self.dialog.peerType,
				self.dialog.peerId,
			 	self.dialog.accessHash);
	
		tg_messages_getHistory(
			self.appDelegate.tg, 
			&peer, 
			0, 
			time(NULL), 
			p, 
			20, 
			0, 
			0, 
			NULL, 
			self, 
			messages_callback);

	[self.bubbleTableView reloadData];
	[self.refreshControl endRefreshing];
}

-(void)refresh:(id)sender{
	[self appendDataFrom:self.bubbleDataArray.count];
}

#pragma mark <messages_getHistory callback>
static int messages_callback(void *d, const tg_message_t *m){
	ChatViewController *self = d;
	if (m->message_ && m->peer_id_ == self.dialog.peerId){
		bool me = (m->from_id_ == self.appDelegate.authorizedUser->id_);
		NSBubbleData *bd = 
			[[NSBubbleData alloc]
				initWithText:[NSString stringWithUTF8String:m->message_] 
				date:[NSDate dateWithTimeIntervalSince1970:m->date_] 
				type:me?BubbleTypeMine:BubbleTypeSomeoneElse];

		[self.bubbleDataArray addObject:bd];
	}

	return 0;
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
