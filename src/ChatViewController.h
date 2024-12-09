#include "BubbleView/UIBubbleTableView.h"
#include "TGDialog.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatViewController : UIViewController
<UIBubbleTableViewDataSource, UIBubbleTableViewDelegate,
	UIImagePickerControllerDelegate, UITextFieldDelegate>
{
}

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

@property (strong) NSTimer *timer;
@property (strong) UITextField *textField;
@property (strong, nonatomic) TGDialog *dialog;
@property (strong, nonatomic) NSString *currentImage;
@property (nonatomic, strong) NSMutableArray *bubbleDataArray;
@property (nonatomic, strong) NSMutableArray *tmpArray;
@property (strong) UIImagePickerController *imagePicker;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) NSOperationQueue *syncData;

@property (strong) UIImage *peerPhoto;

@property () int position;
-(ChatViewController *)initWithDialog:(TGDialog *)dialog;
@end

// vim:ft=objc
