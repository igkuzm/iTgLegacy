//
//  UIBubbleTableView.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#include "UIKit/UIKit.h"
#import <UIKit/UIKit.h>

#import "UIBubbleTableViewDataSource.h"
#import "UIBubbleTableViewCell.h"
#import "UIBubbleTableViewDelegate.h"

typedef enum _NSBubbleTypingType
{
    NSBubbleTypingTypeNobody = 0,
    NSBubbleTypingTypeMe = 1,
    NSBubbleTypingTypeSomebody = 2
} NSBubbleTypingType;

@interface UIBubbleTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, retain) NSMutableArray *bubbleSection;

@property (nonatomic, assign) id<UIBubbleTableViewDataSource> bubbleDataSource;
@property (nonatomic) NSTimeInterval snapInterval;
@property (nonatomic) NSBubbleTypingType typingBubble;
@property (nonatomic) BOOL showAvatars;
@property (nonatomic) BOOL watchingInRealTime;
@property (nonatomic, assign) id<UIBubbleTableViewDelegate> bubbleDelegate;
@property (strong, nonatomic) UIImageView *backgroundImageView;

- (void)prepareData;
- (void) scrollBubbleViewToBottomAnimated:(BOOL)animated;
- (BOOL) scrollToBottomWithAnimation:(BOOL)animatedBool;

- (void)scrollBubbleViewToData:(NSBubbleData *)data 
											 animated:(BOOL)animated;

@end
