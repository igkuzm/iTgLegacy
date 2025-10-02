#import "TGManagedObjectContext.h"

@implementation TGManagedObjectContext

+(TGManagedObjectContext *)newContextOfCoordinator:(TGPersistentStoreCoordinator *)coordinator
{
	TGManagedObjectContext *context = [[super alloc]init];

	[context setPersistentStoreCoordinator:coordinator];

	return context;
}

@end

// vim:ft=objc
