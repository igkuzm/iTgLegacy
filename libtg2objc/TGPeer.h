#import "TGObject.h"

@interface TGPeer : TGObject
{
}

@property int peerType;
@property int id;

+ (NSEntityDescription *)entity;

@end

// vim:ft=objc
