#include "AudioToolbox/AudioToolbox.h"
#include "BubbleView/UIBubbleTableView.h"
#import "MediaPlayer/MediaPlayer.h"
#import "AVFoundation/AVAudioRecorder.h"
#import "FilePickerController.h"
#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>
#import "AppDelegate.h"
#import <AddressBook/ABAddressBook.h>
#import <AddressBookUI/AddressBookUI.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "TextEditViewController.h"

enum {
	ActionSheetAttach,
	ActionSheetMessage,
	ActionSheetProgress,
};

@interface ChatViewController : UIViewController
<UIBubbleTableViewDataSource, UIBubbleTableViewDelegate,
	UIImagePickerControllerDelegate, UITextFieldDelegate,
	UIActionSheetDelegate, UINavigationControllerDelegate,
	AppActivityDelegate, AuthorizationDelegate, 
	FilePickerControllerDelegate, UITextViewDelegate,
	ABPeoplePickerNavigationControllerDelegate,
	CLLocationManagerDelegate, NSBubbleDataDelegate,
	TextEditViewControllerDelegate>
{
}

@property (strong) AppDelegate *appDelegate;

@property (strong) UIBubbleTableView *bubbleTableView;

@property (strong) MPMoviePlayerController *mpc;
//@property (strong) MPMoviePlayerViewController *moviePlayerController;

@property (strong) AVAudioRecorder *audioRecorder;
@property (strong) NSMutableDictionary *recordSettings;

@property SystemSoundID recordStart;

@property Boolean textFieldIsEditable;

@property Boolean stopTransfer;

@property int actionSheetType;

@property (strong) UIProgressView *progressView;
@property (strong) UILabel *progressLabel;
@property int progressTotal;
@property int progressCurrent;

//@property (strong) UIImageView *icon;
@property (strong) UIButton *icon;
@property (strong) NSTimer *timer;
@property (strong) UITextField *textField;
//@property (strong) UITextView *textField;
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
@property (strong) UIBarButtonItem *attach;
@property (strong) UIBarButtonItem *add;
@property (strong) UIBarButtonItem *textFieldItem;
@property (strong) UIBarButtonItem *flexibleSpace;
@property (strong) UIBarButtonItem *cancel;
@property (strong) UIBarButtonItem *label;
@property (strong) UIBarButtonItem *record;
@property (strong) UIButton        *recordButton;

//@property (weak, nonatomic) UITextView *inputField;
@property (strong, nonatomic) UIImageView *inputFieldImageView;

@property (strong) UIImage *peerPhoto;

@property () int position;

@property (strong) CLLocationManager *locationManager;
@property (strong) MKMapView *mapView; 

@end

// vim:ft=objc
