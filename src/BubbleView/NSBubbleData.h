//
//  NSBubbleData.h
//
//  Created by Alex Barinov
//  Project home page: http://alexbarinov.github.com/UIBubbleTableView/
//
//  This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/
//

@protocol NSBubbleDataDelegate
-(void)bubbleDataDidTapImage:(id)bubbleData;
-(void)bubbleDataDidTapText:(id)bubbleData;
@end

#include "Foundation/Foundation.h"
#include "UIKit/UIKit.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "../TGMessage.h"
#import "MediaPlayer/MediaPlayer.h"

typedef enum _NSBubbleType
{
    BubbleTypeMine = 0,
    BubbleTypeSomeoneElse = 1
} NSBubbleType;


@interface NSBubbleData : NSObject

@property (readonly, nonatomic, strong) NSDate *date;
@property (readonly, nonatomic) NSBubbleType type;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UILabel *nameLabel;
@property (nonatomic, strong) UIColor *nameColor;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *sizeLabel;
@property (nonatomic, strong) UILabel *text;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *videoPlayButton;
@property (strong) UIActivityIndicatorView *spinner;
@property (readonly, nonatomic) UIEdgeInsets insets;
@property (nonatomic, strong) UIImage *avatar;
@property NSInteger index;
@property Boolean isImage;
@property (strong) TGMessage *message;
@property float width;
@property (strong) MPMoviePlayerController *mpc;
@property (weak) id <NSBubbleDataDelegate> delegate;

@property UIEdgeInsets textInsetsMine;
@property UIEdgeInsets textInsetsSomeone;


@property Boolean showPlayButton;

- (id)initWithImage:(UIImage *)image date:(NSDate *)date type:(NSBubbleType)type text:(NSString *)text;

- (id)initWithView:(UIView *)view date:(NSDate *)date type:(NSBubbleType)type insets:(UIEdgeInsets)insets; 

- (id)initWithServiceMessage:(NSString *)text date:(NSDate *)date;

@end

// vim:ft=objc
