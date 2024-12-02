//
//  UIBubbleTableViewDelegate.h
//  raspberry
//
//  Created by julian on 5/20/21.
//  Copyright (c) 2021 Trevir. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIBubbleTableView.h"

@protocol UIBubbleTableViewDelegate <NSObject>

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didSelectRow:(int)row;

@end
