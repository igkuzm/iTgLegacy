#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"

@interface TGObject : NSObject
{
}

@property int objectType;
@property (strong) NSManagedObject *managedObject;

- (void)updateWithTL:(const tl_t *)tl;
+ (id)newWithTL:(const tl_t *)tl;
+ (id)newWithManagedObject:(NSManagedObject *)object;
- (NSManagedObject *)
	newManagedObjectInContext:(NSManagedObjectContext *)context;
	
@end

// vim:ft=objc
