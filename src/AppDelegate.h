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
-(void)tgLibLoaded;
-(void)authorizedAs:(tl_user_t *)user;
@end

@protocol ReachabilityDelegate <NSObject>
-(void)isOnLine;
-(void)isOffLine;
@end

@protocol AppActivityDelegate <NSObject>
-(void)willResignActive;
@end

enum {
	ALLERT_TYPE_ASK_INPUT,
	ALLERT_TYPE_YES_NO,
};

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) NSString *token;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) UIWindow *window;
@property (strong,nonatomic) NSURL *url;
@property NSInteger allertType;
@property Boolean tokenAlreadyRequested;
@property (strong, nonatomic) void (^askInput_onDone)(NSString *text);
@property (strong, nonatomic) void (^askYesNo_onYes)();
@property (strong) NSOperationQueue *syncData;
@property FILE *log;
@property tg_t *tg;
@property tl_user_t *authorizedUser;
@property long *user_id;
@property (strong) id<AuthorizationDelegate> authorizationDelegate;
@property (strong) Reachability *reach;
@property (strong) id<ReachabilityDelegate> reachabilityDelegate;
@property (strong) id<AppActivityDelegate> appActivityDelegate;
@property (strong) NSString *imagesCache;
@property (strong) NSString *filesCache;
@property (strong) NSString *peerPhotoCache;
@property (strong) NSString *smallPhotoCache;
@property (strong) NSString *thumbDocCache;
@property (strong) id rootViewController;
@property (strong) id dialogsViewController;

@property (strong) NSMutableArray *colorset;

@property Boolean showNotifications;

-(void)showMessage:(NSString *)msg;
-(void)askYesNo:(NSString *)msg onYes:(void (^)())onYes;
-(void)askInput:(NSString *)msg onDone:(void (^)(NSString *text))onDone;
-(void)authorize;
-(void)showNotification:(NSString *)msg;
-(Boolean)isOnLineAndAuthorized;

-(void)setDebug:(Boolean)debug;
-(void)toggleShowNotifications:(Boolean)showNotifications;
@end

// vim:ft=objc
