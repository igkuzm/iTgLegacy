#import "TGActionTableView.h"
#include "UIKit/UIKit.h"
#include "Foundation/Foundation.h"

//#import "TGViewController.h"

//#import "TGHacks.h"

@interface TGActionTableView () <UIGestureRecognizerDelegate>
{
    bool _shouldHackHeaderSize;
}

@property (nonatomic) bool ignoreTouches;

@end

@implementation TGActionTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
    }
    return self;
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    if (!editing)
    {
        if (_actionCell != nil)
        {
            if ([_actionCell conformsToProtocol:@protocol(TGActionTableViewCell)])
                [(id<TGActionTableViewCell>)_actionCell dismissEditingControls:true];
            self.actionCell = nil;
            
            _ignoreTouches = false;
        }
    }
    
    [super setEditing:editing animated:animated];
}

- (BOOL)touchesShouldCancelInContentView1:(UIView *)__unused view
{
    return true;
}

- (void)setActionCell:(UITableViewCell *)actionCell
{
    _actionCell = actionCell;
    
    if (actionCell != nil)
        self.scrollEnabled = false;
    else
        self.scrollEnabled = true;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_actionCell != nil)
    {
        UIView *buttonHitTest = [_actionCell hitTest:CGPointMake(point.x - _actionCell.frame.origin.x, point.y - _actionCell.frame.origin.y) withEvent:event];
        if ([buttonHitTest isKindOfClass:[UIButton class]])
            return buttonHitTest;
        else
        {
            if ([_actionCell conformsToProtocol:@protocol(TGActionTableViewCell)])
                [(id<TGActionTableViewCell>)_actionCell dismissEditingControls:true];
            self.actionCell = nil;
            _ignoreTouches = true;
            
            id delegate = self.delegate;
            if ([delegate conformsToProtocol:@protocol(TGActionTableViewDelegate)])
            {
                [(id<TGActionTableViewDelegate>)delegate dismissEditingControls];
            }
        }
        
        return self;
    }
    else if (_ignoreTouches && event.type == UIEventTypeTouches)
        return self;
    
    UIView *result = [super hitTest:point withEvent:event];
    
    if ([result isKindOfClass:[UIButton class]])
    {
        self.delaysContentTouches = false;
    }
    else
    {
        self.delaysContentTouches = true;
    }
    
    return result;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches began: %@", touches);
    if (!_ignoreTouches)
        [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!_ignoreTouches)
        [super touchesMoved:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches cancel: %@", touches);
    if (_ignoreTouches)
        _ignoreTouches = false;
    else
        [super touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    NSLog(@"touches ended: %@", touches);
    
    if (_ignoreTouches)
        _ignoreTouches = false;
    else
    {
        [super touchesEnded:touches withEvent:event];
        
        if (self.delegate != nil && [self.delegate respondsToSelector:@selector(touchedTableBackground)])
            [self.delegate performSelector:@selector(touchedTableBackground)];
    }
}

- (void)enableSwipeToLeftAction
{
    //if (iosMajorVersion() < 7)
    //{
        UISwipeGestureRecognizer *rightSwipeRecognizer = [[UISwipeGestureRecognizer alloc] 
					initWithTarget:self action:@selector(tableViewSwipedRight:)];
        rightSwipeRecognizer.direction =
				 	UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:rightSwipeRecognizer];
        rightSwipeRecognizer.delegate = self;

			 UISwipeGestureRecognizer *leftSwipeRecognizer =
				 [[UISwipeGestureRecognizer alloc] 
				 initWithTarget:self action:@selector(tableViewSwipedLeft:)];
        leftSwipeRecognizer.direction =
				 	UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:leftSwipeRecognizer];
        leftSwipeRecognizer.delegate = self;

    //}
}

- (void)tableViewSwipedRight:(UISwipeGestureRecognizer *)recognizer
{
	//NSLog(@"TABLE VIEW SWIPED");
    //if (recognizer.state == UIGestureRecognizerStateRecognized)
    //{
        //if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft)
        //{
						NSLog(@"TABLE VIEW SWIPED DIRECTION RIGHT");
            id delegate = self.delegate;
            if ([delegate respondsToSelector:@selector(performSwipeToRightAction)])
                [delegate performSwipeToRightAction];
        //}
			//if (recognizer.direction == UISwipeGestureRecognizerDirectionRight)
        //{
						//NSLog(@"TABLE VIEW SWIPED DIRECTION RIGHT");
            //id delegate = self.delegate;
            //if ([delegate respondsToSelector:@selector(performSwipeToRightAction)])
                //[delegate performSwipeToRightAction];
        //}

    //}
}

- (void)tableViewSwipedLeft:(UISwipeGestureRecognizer *)recognizer
{
		NSLog(@"TABLE VIEW SWIPED DIRECTION LEFT");
		id delegate = self.delegate;
		if ([delegate respondsToSelector:@selector(performSwipeToLeftAction)])
				[delegate performSwipeToLeftAction];
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (_shouldHackHeaderSize)
    {
        UIView *tableHeaderView = self.tableHeaderView;
        if (tableHeaderView != nil)
        {
            CGSize size = self.frame.size;
            
            CGRect frame = tableHeaderView.frame;
            if (frame.size.width < size.width)
            {
                frame.size.width = size.width;
                tableHeaderView.frame = frame;
            }
        }
    }
}

- (void)hackHeaderSize
{
    _shouldHackHeaderSize = true;
}

@end
