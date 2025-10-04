#import "TGFolder.h"
#import "CoreDataTools.h"
#import "NSString+libtg2.h"

@implementation TGFolder
- (void)updateWithTL:(const tl_t *)tl{
	if (tl->_id == id_folder){
		tl_folder_t *f = (tl_folder_t *)tl;

		self.autofill_new_broadcasts = f->autofill_new_broadcasts_;
		self.autofill_public_groups = f->autofill_public_groups_;
		self.autofill_new_correspondents = f->autofill_new_correspondents_;
		self.id = f->id_;
		self.title = [NSString sringWithTLString:f->title_]; 
		self.photo = [TGChatPhoto newWithTL:f->photo_];
		
		return;
	}
	NSLog(@"tl is not folder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (TGFolder *)newWithTL:(const tl_t *)tl{
	TGFolder *obj = [[TGFolder alloc] init];
	[obj updateWithTL:tl];
	return obj;
}

+ (NSEntityDescription *)entity{
	NSLog(@"%s: %s", __FILE__, __func__);

	NSArray *attributes = @[ 
		[Attribute name:@"autofill_new_broadcasts" type:NSBooleanAttributeType],
		[Attribute name:@"autofill_public_groups" type:NSBooleanAttributeType],
		[Attribute name:@"autofill_new_correspondents" type:NSBooleanAttributeType],
		[Attribute name:@"id" type:NSInteger32AttributeType],
		[Attribute name:@"title" type:NSStringAttributeType],
	];
	
	NSArray *relations = @[ 
		[Relation name:@"photo" entity:[TGChatPhoto entity]],
	];
	
	NSEntityDescription *entity = 
		[NSEntityDescription 
			entityFromNSManagedObjectClass:NSStringFromClass(self) 
												  attributes:attributes 
												   relations:relations];

	return entity;
}
@end
// vim:ft=objc
