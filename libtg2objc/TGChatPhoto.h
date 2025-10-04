#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "../libtg2/tl/macro.h"


@interface TGChatPhoto : NSObject
{
}

@property int chatPhotoType;
@property Boolean has_video;
@property long long photo_id;
@property (strong) NSData *stripped_thumb;
@property int dc_id;

@property (strong) NSManagedObject *managedObject;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGChatPhoto *)newWithTL:(const tl_t *)tl;
+ (TGChatPhoto *)newWithManagedObject:(NSManagedObject *)object;
+ (NSEntityDescription *)entity;
- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context;
@end

// vim:ft=objc
