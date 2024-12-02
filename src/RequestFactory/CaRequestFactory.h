//
//  CaRequestFactory.h
//  Calcium
//
//  Created by bag.xml on 06/04/24.
//  Copyright (c) 2024 Mali 357. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BubbleView/UIBubbleTableView.h"
#import "SVProgressHUD/SVProgressHUD.h"

#define VERSION_MIN(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@protocol CaRequestFactoryDelegate <NSObject>
- (void)didReceiveResponseData:(NSString *)data;
- (void)setTyping:(BOOL)typing;
@end

@interface CaRequestFactory : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>
@property (nonatomic, strong) id<CaRequestFactoryDelegate> delegate;

//Data
@property (nonatomic, strong) NSMutableData *apiaryResponseData;

- (void)startTextRequest:(NSString *)messagePayload withBase64Image:(NSString *)base64Image;
- (void)startTextRequest:(NSString *)messagePayload;
- (void)startImageGenerationRequest:(NSString *)messageContent;
@end

