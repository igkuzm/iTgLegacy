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
		self.photo = [[TGChatPhoto alloc]initWithTL:f->photo_];
		
		return;
	}
	NSLog(@"tl is not folder type: %s",
			TL_NAME_FROM_ID(tl->_id));
}

+ (NSEntityDescription *)entity{

	NSArray *attributes = @[ 
		[NSAttributeDescription 
			attributeWithName:@"autofill_new_broadcasts" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"autofill_public_groups" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"autofill_new_correspondents" 
									 type:NSBooleanAttributeType],
		[NSAttributeDescription 
			attributeWithName:@"id" 
									 type:NSInteger32AttributeType],
		[NSAttributeDescription 
			attributeWithName:@"title" 
									 type:NSStringAttributeType],
	];
	
	NSArray *relations = @[ 
		[NSRelationshipDescription 
			relationWithName:@"photo" 
								entity:[TGChatPhoto entity]],
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
