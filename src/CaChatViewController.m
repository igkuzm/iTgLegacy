//
//  CaChatViewController.m
//  Calcium
//
//  Created by bag.xml on 18/02/24.
//  Copyright (c) 2024 Mali 357. All rights reserved.
//

#import "CaChatViewController.h"

@interface CaChatViewController ()
{
    NSMutableArray *bubbleData;
    UIImagePickerController *imagePicker;
}
@end

@implementation CaChatViewController
@synthesize currentImage;

- (void)viewWillAppear:(BOOL)animated {
    [UINavigationBar.appearance setBackgroundImage:nil forBarMetrics:UIBarMetricsDefault];
    //[UINavigationBar.appearance setTintColor:[UIColor colorWithRed:200/255.0 green:200/255.0 blue:200/255.0 alpha:1.0]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Definition of variables, ones which are used on the bottom.
    BOOL firstLaunchCheck = [[NSUserDefaults standardUserDefaults] boolForKey:@"firstLaunch"];
    //end
    
    //Sidebar setup block
    self.slideMenuController.bouncing = YES;
    self.slideMenuController.gestureSupport = APLSlideMenuGestureSupportDrag;
    self.slideMenuController.separatorColor = [UIColor grayColor];
    //Setup block end
    
    //Table view options
    
    //temp population
    self.bubbleTableView.bubbleDataSource = self;
    self.bubbleTableView.watchingInRealTime = YES;
    self.bubbleTableView.snapInterval = 2800;
    self.bubbleDataArray = [NSMutableArray array];
    self.bubbleTableView.showAvatars = [[NSUserDefaults standardUserDefaults] boolForKey:@"showPFP"];
    [self.bubbleTableView reloadData];
    
    if(VERSION_MIN(@"7.0")) {
        self.bubbleTableView.backgroundColor = [UIColor whiteColor];
    }
    //table view options OFF
    
    //Image picker stuff
    imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    #if !(TARGET_IPHONE_SIMULATOR)
    // We don't have cameras on simulators xd
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    #else
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    #endif
    currentImage = nil;
    //End
    
    //RFactory delegate
    self.requestFactory = [[CaRequestFactory alloc] init];
    self.requestFactory.delegate = self;
    //RFD end
    //Delegate decs
    self.inputField.delegate = self;
    //Delegate decs end
    
    //event notification block BEGIN
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    //event notification block END
    
    //OS Specific settings END
    
    //first launch block, performs a segue if the application has been launched for the first ever time.
    if (firstLaunchCheck == NO) {
        if(VERSION_MIN(@"5.0")){
            [self performSegueWithIdentifier:@"to Welcomepage-iOS6" sender:self];
        } else if(VERSION_MIN(@"7.0")) {
            [self performSegueWithIdentifier:@"to Welcomepage-iOS7" sender:self];
        }
    }
    //first launch block END
    
    //refresh control
    dispatch_async(dispatch_get_main_queue(), ^{
        if(VERSION_MIN(@"6.0") && !self.reloadControl){

            self.reloadControl = UIRefreshControl.new;
            
            self.reloadControl.attributedTitle = [[NSAttributedString alloc] initWithString:@"More"];
            
            [self.bubbleTableView addSubview:self.reloadControl];
            
            [self.reloadControl addTarget:self action:@selector(interactiveView) forControlEvents:UIControlEventValueChanged];
        }
    });
}

//Text field properties BEGIN
- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
    return YES;
}

-(void) textViewDidChange:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
}

-(void) textViewDidEndEditing:(UITextView *)textView {
    self.inputFieldPlaceholder.hidden = self.inputField.text.length != 0;
}
//Text field properties END

//Button actions
- (IBAction)modeSwitch:(id)sender {
    UIActionSheet *messageActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select an option" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Take Picture", @"Select Picture", @"Switch Modes", nil];
    
    [messageActionSheet setTag:1];
    [messageActionSheet setDelegate:self];
    [messageActionSheet showInView:self.view];
    //actionsheet
}

- (IBAction)sendButton:(id)sender {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"--BUTTON ACTION-- Send button tapped");
        BOOL imageMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"imageGenerationModeEnabled"];
        if(imageMode == YES) {
            NSLog(@"imageMode == YES");
            NSLog(@"Image generation mode is enabled, therefore the function for image generation is executed.");
            dispatch_async(dispatch_get_main_queue(), ^{
                [self imageGenRequest];
            });
            //kaboom
        } else if(imageMode == NO) {
            NSLog(@"imageMode == NO");
            NSLog(@"Chat mode is enabled, therefore the function for image generation is executed.");
            
            //this right here is purely a cosmetic measure to hide how the message bubble's dimensions break if the character length is less than 3.
            //to prevent that just "force" the user to assign themselves a nickname
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *prepopulatedText = self.inputField.text;
                NSString *nickname = [[NSUserDefaults standardUserDefaults] objectForKey:@"nickname"];
                if(nickname.length == 0) {
                    NSBubbleData *userBubbleData = [NSBubbleData dataWithText:prepopulatedText date:[NSDate date] type:BubbleTypeMine];
                    [self.bubbleDataArray addObject:userBubbleData];
                } else {
                    NSBubbleData *userBubbleData = [NSBubbleData dataWithText:[NSString stringWithFormat:@"%@:\n%@", nickname, prepopulatedText] date:[NSDate date] type:BubbleTypeMine];
                    [self.bubbleDataArray addObject:userBubbleData];
                }
                [self.bubbleTableView reloadData];
                [self chatRequest];
            });
        }
        //i dont wanna repeat myself twice, but what this does is that it updated the bubbletable view pos to that of what the view looks like with the keyboard expanded
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.viewingPresentTime)
                [self.bubbleTableView setContentOffset:CGPointMake(0, self.bubbleTableView.contentSize.height - self.bubbleTableView.frame.size.height) animated:YES];
        });
    });
}

