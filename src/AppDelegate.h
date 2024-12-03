/**
 * File              : AppDelegate.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#include "Foundation/Foundation.h"
#import <UIKit/UIKit.h>
#include <stdio.h>
#import "Reachability.h"
#include "../libtg/libtg.h"

@protocol AuthorizationDelegate <NSObject>
-(void)authorizedAs:(tl_user_t *)user;
@end

@protocol ReachabilityDelegate <NSObject>
-(void)isOnLine;
-(void)isOffLine;
@end

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) NSURL *url;
@property (strong, nonatomic) void (^askInput_onDone)(NSString *text);
@property tg_t *tg;
@property tl_user_t *authorizedUser;
@property long *user_id;
@property (strong) id<AuthorizationDelegate> authorizationDelegate;
@property (strong) Reachability *reach;
@property (strong) id<ReachabilityDelegate> reachabilityDelegate;
@property (strong) NSString *log;

-(void)showMessage:(NSString *)msg;
-(void)askInput:(NSString *)msg onDone:(void (^)(NSString *text))onDone;
-(void)authorize;

@end

// vim:ft=objc
