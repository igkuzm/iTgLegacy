#include "AudioToolbox/AudioToolbox.h"
#include "BubbleView/UIBubbleTableView.h"
#import "MediaPlayer/MediaPlayer.h"
#import "AVFoundation/AVAudioRecorder.h"
#include "TGDialog.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface ChatViewController : UIViewController
<UIBubbleTableViewDataSource, UIBubbleTableViewDelegate,
	UIImagePickerControllerDelegate, UITextFieldDelegate,
	UIActionSheetDelegate, UINavigationControllerDelegate,
	AppActivityDelegate, AuthorizationDelegate>
{
}

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

//@property (strong) MPMoviePlayerController *moviePlayerController;
//@property (strong) MPMoviePlayerViewController *moviePlayerController;

@property (strong) AVAudioRecorder *audioRecorder;
@property (strong) NSMutableDictionary *recordSettings;

@property SystemSoundID recordStart;

@property Boolean textFieldIsEditable;

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
@property (strong) UIBarButtonItem *record;

//@property (weak, nonatomic) UITextView *inputField;
@property (strong, nonatomic) UIImageView *inputFieldImageView;

@property (strong) UIImage *peerPhoto;

@property () int position;
-(ChatViewController *)initWithDialog:(TGDialog *)dialog;
@end

// vim:ft=objc
