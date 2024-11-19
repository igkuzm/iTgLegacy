/**
 * File              : TextEditViewController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 04.05.2021
 * Last Modified Date: 31.08.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import <UIKit/UIKit.h>

@protocol TextEditViewControllerDelegate <NSObject>
@optional
-(void)textEditViewControllerSaveText:(NSString *)text;
@end

//@interface TextEditViewController : UITableViewController <UITextViewDelegate>
@interface TextEditViewController : UIViewController <UITextViewDelegate>

@property (strong,nonatomic) id <TextEditViewControllerDelegate> delegate;
@property (strong,nonatomic) NSString *text;
@property (strong, nonatomic) UITextView *textView;
@property (strong, nonatomic) UIScrollView *scrollView;

@end

// vim:ft=objc
