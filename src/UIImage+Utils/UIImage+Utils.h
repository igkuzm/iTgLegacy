//
//  UIImage+Utils.h
//  Uwabbit
//
//  Created by electimon on 5/3/24.
//  Copyright (c) 2024 Yuzu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Utils)
+ (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
@end
