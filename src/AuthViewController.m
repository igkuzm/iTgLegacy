#import "AuthViewController.h"
#include "CoreGraphics/CoreGraphics.h"
#include "UIKit/UIKit.h"
@implementation AuthViewController
- (void)viewDidLoad {
	[super viewDidLoad];
	CGRect frame = 
		CGRectMake(10, 10, 100, 100);
	UIButton *start = [[UIButton alloc]initWithFrame:frame];
	[start setTitle:@"Start Messaging" 
				 forState:UIControlStateNormal];
	[start addTarget:self action:@selector(onStart:) 
				forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:start];
}
-(void)onStart:(UIButton *)sender {

}
@end
// vim:ft=objc