- (IBAction)exposeSidebar:(id)sender {
    //Sidebar thingy
    NSLog(@"--BUTTON ACTION-- User pressed left hambuger button, Exposing sidebar now!");
    [self.slideMenuController showLeftMenu:YES];
}

//end

//Button action block end

//Request-firing Blocks

- (void)chatRequest {
    NSLog(@"Chat request is being prepared");
    NSString *messagePayload = self.inputField.text;
    
    //one prerequisite
    self.inputFieldImageView.image = nil;
    
    if (currentImage != nil) {
        [self.requestFactory startTextRequest:messagePayload withBase64Image:currentImage];
        currentImage = nil;
    } else {
        [self.requestFactory startTextRequest:messagePayload];
    }
    self.inputField.text = @"";
}


- (void)imageGenRequest {
    NSLog(@"Image generation request is being prepared");
    NSString *messageContent = self.inputField.text;
    
    [self.requestFactory startImageGenerationRequest:messageContent];
    self.inputField.text = @"";
}

- (void)didReceiveResponseData:(NSString *)data {
    //Spawning bubble
    NSString *nickname = [[NSUserDefaults standardUserDefaults] objectForKey:@"aiNick"];
    if(nickname.length == 0) {
        NSBubbleData *assistantBubbleData = [NSBubbleData dataWithText:data date:[NSDate date] type:BubbleTypeSomeoneElse];
        [self.bubbleDataArray addObject:assistantBubbleData];
    } else {
        NSBubbleData *assistantBubbleData = [NSBubbleData dataWithText:[NSString stringWithFormat:@"%@:\n%@", nickname, data] date:[NSDate date] type:BubbleTypeSomeoneElse];
        [self.bubbleDataArray addObject:assistantBubbleData];
    }
    [self.bubbleTableView reloadData];
    
}

//Temp request classes END

//Keyboard event block begin
- (void)keyboardWillShow:(NSNotification *)notification {

	int keyboardHeight = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.bubbleTableView setHeight:self.view.height - keyboardHeight - self.toolbar.height];
	[self.toolbar setY:self.view.height - keyboardHeight - self.toolbar.height];
	[UIView commitAnimations];
	
	
	if(self.viewingPresentTime)
		[self.bubbleTableView setContentOffset:CGPointMake(0, self.bubbleTableView.contentSize.height - self.bubbleTableView.frame.size.height) animated:NO];
}

- (void)keyboardWillHide:(NSNotification *)notification {
	
	float keyboardAnimationDuration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
	int keyboardAnimationCurve = [[notification.userInfo objectForKey: UIKeyboardAnimationCurveUserInfoKey] integerValue];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:keyboardAnimationDuration];
	[UIView setAnimationCurve:keyboardAnimationCurve];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[self.bubbleTableView setHeight:self.view.height - self.toolbar.height];
	[self.toolbar setY:self.view.height - self.toolbar.height];
	[UIView commitAnimations];
}
//Keyboard event block end

//Bubble table view attributes BEGIN
- (NSInteger)rowsForBubbleTable:(UIBubbleTableView *)tableView {
    return self.bubbleDataArray.count;
}

- (NSBubbleData *)bubbleTableView:(UIBubbleTableView *)tableView dataForRow:(NSInteger)row {
    return [self.bubbleDataArray objectAtIndex:row];
}

// Implement optional delegate method

-(void)bubbleTableView:(UIBubbleTableView *)bubbleTableView didSelectRow:(int)row {
    NSLog(@"selected");
}

//END
//Miscellaneous functions that get called from other block components BEGIN
- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    currentImage = [UIImagePNGRepresentation([UIImage imageWithImage:[info objectForKey:UIImagePickerControllerOriginalImage] scaledToSize:CGSizeMake(640, 480)]) base64EncodedString];
    [self dismissViewControllerAnimated:YES completion:nil];
    CGRect aRect = CGRectMake(156, 2, 24, 24);
    UIImage *img = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    //check if the user was in image-generation mode and change back to chat mode:
    BOOL imageMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"imageGenerationModeEnabled"];
    
    if(imageMode == YES) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"imageGenerationModeEnabled"];
        [SVProgressHUD showSuccessWithStatus:@"Switched to Chat Mode"];
        self.navigationItem.title = @"Chat";
    }
    if (self.inputFieldImageView == nil) {
        self.inputFieldImageView = [[UIImageView alloc] initWithImage:img];
    } else {
        self.inputFieldImageView.image = img;
    }
    [self.inputFieldImageView setFrame:aRect];
    
    [self.inputField addSubview:self.inputFieldImageView];
    NSBubbleData *imgBubbleData = [NSBubbleData dataWithImage:img date:[NSDate date] type:BubbleTypeMine];
    [self.bubbleDataArray addObject:imgBubbleData];
}

