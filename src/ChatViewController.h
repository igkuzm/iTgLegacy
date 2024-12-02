#include "BubbleView/UIBubbleTableView.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatViewController : UIViewController
<UIBubbleTableViewDataSource, UIBubbleTableViewDelegate,
	UIImagePickerControllerDelegate>
{
}

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

@property (strong, nonatomic) NSString *currentImage;
@property (nonatomic, strong) NSMutableArray *bubbleDataArray;
@property (strong) UIImagePickerController *imagePicker;

-(ChatViewController *)initWithPeerId:(long)peerId peerType:(int)type accessHash:(long)accessHash;
@end

// vim:ft=objc
