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

@property () Boolean first;

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

@property (strong) UIImageView *icon;
@property (strong) NSTimer *timer;
@property (strong) UITextField *textField;
@property (strong, nonatomic) TGDialog *dialog;
@property (strong, nonatomic) NSString *currentImage;
@property (nonatomic, strong) NSMutableArray *bubbleDataArray;
@property (nonatomic, strong) NSMutableArray *tmpArray;
@property (nonatomic, strong) NSMutableArray *downloadPhotoArray;
@property (strong) UIImagePickerController *imagePicker;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) UIActivityIndicatorView *peerPhotoSpinner;
@property (strong) NSOperationQueue *syncData;

//@property (weak, nonatomic) UITextView *inputField;
@property (strong, nonatomic) UIImageView *inputFieldImageView;

@property (strong) UIImage *peerPhoto;

@property () int position;
-(ChatViewController *)initWithDialog:(TGDialog *)dialog;
@end

// vim:ft=objc
