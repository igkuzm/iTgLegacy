#import "TGManagedObjectContext.h"

@implementation TGManagedObjectContext

+(TGManagedObjectContext *)newContextOfCoordinator:(TGPersistentStoreCoordinator *)coordinator
{
	NSLog(@"%s: %s", __FILE__, __func__);
	TGManagedObjectContext *context = [[super alloc]init];

	[context setPersistentStoreCoordinator:coordinator];

	return context;
}

@end

// vim:ft=objc
