/**
 * File              : QuickLookController.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 28.07.2021
 * Last Modified Date: 28.07.2021
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */
#import <UIKit/UIKit.h>
#import <QuickLook/QuickLook.h>

@interface QuickLookController : QLPreviewController <QLPreviewControllerDataSource, QLPreviewControllerDelegate>
@property (strong,nonatomic) NSArray *data;

-(QuickLookController *)initQLPreviewControllerWithData:(NSArray *)data;
@end
