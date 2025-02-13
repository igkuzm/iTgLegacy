
//  UIBubbleTableView.m
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

#import "UIBubbleTableView.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"
#import "NSBubbleData.h"
#import "UIBubbleHeaderTableViewCell.h"
#import "UIBubbleTypingTableViewCell.h"
#import "../TGActionTableView.h"
#import "../UIImage+Utils/UIImage+Utils.h"

@interface UIBubbleTableView ()

@end

@implementation UIBubbleTableView

@synthesize bubbleDataSource = _bubbleDataSource;
@synthesize snapInterval = _snapInterval;
@synthesize bubbleSection = _bubbleSection;
@synthesize typingBubble = _typingBubble;
@synthesize showAvatars = _showAvatars;

#pragma mark - Initializators

- (void)initializator
{
    // UITableView properties	
		self.backgroundColor = [UIColor clearColor];
		self.separatorStyle = UITableViewCellSeparatorStyleNone;
		assert(self.style == UITableViewStylePlain);
		
		self.delegate = self;
		self.dataSource = self;
		
		// UIBubbleTableView default properties
		
		self.snapInterval = 120;
		self.typingBubble = NSBubbleTypingTypeNobody;

		self.backgroundImageView = [[UIImageView alloc]
			initWithFrame:self.bounds];
		[self addSubview:self.backgroundImageView];

		// tap gesture
		// on tap
		UITapGestureRecognizer *gestureRecognizer = 
			[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap)];
		[self addGestureRecognizer:gestureRecognizer];
}

- (id)init
{
    self = [super init];
    if (self) [self initializator];
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) [self initializator];
    return self;
}

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
    self = [super initWithFrame:frame style:UITableViewStylePlain];
    if (self) [self initializator];
    return self;
}

#if !__has_feature(objc_arc)
- (void)dealloc
{
    [_bubbleSection release];
	_bubbleSection = nil;
	_bubbleDataSource = nil;
    [super dealloc];
}
#endif

#pragma mark - Override

-(void)onTap{
	if (self.bubbleDelegate)
		[self.bubbleDelegate bubbleTableViewOnTap:self];
}

-(void)reloadData{
	[self prepareData];
  [super reloadData];
}

- (void)prepareData
{
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    
    // Cleaning up
		self.bubbleSection = nil;
    
    // Loading new data
    int count = 0;
    self.bubbleSection = [[NSMutableArray alloc] init];
    
    if (self.bubbleDataSource && (count = [self.bubbleDataSource rowsForBubbleTable:self]) > 0)
    {
        NSMutableArray *bubbleData = 
					[[NSMutableArray alloc] initWithCapacity:count];
        
        for (int i = 0; i < count; i++)
        {
            NSObject *object = 
							[self.bubbleDataSource bubbleTableView:self dataForRow:i];
            assert([object isKindOfClass:[NSBubbleData class]]);
            [bubbleData addObject:object];
        }
        
        [bubbleData sortUsingComparator:^NSComparisonResult(id obj1, id obj2)
         {
             NSBubbleData *bubbleData1 = (NSBubbleData *)obj1;
             NSBubbleData *bubbleData2 = (NSBubbleData *)obj2;
             
             return [bubbleData1.date compare:bubbleData2.date];            
         }];
        
        NSDate *last = [NSDate dateWithTimeIntervalSince1970:0];
        NSMutableArray *currentSection = nil;
        
        for (int i = 0; i < count; i++)
        {
            NSBubbleData *data = (NSBubbleData *)[bubbleData objectAtIndex:i];
            
            if ([data.date timeIntervalSinceDate:last] > self.snapInterval)
            {
                currentSection = [[NSMutableArray alloc] init];
                [self.bubbleSection addObject:currentSection];
            }
            
            [currentSection addObject:data];
            last = data.date;
        }
    }
    
    //[self scrollToBottomWithAnimation:YES];
}

