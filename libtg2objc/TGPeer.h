#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"

@interface TGPeer : NSObject
{
}

@property int peerType;
@property int id;

@property (strong) NSManagedObject *managedObject;

- (void)updateWithTL:(const tl_t *)tl;
+ (TGPeer *)newWithTL:(const tl_t *)tl;
+ (TGPeer *)newWithManagedObject:(NSManagedObject *)object;
- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context;
+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
