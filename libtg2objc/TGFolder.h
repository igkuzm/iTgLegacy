#import <CoreData/CoreData.h>
#import "../libtg2/libtg.h"
#import "TGChatPhoto.h"

@interface TGFolder : NSManagedObject
{
}

@property Boolean autofill_new_broadcasts;
@property Boolean autofill_public_groups;
@property Boolean autofill_new_correspondents;
@property int id;
@property (strong) NSString *title;
@property (strong) TGChatPhoto *photo;

- (id)initWithTL:(const tl_t *)tl;

+ (NSEntityDescription *)entity;
@end

// vim:ft=objc
