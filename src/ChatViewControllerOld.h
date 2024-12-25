#include "BubbleView/UIBubbleTableView.h"
#include "TGDialog.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatViewController : UIViewController
<UIBubbleTableViewDataSource, UIBubbleTableViewDelegate,
	UIImagePickerControllerDelegate, UITextFieldDelegate,
	UIActionSheetDelegate, UINavigationControllerDelegate>
{
}

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

@property (strong) UIProgressView *progressView;
@property (strong) UILabel *progressLabel;
@property int progressTotal;
@property int progressCurrent;

@property (strong) UIImageView *icon;
@property (strong) NSTimer *timer;
@property (strong) UITextField *textField;
@property (strong, nonatomic) TGDialog *dialog;
@property (strong, nonatomic) NSString *currentImage;
@property (nonatomic, strong) NSMutableArray *bubbleDataArray;
@property (strong) UIImagePickerController *imagePicker;
@property (strong) UIRefreshControl *refreshControl;
@property (strong) UIActivityIndicatorView *spinner;
@property (strong) UIActivityIndicatorView *peerPhotoSpinner;
@property (strong) NSOperationQueue *syncData;
@property (strong) NSOperationQueue *download;


// toolbar
@property (strong) UIBarButtonItem *progress;
@property (strong) UIBarButtonItem *send;
@property (strong) UIBarButtonItem *add;
@property (strong) UIBarButtonItem *textFieldItem;
@property (strong) UIBarButtonItem *flexibleSpace;
@property (strong) UIBarButtonItem *cancel;
@property (strong) UIBarButtonItem *label;

//@property (weak, nonatomic) UITextView *inputField;
@property (strong, nonatomic) UIImageView *inputFieldImageView;

@property (strong) UIImage *peerPhoto;

@property () int position;
-(ChatViewController *)initWithDialog:(TGDialog *)dialog;
@end

// vim:ft=objc
