#import "TGPersistentStoreCoordinator.h"
#include "Foundation/Foundation.h"
#import "TGManagedObjectModel.h"

@implementation TGPersistentStoreCoordinator

+(TGPersistentStoreCoordinator *)coordinator
{
	TGPersistentStoreCoordinator *coordinator = [[super alloc]
	 	initWithManagedObjectModel:[TGManagedObjectModel model]];
		
	NSURL *storePath = [NSURL fileURLWithPath:
		[NSSearchPathForDirectoriesInDomains(
			NSDocumentDirectory, 
			NSUserDomainMask, 
			YES) 
		objectAtIndex:0]];
		
	NSURL *storeURL = 
		[storePath URLByAppendingPathComponent:@"tg.sqlite"];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >=30000
	NSDictionary *options = 
		@{NSSQLitePragmasOption:@{@"journal_mode":@"MEMORY"}};
#else 
	NSDictionary *options = nil;
#endif

	NSError *error = nil;
	[coordinator addPersistentStoreWithType:NSSQLiteStoreType 
														configuration:nil 
																			URL:storeURL 
																	options:options 
																		error:&error];
	if (error){
		NSLog(@"Error: can't set store for coordinator: %@", 
				error.description);
		return NULL;
	}

	return coordinator;
}
@end

// vim:ft=objc
