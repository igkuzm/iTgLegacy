#import <CoreData/CoreData.h>
#include "TGPersistentStoreCoordinator.h"

@interface TGManagedObjectContext : NSManagedObjectContext
{
}
+(TGManagedObjectContext *)newContextOfCoordinator:(TGPersistentStoreCoordinator *)coordinator;
@end
// vim:ft=objc