//actionsheet and alertview refersheet index functions
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet.tag == 1) {
        if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            [self presentViewController:imagePicker animated:YES completion:nil];
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex] + 1) {
            //imagepicker declaration
            UIImagePickerController *picker = UIImagePickerController.new;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            
            [picker setDelegate:self];
            [picker viewWillAppear:YES];
            //spawn
            [self presentViewController:picker animated:YES completion:nil];
            [picker viewWillAppear:YES];
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex] + 2) {
            
            //mode switch
            BOOL imageMode = [[NSUserDefaults standardUserDefaults] boolForKey:@"imageGenerationModeEnabled"];
            BOOL clearAlways = [[NSUserDefaults standardUserDefaults] boolForKey:@"alwaysClear"];
            if (imageMode == YES) {
                UIImage *correspondingMode = [UIImage imageNamed:@"PictureModeGlyph"];
                NSLog(@"--BUTTON ACTION-- User switched to chat mode from gen mode");
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"imageGenerationModeEnabled"];
                [SVProgressHUD showSuccessWithStatus:@"Switched to Chat Mode"];
                self.navigationItem.title = @"Chat";
                
                //Clears history
                if(clearAlways == YES) {
                    NSLog(@"Chat history has been cleared.");
                    [self.bubbleDataArray removeAllObjects];
                    [self.bubbleTableView reloadData];
                }
                
                //Input field
                self.inputFieldPlaceholder.text = @"Type something in...";
                self.inputField.text = @"";
                [self.modeButton setImage:correspondingMode];
                
            } else if (imageMode == NO) {
                UIImage *correspondingMode = [UIImage imageNamed:@"hamburger"];
                NSLog(@"--BUTTON ACTION-- User switched to gen from chat mode");
                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"imageGenerationModeEnabled"];
                [SVProgressHUD showSuccessWithStatus:@"Switched to Image Generation Mode"];
                self.navigationItem.title = @"Generate Image";
                
                //If someone has an image, nil it
                self.inputFieldImageView.image = nil;
                //Clears history
                if(clearAlways == YES) {
                    NSLog(@"Chat history has been cleared.");
                    [self.bubbleDataArray removeAllObjects];
                    [self.bubbleTableView reloadData];
                }
                
                //input field dishery
                self.inputFieldPlaceholder.text = @"Generate something...";
                self.inputField.text = @"";
                [self.modeButton setImage:correspondingMode];
            }
        }
    } else if(actionSheet.tag == 2) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Clear Conversation" message:@"Are you sure you want to clear the entire conversation?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Clear", nil];
            [alertView setTag:3];
            [alertView show];
        } else if (buttonIndex == actionSheet.firstOtherButtonIndex) {
            NSLog(@"share");
            //PURE TEST
            NSArray *itemsToShare = @[self.inputField.text];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
            [self presentViewController:activityVC animated:YES completion:nil];
            [activityVC viewWillAppear:YES];
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex] + 1) {
            [SVProgressHUD showErrorWithStatus:@"Save failed"];
        } else if (buttonIndex == [actionSheet firstOtherButtonIndex] + 2) {
            //
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Name Conversation" message:@"Type a name into the input field to name your conversation" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"OK", nil];
            //input field
            alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
            [alertView setTag:2];
            [alertView show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 2) {
        if (buttonIndex == alertView.firstOtherButtonIndex) {
            NSString *enteredText = [alertView textFieldAtIndex:0].text;
            self.navigationItem.title = enteredText;
        }
    } else if(alertView.tag == 3) {
        if(buttonIndex == alertView.firstOtherButtonIndex) {
            [self setTyping:0];
            [self.bubbleDataArray removeAllObjects];
            [self.bubbleTableView reloadData];
        }
    }
}

//Status indicators

- (void)setTyping:(BOOL)typing {
    self.bubbleTableView.typingBubble = typing ? 2 : 0;
}
-(void)scrollChatToBottom {
    [self.bubbleTableView scrollBubbleViewToBottomAnimated:false];
}

- (void)interactiveView {
    [self.inputField resignFirstResponder];
    UIActionSheet *messageActionSheet = [[UIActionSheet alloc] initWithTitle:@"What do you want to do" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Clear conversation" otherButtonTitles:@"Share", @"Save Conversation", @"Name", nil];
    [messageActionSheet setTag:2];
    [messageActionSheet setDelegate:self];
    [self.reloadControl endRefreshing];
    [messageActionSheet showInView:self.view];
}
//END

@end
