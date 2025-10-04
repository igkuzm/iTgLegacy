#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "TGChatPhoto.h"

@interface TGFolder : NSObject
{
}

@property Boolean autofill_new_broadcasts;
@property Boolean autofill_public_groups;
@property Boolean autofill_new_correspondents;
@property int id;
@property (strong) NSString *title;
@property (strong) TGChatPhoto *photo;

@property (strong) NSManagedObject *managedObject;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGFolder *)newWithTL:(const tl_t *)tl;
+ (TGFolder *)newWithManagedObject:(NSManagedObject *)object;
- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription *)entityWithTGphoto:(NSEntityDescription *)tgphoto;
@end

// vim:ft=objc
