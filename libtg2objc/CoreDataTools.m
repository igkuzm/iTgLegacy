#import "CoreDataTools.h"

@implementation Attribute
+(Attribute *)name:(NSString *)name type:(NSAttributeType)type
{
	NSLog(@"%s", __func__);
	Attribute *attribute = [[Attribute alloc] init];
	[attribute setName:name];
	[attribute setType:type];
	return attribute;
}
@end

@implementation Relation
+(Relation *)name:(NSString *)name entity:(NSEntityDescription *)entity
{
	NSLog(@"%s", __func__);
	Relation *relation = [[Relation alloc] init];
	[relation setName:name];
	[relation setEntity:entity];
	return relation;
}
@end

@implementation  NSEntityDescription (tools)
	+ (NSEntityDescription *)entityFromNSManagedObjectClass:(NSString *)className
{
	NSLog(@"%s", __func__);
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:className];
	[entity setManagedObjectClassName:@"NSManagedObject"];
	return entity;
}

+ (NSEntityDescription *)entityFromNSManagedObjectClass:(NSString *)className attributes:(NSArray *)attributes relations:(NSArray *)relations
{
	NSLog(@"%s", __func__);
	NSEntityDescription *entity = 
		[NSEntityDescription entityFromNSManagedObjectClass:className];
	
	NSMutableArray *properties = [NSMutableArray array];
	for (Attribute *attribute in attributes){
		
		NSAttributeDescription *desc = [[NSAttributeDescription alloc] init];
		[desc setName:attribute.name];
		[desc setAttributeType:attribute.type];
		[desc setOptional:YES];

		[properties addObject:desc];
	}
	for (Relation *relation in relations){
		
		NSRelationshipDescription *desc = 
				[[NSRelationshipDescription alloc] init];
		[desc setName:relation.name];
		[desc setDestinationEntity:relation.entity];
		[desc setMinCount:0];
		[desc setMaxCount:1];
		[desc setDeleteRule:NSNullifyDeleteRule];
		//[relation setDeleteRule:NSCascadeDeleteRule]; // for multy
		//[relation setInverseRelationship:]
	
		[properties addObject:desc];
	}
	[entity setProperties:properties];

	return entity;
}
@end

// vim:ft=objc
