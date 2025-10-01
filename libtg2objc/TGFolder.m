#import "TGFolder.h"
#import "NSString+libtg2.h"

@implementation TGFolder
- (id)initWithTL:(const tl_t *)tl{
	if (self = [super init]) {
		if (tl->_id == id_folder){
			tl_folder_t *f = (tl_folder_t *)tl;

			self.autofill_new_broadcasts = f->autofill_new_broadcasts_;
			self.autofill_public_groups = f->autofill_public_groups_;
			self.autofill_new_correspondents = f->autofill_new_correspondents_;
			self.id = f->id_;
			self.title = [NSString sringWithTLString:f->title_]; 
			self.photo = [[TGChatPhoto alloc]initWithTL:f->photo_];

		}
	}
	return self;
}

+ (NSEntityDescription *)entity{

	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:@"TGFolder"];
	[entity setManagedObjectClassName:@"TGFolder"];
	
	NSMutableArray *properties = [NSMutableArray array];
	
	// create the attributes
	// Boolean
	for (NSString *attributeDescriptionName in @[
			@"autofill_new_broadcasts",
			@"autofill_public_groups",
			@"autofill_new_correspondents",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSBooleanAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// Int32
	for (NSString *attributeDescriptionName in @[
			@"id",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSInteger32AttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// NSString
	for (NSString *attributeDescriptionName in @[
			@"title",
	])
	{
		NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		[attribute setName:attributeDescriptionName];
		[attribute setAttributeType:NSStringAttributeType];
		[attribute setOptional:YES];
		[properties addObject:attribute];
	}

	// TGChatPhoto
	{
		NSRelationshipDescription *relation = 
			[[NSRelationshipDescription alloc] init];
		[relation setName:@"photo"];
		[relation setDestinationEntity:[TGChatPhoto entity]];
		[relation setMinCount:0];
		[relation setMaxCount:1];
		[relation setDeleteRule:NSNullifyDeleteRule];
		//[relation setDeleteRule:NSCascadeDeleteRule]; // for multy
		//[relation setInverseRelationship:]
		[properties addObject:relation];
	}

	[entity setProperties:properties];

	return entity;
}
@end
// vim:ft=objc
