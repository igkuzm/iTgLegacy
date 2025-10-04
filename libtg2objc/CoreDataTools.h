#import <CoreData/CoreData.h>

@interface Attribute : NSObject
{
}
@property (strong) NSString *name;
@property NSAttributeType type;
+(Attribute *)name:(NSString *)name 
							type:(NSAttributeType)type;
@end

@interface Relation : NSObject
{
}
@property (strong) NSString *name;
@property (strong) NSEntityDescription *entity;
+(Relation *)name:(NSString *)name 
					 entity:(NSEntityDescription *)entity;
@end

@interface NSEntityDescription (tools)
	+ (NSEntityDescription *)
	entityFromNSManagedObjectClass:(NSString *)className;

	+ (NSEntityDescription *)
	entityFromNSManagedObjectClass:(NSString *)className 
											attributes:(NSArray *)attributes 
											 relations:(NSArray *)relations;
@end

// vim:ft=objc