- (BOOL) scrollToBottomWithAnimation:(BOOL)animatedBool {
	//Autoscroll to bottom of chat when reloadData called. Returns whether scroll actually occurred.
    
    int sectionCount = [self numberOfSections];
    
    if(sectionCount<=0) return NO;
    
    int rowsInLastSection = [self numberOfRowsInSection:sectionCount-1];
    
    NSIndexPath *scrollIndexPath = [NSIndexPath indexPathForRow:rowsInLastSection-1 inSection:sectionCount-1];
    [self scrollToRowAtIndexPath:scrollIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:animatedBool];
    
    return YES;	
    
    if(self.watchingInRealTime){
        [self scrollBubbleViewToBottomAnimated:false];
    }
}

#pragma mark - UITableViewDelegate implementation

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
		
		// Now typing
	if (indexPath.section >= [self.bubbleSection count])
		{
				return;
		}
		
	// Header
	if (indexPath.row == 0)
	{
			return ;
	}
		
	NSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
		if (self.bubbleDelegate)
			[self.bubbleDelegate bubbleTableView:self didSelectData:data];
}

#pragma mark - UITableViewDataSource implementation

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int result = [self.bubbleSection count];
    if (self.typingBubble != NSBubbleTypingTypeNobody) result++;
    return result;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // This is for now typing bubble
	if (section >= [self.bubbleSection count]) return 1;
    
  return [[self.bubbleSection objectAtIndex:section] count] + 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Now typing
	if (indexPath.section >= [self.bubbleSection count])
	{
			return MAX([UIBubbleTypingTableViewCell height], self.showAvatars ? 52 : 0);
	}
	
	// Header
	if (indexPath.row == 0)
	{
			return [UIBubbleHeaderTableViewCell height];
	}
	
	NSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
	return MAX(data.insets.top + data.view.frame.size.height + data.insets.bottom, self.showAvatars ? 52 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Now typing
	if (indexPath.section >= [self.bubbleSection count])
    {
        static NSString *cellId = @"tblBubbleTypingCell";
        UIBubbleTypingTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
        
        if (cell == nil) cell = [[UIBubbleTypingTableViewCell alloc] init];

        cell.type = self.typingBubble;
        cell.showAvatar = self.showAvatars;
        
        return cell;
    }

   // Header with date and time
  if (indexPath.row == 0)
    {
        static NSString *cellId = @"tblBubbleHeaderCell";
        UIBubbleHeaderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
        NSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:0];
        
        if (cell == nil) cell = [[UIBubbleHeaderTableViewCell alloc] init];

        cell.date = data.date;
       
        return cell;
    }
    
		// Standard bubble    
    static NSString *cellId = @"tblBubbleCell";
    UIBubbleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    NSBubbleData *data = [[self.bubbleSection objectAtIndex:indexPath.section] objectAtIndex:indexPath.row - 1];
    
    if (cell == nil) cell = [[UIBubbleTableViewCell alloc] init];
    
    cell.data = data;
    cell.showAvatar = self.showAvatars;

		// swipe gesture
		UISwipeGestureRecognizer *swipeToLeftRecognizer = 
			[[UISwipeGestureRecognizer alloc] 
			initWithTarget:self action:@selector(swipeToLeft:)];
		swipeToLeftRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
		[cell addGestureRecognizer:swipeToLeftRecognizer];
		
		//if (!data.message.mine)
			//cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

		//if ([cell.data.view isKindOfClass:[UITextView class]]){
			//UITextView *tw = (UITextView *)cell.data.view;
			//CGRect frame = tw.frame; 
			//frame.size.height = tw.contentSize.height + 30;
			//tw.frame = frame;
		//}
    
    return cell;
}

