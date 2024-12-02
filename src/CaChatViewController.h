//
//  CaChatViewController.h
//  Calcium
//
//  Created by bag.xml on 18/02/24.
//  Copyright (c) 2024 Mali 357. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "APLSlideMenu/APLSlideMenuViewController.h"
#import "BubbleView/NSBubbleData.h"
#import "SVProgressHUD/SVProgressHUD.h"
#import "BubbleView//UIBubbleTableView.h"
#import "TRMalleableFrameView/TRMalleableFrameView.h"
#import "RequestFactory/CaRequestFactory.h"
#import "UIImage+Utils/UIImage+Utils.h"
#import "Base64/Base64.h"

#define VERSION_MIN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@interface CaChatViewController : UIViewController <UIBubbleTableViewDataSource, UIBubbleTableViewDelegate, UIActionSheetDelegate, CaRequestFactoryDelegate, UIImagePickerControllerDelegate>

// Main view
@property (weak, nonatomic) IBOutlet UIBubbleTableView *bubbleTableView;
// End of main view

// Toolbar and its children, block begin
// Left button
@property (weak, nonatomic) IBOutlet UIBarButtonItem *modeButton;

// Right button
@property (weak, nonatomic) IBOutlet UIBarButtonItem *sendButton;

// Pill
@property (weak, nonatomic) IBOutlet UITextView *inputField;
@property (weak, nonatomic) IBOutlet UILabel *inputFieldPlaceholder;
@property (weak, nonatomic) IBOutlet UIImageView *insetShadow;
@property (weak, nonatomic) IBOutlet UIView *pill;
@property (strong, nonatomic) UIImageView *inputFieldImageView;

// Main toolbar
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
// End of toolbar block

// Miscellaneous declarations
@property bool viewingPresentTime;
@property (strong, nonatomic) NSString *currentImage;
@property (nonatomic, strong) NSMutableArray *bubbleDataArray;
// End of miscellaneous declarations

// Request Factory
@property (nonatomic, strong) CaRequestFactory *requestFactory;
@property (nonatomic, strong) NSMutableData *apiaryResponseData;

// Refresh control
@property UIRefreshControl *reloadControl;

@end
