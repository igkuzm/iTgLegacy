#import "CoreDataTools.h"

@implementation Attribute
+(Attribute *)name:(NSString *)name type:(NSAttributeType)type
{
	NSLog(@"%s: %s", __FILE__, __func__);
	Attribute *attribute = [[Attribute alloc] init];
	[attribute setName:name];
	[attribute setType:type];
	return attribute;
}
@end

@implementation Relation
+(Relation *)name:(NSString *)name entity:(NSEntityDescription *)entity
{
	NSLog(@"%s: %s", __FILE__, __func__);
	Relation *relation = [[Relation alloc] init];
	[relation setName:name];
	[relation setEntity:entity];
	return relation;
}
@end

@implementation  NSEntityDescription (tools)
	+ (NSEntityDescription *)entityFromNSManagedObjectClass:(NSString *)className
{
	NSLog(@"%s: %s", __FILE__, __func__);
	NSEntityDescription *entity = [[NSEntityDescription alloc] init];
	[entity setName:className];
	[entity setManagedObjectClassName:className];
	return entity;
}

+ (NSEntityDescription *)entityFromNSManagedObjectClass:(NSString *)className attributes:(NSArray *)attributes relations:(NSArray *)relations
{
	NSLog(@"%s: %s", __FILE__, __func__);
	NSEntityDescription *entity = 
		[NSEntityDescription entityFromNSManagedObjectClass:className];
	
	NSMutableArray *properties = [NSMutableArray array];
	for (Attribute *attribute in attributes){
		//NSAttributeDescription *desc = 
			//[NSAttributeDescription attributeWithName:attribute.name 
																					 //type:attribute.type];
		NSAttributeDescription *desc = [[NSAttributeDescription alloc] init];
		[desc setName:attribute.name];
		[desc setAttributeType:attribute.type];
		[desc setOptional:YES];

		[properties addObject:desc];
	}
	/*
	for (Relation *relation in relations){
		//NSRelationshipDescription *desc = 
			//[NSRelationshipDescription relationWithName:relation.name 
																					 //entity:relation.entity];
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
	*/
	[entity setProperties:properties];

	return entity;
}
@end

//@implementation NSAttributeDescription (tools)
	//+ (NSAttributeDescription *)attributeWithName:(NSString *)name type:(NSAttributeType)type
//{
		//NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
		//[attribute setName:name];
		//[attribute setAttributeType:type];
		//[attribute setOptional:YES];

		//return attribute;
//}
//@end

//@implementation NSRelationshipDescription (tools)
	//+ (NSRelationshipDescription *)relationWithName:(NSString *)name entity:(NSEntityDescription *)entity
//{
	//NSRelationshipDescription *relation = 
			//[[NSRelationshipDescription alloc] init];
	//[relation setName:name];
	//[relation setDestinationEntity:entity];
	//[relation setMinCount:0];
	//[relation setMaxCount:1];
	//[relation setDeleteRule:NSNullifyDeleteRule];
	////[relation setDeleteRule:NSCascadeDeleteRule]; // for multy
	////[relation setInverseRelationship:]
	
	//return relation;
//}
//@end
// vim:ft=objc