-(void)swipeToLeft:(UISwipeGestureRecognizer *)gestureRecognizer{
	NSLog(@"SWIPED LEFT");
	if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
	{
		UIBubbleTableViewCell *cell = 
			(UIBubbleTableViewCell *)gestureRecognizer.view;
		if (self.bubbleDelegate)
			[self.bubbleDelegate performSwipeToLeftAction:cell.data];
	}
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat height = scrollView.frame.size.height;
    
    CGFloat contentYoffset = scrollView.contentOffset.y;
    
    CGFloat distanceFromBottom = scrollView.contentSize.height - contentYoffset;
    
    self.watchingInRealTime = distanceFromBottom - 20 <= height;

		if (self.bubbleDelegate)
			[self.bubbleDelegate bubbleTableView:self didScroll:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	if (self.bubbleDelegate)
		[self.bubbleDelegate bubbleTableViewDidBeginDragging:self];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	float bottomEdge = 
		scrollView.contentOffset.y + scrollView.frame.size.height;
	
	if (bottomEdge >= scrollView.contentSize.height) {
		// BOTTOM
		//NSInteger lastSectionIdx = [self numberOfSections] - 1;
		//if (lastSectionIdx >= [self.bubbleSection count])
			//return;
		
		//NSArray *section = 
			//[self.bubbleSection objectAtIndex:lastSectionIdx];
		//NSBubbleData *data = 
			//[section objectAtIndex:section.count - 1];
		
		//if (data)
		if (self.bubbleDelegate)
			[self.bubbleDelegate 
				bubbleTableView:self didEndDecelerationgToBottom:YES];

	} else if (scrollView.contentOffset.y == 0){
			if (self.bubbleDelegate)
				[self.bubbleDelegate 
					bubbleTableView:self didEndDecelerationgToTop:YES];
	}
	
	//NSIndexPath *indexPath = 
			//[[self indexPathsForVisibleRows]objectAtIndex:0];

	//// Now typing
	//if (indexPath.section >= [self.bubbleSection count])
	//{
			//return;
	//}
	
	//// Header
	//if (indexPath.row == 0)
	//{
		//NSBubbleData *data = 
		//[[self.bubbleSection objectAtIndex:indexPath.section] 
												 //objectAtIndex:indexPath.row];

		//if (data)
			//if (self.bubbleDelegate)
				//[self.bubbleDelegate 
					//bubbleTableView:self didEndDecelerationgTo:data];

		//return;
	//}
	
	//NSBubbleData *data = 
		//[[self.bubbleSection objectAtIndex:indexPath.section] 
												 //objectAtIndex:indexPath.row - 1];

	//if (data)
		//if (self.bubbleDelegate)
			//[self.bubbleDelegate 
				//bubbleTableView:self didEndDecelerationgTo:data];

	//return;
}

- (void)tableView:(UITableView *)tableView 
	accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath 
{
	
	// Now typing
	if (indexPath.section >= [self.bubbleSection count])
	{
			return;
	}
	
	// Header
	if (indexPath.row == 0)
	{
		return;
	}
	
	NSBubbleData *data = 
		[[self.bubbleSection objectAtIndex:indexPath.section] 
												 objectAtIndex:indexPath.row - 1];

	if (self.bubbleDelegate)
		[self.bubbleDelegate 
			bubbleTableView:self accessoryButtonTappedForData:data];
}

#pragma mark - Public interface

- (void) scrollBubbleViewToBottomAnimated:(BOOL)animated
{
    NSInteger lastSectionIdx = [self numberOfSections] - 1;
    
    if (lastSectionIdx >= 0)
    {
    	[self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:([self numberOfRowsInSection:lastSectionIdx] - 1) inSection:lastSectionIdx] atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }
}

- (void) scrollBubbleViewToData:(NSBubbleData *)data 
											 animated:(BOOL)animated
{
	NSInteger section = 0;
	for (NSArray *s in self.bubbleSection){
		NSInteger row = 0;
		for (NSBubbleData *d in s){
			if (row == 0) // skip header
				continue;
			if (d.message.id == data.message.id){
				[self scrollToRowAtIndexPath:
					[NSIndexPath indexPathForRow:row inSection:section] 
					atScrollPosition:UITableViewScrollPositionTop 
					animated:animated];

				return;
			}
			
			row++;
		}

		section++;
	}

}

//- (void) scrollViewWillEndDragging:(UIScrollView *) scrollView 
                      //withVelocity:(CGPoint) velocity 
               //targetContentOffset:(CGPoint *) targetContentOffset
//{
	//if (self.bubbleDelegate && [self.bubbleDelegate respondsToSelector:@selector(bubbleTableViewWillEndDragging:withVelocity:targetContentOffset::)])
		//[self.bubbleDelegate bubbleTableViewWillEndDragging:self withVelocity:velocity targetContentOffset:targetContentOffset];
//}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	//if (section == 0)
		//return @"top messages";
	return @"";
}

@end
