#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"

@interface TGObject : NSManagedObject
{
}

@property (strong) NSNumber * tl_id;

- (void)updateWithTL:(const tl_t *)tl
				     context:(NSManagedObjectContext *)context;
+ (id)newWithTL:(const tl_t *)tl 
				context:(NSManagedObjectContext *)context;
	
@end
// vim:ft=objc
