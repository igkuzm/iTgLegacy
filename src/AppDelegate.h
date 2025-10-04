/**
 * File              : AppDelegate.h
 * Author            : Igor V. Sementsov <ig.kuzm@gmail.com>
 * Date              : 09.08.2023
 * Last Modified Date: 13.09.2023
 * Last Modified By  : Igor V. Sementsov <ig.kuzm@gmail.com>
 */

#import <UIKit/UIKit.h>
#include "../libtg2/libtg.h"
#import "../libtg2objc/TGPersistentStoreCoordinator.h"

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

typedef NS_ENUM(NSInteger, ALLERT_TYPE) {
	ALLERT_TYPE_ASK_INPUT,
	ALLERT_TYPE_YES_NO,
};

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong) TGPersistentStoreCoordinator *coordinator;
@property (strong, nonatomic) NSString *cacheDir;
@property FILE *log;
@property ALLERT_TYPE allertType;
@property (strong, nonatomic) void (^askInput_onDone)(NSString *text);
@property (strong, nonatomic) void (^askYesNo_onYes)();

//@property (strong, nonatomic) NSString *token;
//@property (strong, nonatomic) NSTimer *timer;
//@property (strong, nonatomic) UIWindow *window;
//@property (strong,nonatomic) NSURL *url;
//@property Boolean tokenAlreadyRequested;
//@property (strong) NSOperationQueue *syncData;
//@property tg_t *tg;
//@property tl_user_t *authorizedUser;
//@property long *user_id;
//@property (strong) id<AuthorizationDelegate> authorizationDelegate;
//@property (strong) Reachability *reach;
//@property (strong) id<ReachabilityDelegate> reachabilityDelegate;
//@property (strong) id<AppActivityDelegate> appActivityDelegate;
//@property (strong) NSString *imagesCache;
//@property (strong) NSString *filesCache;
//@property (strong) NSString *peerPhotoCache;
//@property (strong) NSString *smallPhotoCache;
//@property (strong) NSString *thumbDocCache;
//@property (strong) id rootViewController;
//@property (strong) id dialogsViewController;

//@property (strong) NSArray *colorset;
//@property (strong) NSMutableArray *unread;
//-(void)removeUnredId:(uint64_t)fromId;

//@property Boolean showNotifications;

-(void)showMessage:(NSString *)msg;
-(void)askYesNo:(NSString *)msg onYes:(void (^)())onYes;
-(void)askInput:(NSString *)msg onDone:(void (^)(NSString *text))onDone;
-(void)authorize;
-(void)showNotification:(NSString *)msg;
-(Boolean)isOnLineAndAuthorized;

-(void)setDebug:(Boolean)debug;
-(void)toggleShowNotifications:(Boolean)showNotifications;

- (void)setupPlayAndRecordAudioSession;
- (void)setupSoloAmbientAudioSession;
@end

// vim:ft=objc
