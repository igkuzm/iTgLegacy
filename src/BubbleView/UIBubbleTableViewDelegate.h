//
//  UIBubbleTableViewDelegate.h
//  raspberry
//
//  Created by julian on 5/20/21.
//  Copyright (c) 2021 Trevir. All rights reserved.
//

#include "NSBubbleData.h"
#import <Foundation/Foundation.h>
#import "UIBubbleTableView.h"

@protocol UIBubbleTableViewDelegate <NSObject>

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didSelectData:(NSBubbleData *)data;

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didScroll:(UIScrollView *)scrollView;

- (void)bubbleTableViewDidBeginDragging:(UIBubbleTableView *)bubbleTableView;

- (void)bubbleTableViewOnTap:(UIBubbleTableView *)bubbleTableView;

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didEndDecelerationgToTop:(Boolean)top;

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
didEndDecelerationgToBottom:(Boolean)bottom;

- (void)bubbleTableView:(UIBubbleTableView *)bubbleTableView
accessoryButtonTappedForData:(NSBubbleData *)data;

- (void)performSwipeToLeftAction:(NSBubbleData *)data;
- (void)performSwipeToRightAction:(NSBubbleData *)data;

- (void) bubbleTableViewWillEndDragging:(UIBubbleTableView *)bubbleTableView 
                      withVelocity:(CGPoint) velocity 
               targetContentOffset:(CGPoint *) targetContentOffset;


@end
